/// This module implements the global state variables for WormholeNTT as a
/// shared object. The `State` object is used to perform anything that requires
/// access to data that defines the WormholeNTT contract.
module wormhole_ntt::state {
    use std::vector;
    use sui::object;
    use sui::event::emit;
    use sui::object::{UID, ID};
    use sui::table::{Self, Table};
    use sui::tx_context::TxContext;
    use sui::coin::{TreasuryCap, CoinMetadata};

    use wormhole::state::chain_id;
    use wormhole_ntt::nft_registry;
    use wormhole::emitter::{EmitterCap};
    use wormhole::publish_message::{MessageTicket};
    use wormhole::consumed_vaas::{Self, ConsumedVAAs};
    use wormhole_ntt::nft::{TreasuryCap as NftTreasuryCap};
    use wormhole::external_address::{Self, ExternalAddress};
    use wormhole_ntt::nft_registry::{NFTRegistry, VerifiedNFT};
    use wormhole_ntt::token_registry::{Self, TokenRegistry, VerifiedAsset};

    const MODE_LOCKING: u8 = 0;
    const MODE_BURNING: u8 = 1;

    const E_INVALID_PEER_CHAIN_ID_ZERO: u64 = 0;
    const E_INVALID_PEER_ZERO_ADDRESS: u64 = 1;
    const E_INVALID_PEER_DECIMALS: u64 = 2;
    const E_INVALID_PEER_SAME_CHAIN_ID: u64 = 3;

    friend wormhole_ntt::setup;
    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::ntt_transceiver;
    friend wormhole_ntt::non_fungible_ntt_manager;

    /// Container for all state variables for WormholeNtt.
    struct State has key, store {
        id: UID,
        /// WormholeNtt mode LOCKING and BURNING
        mode: u8,
        /// Emitter capability required to publish Wormhole messages.
        emitter_cap: EmitterCap,
        /// Registry for native tokens.
        token_registry: TokenRegistry,
        /// Registry for NFT tokens
        nft_registry: NFTRegistry,
        /// message sequence id use for transfer tokens
        message_sequence: u64,
        /// target chain NttManager contract address table
        manager_peers: Table<u16, NttManagerPeer>,
        /// target chain WormholeTransceiver contract address table
        transceiver_peers: Table<u16, WormholeTransceiverPeer>,
        /// Set of consumed VAA hashes.
        consumed_vaas: ConsumedVAAs,
    }

    /// NttManager peer container for contract address and token decimals
    struct NttManagerPeer has copy, store {
        peer_address: vector<u8>,
        token_decimals: u8
    }

    struct WormholeTransceiverPeer has copy, store {
        peer_contract: ExternalAddress
    }

    /// Event for NttManager peer info updated
    struct NttManagerPeerUpdate has copy, drop {
        chian_id: u16,
        old_peer_contract: vector<u8>,
        old_peer_decimals: u8,
        peer_contract: vector<u8>,
        peer_decimals: u8
    }

    /// Event for WormholeTransceiver peer info updated
    struct WormholeTransceiverPeerUpdate has copy, drop {
        chian_id: u16,
        old_peer_contract: ExternalAddress,
        peer_contract: ExternalAddress,
    }

    /// used to create the `VerifiedAsset` through `TokenRegistry`
    public fun verified_asset<CoinType>(
        self: &State
    ): VerifiedAsset<CoinType> {
        token_registry::verified_asset(&self.token_registry)
    }

    /// used to create the `VerifiedNFT` through `NFTRegistry`
    public fun verified_nft<T>(
        self: &State
    ): VerifiedNFT<T> {
        nft_registry::verified_nft<T>(&self.nft_registry)
    }

    /// create new state
    public(friend) fun new(
        mode: u8,
        emitter_cap: EmitterCap,
        ctx: &mut TxContext
    ): State {
        State {
            id: object::new(ctx),
            mode,
            emitter_cap,
            token_registry: token_registry::new(ctx),
            nft_registry: nft_registry::new(ctx),
            message_sequence: 0,
            manager_peers: table::new(ctx),
            transceiver_peers: table::new(ctx),
            consumed_vaas: consumed_vaas::new(ctx),
        }
    }

    /// Publish Wormhole message using WormholeNtt's `EmitterCap`.
    public fun prepare_wormhole_message(
        self: &mut State,
        nonce: u32,
        payload: vector<u8>
    ): MessageTicket {
        wormhole::publish_message::prepare_message(
            &mut self.emitter_cap,
            nonce,
            payload,
        )
    }

    /// check current WormholeNtt mode is LOCKING
    public fun is_mode_locking(state: &State): bool {
        state.mode == MODE_LOCKING
    }

    /// check current WormholeNtt mode is BURNING
    public fun is_mode_burning(state: &State): bool {
        state.mode == MODE_BURNING
    }

    public(friend) fun state_id(self: &State): ID {
        object::uid_to_inner(&self.id)
    }

    public(friend) fun emitter_id(self: &State): ID {
        object::id(&self.emitter_cap)
    }

    /// borrow mut `TokenRegistry`
    public(friend) fun borrow_mut_token_registry(
        self: &mut State
    ): &mut TokenRegistry {
        &mut self.token_registry
    }

    /// borrow mut `NFTRegistry`
    public(friend) fun borrow_mut_nft_registry(
        self: &mut State
    ): &mut NFTRegistry {
        &mut self.nft_registry
    }

    /// Store `VAA` hash as a way to claim a VAA. This method prevents a VAA
    /// from being replayed.
    public(friend) fun borrow_mut_consumed_vaas(
        self: &mut State
    ): &mut ConsumedVAAs {
        &mut self.consumed_vaas
    }

    /// increase message_sequenece for WormholeNtt message transfer
    public(friend) fun use_message_sequence(state: &mut State): u64 {
        state.message_sequence = state.message_sequence + 1;
        state.message_sequence
    }

    /// get NttManager peer contract address
    public(friend) fun get_manager_peer_address(state: &State, chain_id: u16): vector<u8> {
        table::borrow(&state.manager_peers, chain_id).peer_address
    }

    /// get NttManager peer contract decimals
    public(friend) fun get_manager_peer_decimals(state: &State, chain_id: u16): u8 {
        table::borrow(&state.manager_peers, chain_id).token_decimals
    }

    /// get NttManager peer contract info
    public(friend) fun get_manager_peer(state: &State, chain_id: u16): &NttManagerPeer {
        table::borrow(&state.manager_peers, chain_id)
    }

    /// get NttManager peer contract info mut
    public(friend) fun get_manager_peer_mut(state: &mut State, chain_id: u16): &mut NttManagerPeer {
        table::borrow_mut(&mut state.manager_peers, chain_id)
    }

    /// get current state object address
    public(friend) fun get_state_address(state: &State): vector<u8> {
        object::uid_to_bytes(&state.id)
    }

    /// get WormholeTransceiver peer contract address
    public(friend) fun get_transceiver_peer_address(state: &State, chain_id: u16): ExternalAddress {
        table::borrow(&state.transceiver_peers, chain_id).peer_contract
    }

    /// add new native token to the `TokenRegistry`
    public(friend) fun add_new_native_token<CoinType>(
        self: &mut State,
        coin_meta: &CoinMetadata<CoinType>,
        treasury_cap: TreasuryCap<CoinType>,
    ) {
        token_registry::add_new_native_token(&mut self.token_registry, coin_meta, treasury_cap);
    }

    public(friend) fun check_native_token<CoinType>(
        self: &mut State,
    ): bool {
        token_registry::has<CoinType>(&mut self.token_registry)
    }

    public(friend) fun add_new_nft<T>(
        self: &mut State,
        treasury_cap: NftTreasuryCap<T>,
        ctx: &mut TxContext
    ) {
        nft_registry::add_new_nft(&mut self.nft_registry, treasury_cap, ctx);
    }

    /// set NttManager peer contract info
    public(friend) fun set_manager_peer(
        state: &mut State,
        peer_chain_id: u16,
        peer_contract: vector<u8>,
        decimals: u8
    ) {
        assert!(peer_chain_id > 0, E_INVALID_PEER_CHAIN_ID_ZERO);
        assert!(vector::length(&peer_contract) > 0, E_INVALID_PEER_ZERO_ADDRESS);
        assert!(decimals > 0, E_INVALID_PEER_DECIMALS);
        assert!(peer_chain_id != chain_id(), E_INVALID_PEER_SAME_CHAIN_ID);

        if (table::contains(&state.manager_peers, peer_chain_id)) {
            let old_peer_address = get_manager_peer_address(state, peer_chain_id);
            let old_peer_token_decimals = get_manager_peer_decimals(state, peer_chain_id);

            emit(NttManagerPeerUpdate {
                chian_id: peer_chain_id,
                old_peer_contract: old_peer_address,
                old_peer_decimals: old_peer_token_decimals,
                peer_contract: peer_contract,
                peer_decimals: decimals
            });

            let peer_mut = get_manager_peer_mut(state, peer_chain_id);
            peer_mut.peer_address = peer_contract;
            peer_mut.token_decimals = decimals;
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

    public(friend) fun check_manager_peer(
        state: &mut State,
        peer_chain_id: u16
    ): bool {
        table::contains(&state.manager_peers, peer_chain_id)
    }

    public(friend) fun check_transceiver_peer(
        state: &mut State,
        peer_chain_id: u16
    ): bool {
        table::contains(&state.transceiver_peers, peer_chain_id)
    }

    /// set Wormhole transceiver peer info
    public(friend) fun set_transceiver_peer(
        state: &mut State,
        peer_chain_id: u16,
        peer_contract: ExternalAddress,
    ) {
        assert!(peer_chain_id > 0, E_INVALID_PEER_CHAIN_ID_ZERO);
        assert!(external_address::is_nonzero(&peer_contract), E_INVALID_PEER_ZERO_ADDRESS);
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
}
