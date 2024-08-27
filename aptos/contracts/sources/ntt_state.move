/// This module implements the global state variables for WormholeNTT as a
/// shared object. The `State` object is used to perform anything that requires
/// access to data that defines the WormholeNTT contract.
module wormhole_ntt::ntt_state {
    use std::vector;
    use std::string;
    use std::event::{emit};

    use aptos_framework::account;
    use aptos_std::table::{Self, Table};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::object::{Self, ExtendRef};
    use aptos_std::type_info::{Self, TypeInfo, type_of};
    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability, MintCapability, Coin};

    use wormhole::state;
    use wormhole::wormhole;
    use wormhole::set::{Self, Set};
    use wormhole::u16::{Self as U16, U16};
    use wormhole::emitter::{EmitterCapability};
    use wormhole_ntt::token_hash::{Self, TokenHash};
    use wormhole_ntt::ntt_external_address::{Self, NttExternalAddress};

    const MODE_LOCKING: u8 = 0;
    const MODE_BURNING: u8 = 1;

    const PACKAGE_SYMBOL: vector<u8> = b"wormhole_ntt";

    const E_INVALID_PEER_CHAIN_ID_ZERO: u64 = 0;
    const E_INVALID_PEER_ZERO_ADDRESS: u64 = 1;
    const E_INVALID_PEER_DECIMALS: u64 = 2;
    const E_INVALID_PEER_SAME_CHAIN_ID: u64 = 3;

    friend wormhole_ntt::ntt;
    friend wormhole_ntt::ntt_vaa;
    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::ntt_transceiver;

    /// Container for all state variables for WormholeNtt.
    struct State has key, store {
        /// WormholeNtt mode LOCKING and BURNING
        mode: u8,
        /// Emitter capability required to publish Wormhole messages.
        emitter_cap: EmitterCapability,
        /// ExtendRef to generate signer
        extend_ref: ExtendRef,
        /// message sequence id use for transfer tokens
        message_sequence: u64,
        /// target chain NttManager contract address table
        manager_peers: Table<u16, NttManagerPeer>,
        /// target chain WormholeTransceiver contract address table
        transceiver_peers: Table<u16, WormholeTransceiverPeer>,
        /// Set of consumed VAA hashes.
        consumed_vaas: Set<vector<u8>>,
        /// Native Infos for TokenHash
        native_infos: Table<TokenHash, TypeInfo>,
        /// Mapping of bridge contracts on other chains
        registered_emitters: Table<U16, NttExternalAddress>,
    }

    struct NativeToken<phantom CoinType> has key {
        burn_cap: BurnCapability<CoinType>,
        freeze_cap: FreezeCapability<CoinType>,
        mint_cap: MintCapability<CoinType>,
    }

    #[event]
    struct NttManagerPeer has drop, store {
        peer_address: vector<u8>,
        token_decimals: u8
    }

    #[event]
    struct WormholeTransceiverPeer has drop, store {
        peer_contract: NttExternalAddress
    }

    #[event]
    struct NttManagerPeerUpdate has drop, store {
        chian_id: u16,
        old_peer_contract: vector<u8>,
        old_peer_decimals: u8,
        peer_contract: vector<u8>,
        peer_decimals: u8
    }

    #[event]
    struct WormholeTransceiverPeerUpdate has drop, store {
        chian_id: u16,
        old_peer_contract: NttExternalAddress,
        peer_contract: NttExternalAddress,
    }

    public(friend) fun get_package_symbol(): vector<u8> {
        PACKAGE_SYMBOL
    }

    #[view]
    public(friend) fun package_address(): address {
        object::create_object_address(&@wormhole_ntt, PACKAGE_SYMBOL)
    }

    /// create new state
    public(friend) fun init_wormhole_ntt_state(signer: &signer, emitter_cap: EmitterCapability, extend_ref: ExtendRef) {
        account::create_account_if_does_not_exist(package_address());

        move_to(signer, State {
            mode: MODE_LOCKING,
            emitter_cap,
            extend_ref,
            message_sequence: 0,
            manager_peers: table::new(),
            transceiver_peers: table::new(),
            consumed_vaas: set::new(),
            native_infos: table::new(),
            registered_emitters: table::new()
        });
    }

    public(friend) fun set_mode(mode: u8) acquires State {
        let state = borrow_global_mut<State>(package_address());
        state.mode = mode;
    }

    public(friend) fun is_registered_native_asset<CoinType>(): bool acquires State {
        let token = token_hash::derive<CoinType>();
        let native_infos = &borrow_global<State>(package_address()).native_infos;
        table::contains(native_infos, token)
    }

    public(friend) fun check_account_registered<CoinType>() acquires State {
        if (!coin::is_account_registered<CoinType>(package_address())) {
            coin::register<CoinType>(&wormhole_ntt_signer());
        };
        if (!coin::is_account_registered<AptosCoin>(package_address())) {
            coin::register<AptosCoin>(&wormhole_ntt_signer());
        };
    }

    public(friend) fun add_new_native_token<CoinType>(sender: &signer, name: vector<u8>, symbol: vector<u8>, decimals: u8, monitor_supply: bool) acquires State {
        let coin_ref = &object::create_named_object(sender, symbol);
        let coin_signer =  &object::generate_signer(coin_ref);

        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<CoinType>(
            coin_signer,
            string::utf8(name),
            string::utf8(symbol),
            decimals,
            monitor_supply,
        );

        let native_token = NativeToken<CoinType> {
            burn_cap,
            freeze_cap,
            mint_cap
        };

        move_to(&wormhole_ntt_signer(), native_token);
        set_native_asset_type_info<CoinType>();
    }

    public(friend) fun mint_native_token<CoinType>(amount: u64): Coin<CoinType> acquires NativeToken {
        let native_token = borrow_global_mut<NativeToken<CoinType>>(package_address());
        let coins = coin::mint<CoinType>(amount, &native_token.mint_cap);
        coins
    }

    public(friend) fun burn_native_token<CoinType>(coins: Coin<CoinType>) acquires NativeToken {
        let native_token = borrow_global_mut<NativeToken<CoinType>>(package_address());
        coin::burn<CoinType>(coins, &native_token.burn_cap);
    }

    public(friend) fun set_native_asset_type_info<CoinType>() acquires State {
        let token_address = token_hash::derive<CoinType>();
        let type_info = type_of<CoinType>();

        let state = borrow_global_mut<State>(package_address());
        let native_infos = &mut state.native_infos;
        table::add(native_infos, token_address, type_info);
    }

    public(friend) fun wormhole_ntt_signer(): signer acquires State {
        object::generate_signer_for_extending(&borrow_global<State>(package_address()).extend_ref)
    }

    /// check current WormholeNtt mode is LOCKING
    public fun is_mode_locking(): bool acquires State {
        let state = borrow_global<State>(package_address());
        state.mode == MODE_LOCKING
    }

    /// check current WormholeNtt mode is BURNING
    public fun is_mode_burning(): bool acquires State {
        let state = borrow_global<State>(package_address());
        state.mode == MODE_BURNING
    }

    public(friend) fun publish_message(nonce: u64, payload: vector<u8>, message_fee: Coin<AptosCoin>): u64 acquires State {
        let emitter_cap = &mut borrow_global_mut<State>(package_address()).emitter_cap;
        wormhole::publish_message(
            emitter_cap,
            nonce,
            payload,
            message_fee
        )
    }

    /// increase message_sequenece for WormholeNtt message transfer
    public(friend) fun use_message_sequence(): u64 acquires State {
        let state = borrow_global_mut<State>(package_address());
        state.message_sequence = state.message_sequence + 1;
        state.message_sequence
    }

    /// get NttManager peer contract address
    public(friend) fun get_manager_peer_address(chain_id: u16): vector<u8> acquires State {
        let state = borrow_global<State>(package_address());
        table::borrow(&state.manager_peers, chain_id).peer_address
    }

    /// get NttManager peer contract decimals
    public(friend) fun get_manager_peer_decimals(chain_id: u16): u8 acquires State {
        let state = borrow_global<State>(package_address());
        table::borrow(&state.manager_peers, chain_id).token_decimals
    }

    /// get NttManager peer contract info
    // public(friend) fun get_manager_peer(chain_id: u16): &NttManagerPeer acquires State {
    //     let manager_peers = &borrow_global<State>(@wormhole_ntt).manager_peers;
    //     table::borrow(manager_peers, chain_id)
    // }

    fun set_manager_peer_info(peer_chain_id: u16, peer_contract: vector<u8>, decimals: u8) acquires State {
        let manager_peers = &mut borrow_global_mut<State>(package_address()).manager_peers;
        let peer_chain_info = table::borrow_mut(manager_peers, peer_chain_id);
        peer_chain_info.peer_address = peer_contract;
        peer_chain_info.token_decimals = decimals;
    }

    /// get current state object address
    // public(friend) fun get_state_address(state: &State): vector<u8> {
    //     object::uid_to_bytes(&state.id)
    // }

    /// get WormholeTransceiver peer contract address
    public(friend) fun get_transceiver_peer_address(chain_id: u16): NttExternalAddress acquires State {
        let state = borrow_global<State>(package_address());
        table::borrow(&state.transceiver_peers, chain_id).peer_contract
    }

    public(friend) fun token_address<CoinType>(): address {
        let type_info = type_info::type_of<CoinType>();
        type_info::account_address(&type_info)
    }

    /// set NttManager peer contract info
    public(friend) fun set_manager_peer(peer_chain_id: u16, peer_contract: vector<u8>, decimals: u8) acquires State {
        let state = borrow_global_mut<State>(package_address());
        assert!(peer_chain_id > 0, E_INVALID_PEER_CHAIN_ID_ZERO);
        assert!(vector::length(&peer_contract) > 0, E_INVALID_PEER_ZERO_ADDRESS);
        assert!(decimals > 0, E_INVALID_PEER_DECIMALS);
        assert!(peer_chain_id != chain_id(), E_INVALID_PEER_SAME_CHAIN_ID);

        if (table::contains(&state.manager_peers, peer_chain_id)) {
            let old_peer_address = get_manager_peer_address(peer_chain_id);
            let old_peer_token_decimals = get_manager_peer_decimals(peer_chain_id);

            emit(NttManagerPeerUpdate {
                chian_id: peer_chain_id,
                old_peer_contract: old_peer_address,
                old_peer_decimals: old_peer_token_decimals,
                peer_contract: peer_contract,
                peer_decimals: decimals
            });

            set_manager_peer_info(peer_chain_id, peer_contract, decimals);
        } else {
            let peer = NttManagerPeer {
                peer_address: peer_contract,
                token_decimals: decimals
            };

            table::add(&mut state.manager_peers, peer_chain_id, peer);

            emit(NttManagerPeerUpdate {
                chian_id: peer_chain_id,
                old_peer_contract: vector[],
                old_peer_decimals: 0,
                peer_contract: peer_contract,
                peer_decimals: decimals
            });
        }
    }

    public(friend) fun set_vaa_consumed(hash: vector<u8>) acquires State {
        let state = borrow_global_mut<State>(package_address());
        set::add(&mut state.consumed_vaas, hash);
    }

    /// set Wormhole transceiver peer info
    public(friend) fun set_transceiver_peer(peer_chain_id: u16, peer_contract: NttExternalAddress) acquires State {
        let state = borrow_global_mut<State>(package_address());
        assert!(peer_chain_id > 0, E_INVALID_PEER_CHAIN_ID_ZERO);
        assert!(ntt_external_address::is_nonzero(&peer_contract), E_INVALID_PEER_ZERO_ADDRESS);
        assert!(peer_chain_id != chain_id(), E_INVALID_PEER_SAME_CHAIN_ID);

        if (table::contains(&state.transceiver_peers, peer_chain_id)) {
            let peer_info = table::borrow_mut(&mut state.transceiver_peers, peer_chain_id);
            emit(WormholeTransceiverPeerUpdate{
                chian_id: peer_chain_id,
                old_peer_contract: peer_info.peer_contract,
                peer_contract
            });

            peer_info.peer_contract = peer_contract;
        } else {
            table::add(&mut state.transceiver_peers, peer_chain_id, WormholeTransceiverPeer { peer_contract });
        }
    }

    public fun chain_id(): u16 {
        let chain_id = ((U16::to_u64( state::get_chain_id())) as u16);
        chain_id
    }
}