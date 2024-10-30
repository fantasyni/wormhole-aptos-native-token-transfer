/// This module implements the global state variables for WormholeNTT as a
/// shared object. The `State` object is used to perform anything that requires
/// access to data that defines the WormholeNTT contract.
module wormhole_ntt::ntt_state {
    use std::vector;
    use std::string;
    use std::option;
    use std::signer;
    use std::event::{emit};

    use aptos_framework::coin::{Coin};
    use aptos_std::table::{Self, Table};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::object::{Self, ExtendRef, Object};

    use wormhole::state;
    use wormhole::wormhole;
    use wormhole::set::{Self, Set};
    use wormhole::u16::{Self as U16, U16};
    use wormhole::emitter::{EmitterCapability};
    use aptos_framework::primary_fungible_store;
    use wormhole_ntt::ntt_external_address::{Self, NttExternalAddress};
    use aptos_framework::fungible_asset::{Self, MintRef, TransferRef, BurnRef, Metadata, FungibleAsset};

    const MODE_LOCKING: u8 = 0;
    const MODE_BURNING: u8 = 1;

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
        native_infos: Table<address, bool>,
        /// Mapping of bridge contracts on other chains
        registered_emitters: Table<U16, NttExternalAddress>,
    }

    struct NativeToken has key {
        mint_ref: MintRef,
        transfer_ref: TransferRef,
        burn_ref: BurnRef,
    }

    #[event]
    struct CreateTokenEvent has drop, store {
        token_address: address
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

    #[view]
    public(friend) fun package_address(object_address: address): address {
        object_address
    }

    /// create new state
    public(friend) fun init_wormhole_ntt_state(object_signer: &signer, emitter_cap: EmitterCapability, extend_ref: ExtendRef, mode: u8) {
        move_to(object_signer, State {
            mode,
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

    public(friend) fun set_mode(object_address: address, mode: u8) acquires State {
        let state = borrow_global_mut<State>(object_address);
        state.mode = mode;
    }

    public(friend) fun is_registered_native_asset(object_address: address, token_address: address): bool acquires State {
        let state = borrow_global_mut<State>(object_address);

        let native_infos = &state.native_infos;
        table::contains(native_infos, token_address)
    }

    // public(friend) fun check_account_registered<CoinType>(object_address: address) acquires State {
    //     if (!coin::is_account_registered<CoinType>(object_address)) {
    //         coin::register<CoinType>(&wormhole_ntt_signer(object_address));
    //     };
    //     if (!coin::is_account_registered<AptosCoin>(object_address)) {
    //         coin::register<AptosCoin>(&wormhole_ntt_signer(object_address));
    //     };
    // }

    public(friend) fun add_new_native_token(
        object_address: address,
        sender: &signer,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8
    ) acquires State {
        let constructor_ref = &object::create_sticky_object(signer::address_of(sender));
        let token_address = object::address_from_constructor_ref(constructor_ref);

        primary_fungible_store::create_primary_store_enabled_fungible_asset(
            constructor_ref,
            option::none(),
            string::utf8(name),
            string::utf8(symbol),
            decimals,
            string::utf8(b""), /* icon */
            string::utf8(b""), /* project */
        );

        // Create mint/burn/transfer refs to allow creator to manage the fungible asset.
        let mint_ref = fungible_asset::generate_mint_ref(constructor_ref);
        let burn_ref = fungible_asset::generate_burn_ref(constructor_ref);
        let transfer_ref = fungible_asset::generate_transfer_ref(constructor_ref);
        let metadata_object_signer = object::generate_signer(constructor_ref);
        let native_token = NativeToken { mint_ref, transfer_ref, burn_ref };
        move_to(&metadata_object_signer, native_token);

        set_native_asset_type_info(object_address, token_address);

        emit(CreateTokenEvent{
            token_address
        })
    }

    public fun get_metadata(token_address: address): Object<Metadata> {
        object::address_to_object<Metadata>(token_address)
    }

    inline fun authorized_borrow_refs(
        asset: Object<Metadata>,
    ): &NativeToken acquires NativeToken {
        // assert!(object::is_owner(asset, signer::address_of(owner)), error::permission_denied(ENOT_OWNER));
        borrow_global<NativeToken>(object::object_address(&asset))
    }

    public(friend) fun deposit_token(token_address: address, to: address, fa: FungibleAsset) acquires NativeToken {
        let asset = get_metadata(token_address);
        let native_token = authorized_borrow_refs(asset);
        let transfer_ref = &native_token.transfer_ref;
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::deposit_with_ref(transfer_ref, to_wallet, fa);
    }

    public(friend) fun withdraw_token(token_address: address, from: address, amount: u64): FungibleAsset acquires NativeToken {
        let asset = get_metadata(token_address);
        let native_token = authorized_borrow_refs(asset);
        let transfer_ref = &native_token.transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        fungible_asset::withdraw_with_ref(transfer_ref, from_wallet, amount)
    }

    public(friend) fun withdraw_token_to(token_address: address, from: address, to: address, amount: u64) acquires NativeToken {
        let asset = get_metadata(token_address);
        let native_token = authorized_borrow_refs(asset);
        let transfer_ref = &native_token.transfer_ref;
        let from_wallet = primary_fungible_store::primary_store(from, asset);
        let fa = fungible_asset::withdraw_with_ref(transfer_ref, from_wallet, amount);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        fungible_asset::deposit_with_ref(transfer_ref, to_wallet, fa);
    }

    public(friend) fun mint_native_token(token_address: address, to: address, amount: u64) acquires NativeToken {
        let asset = get_metadata(token_address);
        let native_token = authorized_borrow_refs(asset);
        let to_wallet = primary_fungible_store::ensure_primary_store_exists(to, asset);
        let fa = fungible_asset::mint(&native_token.mint_ref, amount);
        fungible_asset::deposit_with_ref(&native_token.transfer_ref, to_wallet, fa);
    }

    public(friend) fun burn_native_token(token_address: address, coins: FungibleAsset) acquires NativeToken {
        let asset = get_metadata(token_address);
        let native_token = authorized_borrow_refs(asset);
        let burn_ref = &native_token.burn_ref;
        fungible_asset::burn(burn_ref, coins);
    }

    public(friend) fun set_native_asset_type_info(object_address: address, token_address: address) acquires State {
        let state = borrow_global_mut<State>(object_address);

        let native_infos = &mut state.native_infos;
        table::add(native_infos, token_address, true);
    }

    public(friend) fun wormhole_ntt_signer(object_address: address): signer acquires State {
        let state = borrow_global_mut<State>(object_address);
        object::generate_signer_for_extending(&state.extend_ref)
    }

    /// check current WormholeNtt mode is LOCKING
    public fun is_mode_locking(object_address: address): bool acquires State {
        let state = borrow_global_mut<State>(object_address);
        state.mode == MODE_LOCKING
    }

    /// check current WormholeNtt mode is BURNING
    public fun is_mode_burning(object_address: address): bool acquires State {
        let state = borrow_global_mut<State>(object_address);
        state.mode == MODE_BURNING
    }

    public(friend) fun publish_message(object_address: address, nonce: u64, payload: vector<u8>, message_fee: Coin<AptosCoin>): u64 acquires State {
        let state = borrow_global_mut<State>(object_address);
        let emitter_cap = &mut state.emitter_cap;
        wormhole::publish_message(
            emitter_cap,
            nonce,
            payload,
            message_fee
        )
    }

    /// increase message_sequenece for WormholeNtt message transfer
    public(friend) fun use_message_sequence(object_address: address): u64 acquires State {
        let state = borrow_global_mut<State>(object_address);
        state.message_sequence = state.message_sequence + 1;
        state.message_sequence
    }

    /// get NttManager peer contract address
    public(friend) fun get_manager_peer_address(object_address: address, chain_id: u16): vector<u8> acquires State {
        let state = borrow_global_mut<State>(object_address);
        table::borrow(&state.manager_peers, chain_id).peer_address
    }

    /// get NttManager peer contract decimals
    public(friend) fun get_manager_peer_decimals(object_address: address, chain_id: u16): u8 acquires State {
        let state = borrow_global_mut<State>(object_address);
        table::borrow(&state.manager_peers, chain_id).token_decimals
    }

    /// get NttManager peer contract info
    // public(friend) fun get_manager_peer(chain_id: u16): &NttManagerPeer acquires State {
    //     let manager_peers = &borrow_global<State>(@wormhole_ntt).manager_peers;
    //     table::borrow(manager_peers, chain_id)
    // }

    fun set_manager_peer_info(object_address: address, peer_chain_id: u16, peer_contract: vector<u8>, decimals: u8) acquires State {
        let state = borrow_global_mut<State>(object_address);
        let manager_peers = &mut state.manager_peers;
        let peer_chain_info = table::borrow_mut(manager_peers, peer_chain_id);
        peer_chain_info.peer_address = peer_contract;
        peer_chain_info.token_decimals = decimals;
    }

    /// get current state object address
    // public(friend) fun get_state_address(state: &State): vector<u8> {
    //     object::uid_to_bytes(&state.id)
    // }

    /// get WormholeTransceiver peer contract address
    public(friend) fun get_transceiver_peer_address(object_address: address, chain_id: u16): NttExternalAddress acquires State {
        let state = borrow_global_mut<State>(object_address);
        table::borrow(&state.transceiver_peers, chain_id).peer_contract
    }

    /// set NttManager peer contract info
    public(friend) fun set_manager_peer(object_address: address, peer_chain_id: u16, peer_contract: vector<u8>, decimals: u8) acquires State {
        let state = borrow_global_mut<State>(object_address);
        assert!(peer_chain_id > 0, E_INVALID_PEER_CHAIN_ID_ZERO);
        assert!(vector::length(&peer_contract) > 0, E_INVALID_PEER_ZERO_ADDRESS);
        assert!(decimals > 0, E_INVALID_PEER_DECIMALS);
        assert!(peer_chain_id != chain_id(), E_INVALID_PEER_SAME_CHAIN_ID);

        if (table::contains(&state.manager_peers, peer_chain_id)) {
            let old_peer_address = get_manager_peer_address(object_address, peer_chain_id);
            let old_peer_token_decimals = get_manager_peer_decimals(object_address, peer_chain_id);

            emit(NttManagerPeerUpdate {
                chian_id: peer_chain_id,
                old_peer_contract: old_peer_address,
                old_peer_decimals: old_peer_token_decimals,
                peer_contract: peer_contract,
                peer_decimals: decimals
            });

            set_manager_peer_info(object_address, peer_chain_id, peer_contract, decimals);
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

    public(friend) fun set_vaa_consumed(object_address: address, hash: vector<u8>) acquires State {
        let state = borrow_global_mut<State>(object_address);
        set::add(&mut state.consumed_vaas, hash);
    }

    /// set Wormhole transceiver peer info
    public(friend) fun set_transceiver_peer(object_address: address,peer_chain_id: u16, peer_contract: NttExternalAddress) acquires State {
        let state = borrow_global_mut<State>(object_address);
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