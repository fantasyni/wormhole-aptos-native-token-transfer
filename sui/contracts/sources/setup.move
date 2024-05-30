module wormhole_ntt::setup {
    use sui::transfer::{Self};
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{CoinMetadata, TreasuryCap};

    use wormhole::bytes32::{Self};
    use wormhole::external_address;
    use wormhole::emitter::{EmitterCap};
    use wormhole_ntt::state::{Self, State};
    use wormhole_ntt::nft::{TreasuryCap as NftTreasuryCap};

    /// Capability for admin role actions
    struct AdminCap has key, store {
        id: UID
    }

    /// Called automatically when module is first published.
    /// Transfers `AdminCap` to sender.
    fun init(ctx: &mut TxContext) {
        let admin_cap = AdminCap { id: object::new(ctx) };
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
    }

    #[allow(lint(share_owned))]
    /// Only the owner of the `AdminCap` can call this method. This
    /// This method set `mode` and `emitterCap` to create and share the `State` object.
    public fun complete(
        _: &AdminCap,
        mode: u8,
        emitter_cap: EmitterCap,
        ctx: &mut TxContext
    ) {
        // Share new state.
        transfer::public_share_object(
            state::new(
                mode,
                emitter_cap,
                ctx
            ));
    }

    /// add new native token to `WormholeNTT`
    public fun add_new_native_token<CoinType>(
        _: &AdminCap,
        state: &mut State,
        coin_meta: &CoinMetadata<CoinType>,
        treasury_cap: TreasuryCap<CoinType>,
    ) {
        state::add_new_native_token(state, coin_meta, treasury_cap);
    }

    /// add new nft token to `WormholeNTT`
    public fun add_new_nft<T>(
        _: &AdminCap,
        state: &mut State,
        treasury_cap: NftTreasuryCap<T>,
        ctx: &mut TxContext
    ) {
        state::add_new_nft(state, treasury_cap, ctx);
    }

    /// set ntt manager peer contract address to the target chain
    public fun set_manager_peer(
        _: &AdminCap,
        state: &mut State,
        peer_chain_id: u16,
        peer_contract: vector<u8>,
        decimals: u8
    ) {
        state::set_manager_peer(state, peer_chain_id, peer_contract, decimals);
    }

    /// set ntt transceiver peer contract address to the target chain
    public fun set_transceiver_peer(
        _: &AdminCap,
        state: &mut State,
        peer_chain_id: u16,
        peer_contract: vector<u8>,
    ) {
        let peer_contract_address = external_address::new(bytes32::from_bytes(peer_contract));
        state::set_transceiver_peer(state, peer_chain_id, peer_contract_address);
    }

    #[test_only]
    public fun init_test_only(ctx: &mut TxContext) {
        init(ctx);
    }
}
