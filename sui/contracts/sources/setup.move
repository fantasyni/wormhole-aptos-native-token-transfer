module wormhole_ntt::setup {
    use sui::event::emit;
    use sui::transfer::{Self};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::coin::{Self, CoinMetadata, TreasuryCap};

    use wormhole::bytes32::{Self};
    use wormhole::external_address;
    use wormhole::emitter::{EmitterCap};
    use wormhole_ntt::native_token;
    use wormhole_ntt::token_registry;
    use wormhole_ntt::state::{Self, State};
    use wormhole_ntt::nft::{TreasuryCap as NftTreasuryCap};

    const E_INVALID_ADMIN_CAP: u64 = 0;
    const E_TOKEN_MINTED: u64 = 1;

    /// Capability for admin role actions
    struct AdminCap has key, store {
        id: UID,
        state_id: ID,
        mintInitToken: bool
    }

    struct CreateNttEvent has copy, drop {
        manager_address: ID,
        emitter_address: ID
    }

    #[allow(lint(share_owned))]
    /// Only the owner of the `AdminCap` can call this method. This
    /// This method set `mode` and `emitterCap` to create and share the `State` object.
    public fun create_ntt(
        mode: u8,
        emitter_cap: EmitterCap,
        ctx: &mut TxContext
    ) {
        let state = state::new(
            mode,
            emitter_cap,
            ctx
        );

        let admin_cap = AdminCap {
            id: object::new(ctx),
            state_id: state::state_id(&state),
            mintInitToken: false,
        };

        emit(CreateNttEvent {
            manager_address: state::state_id(&state),
            emitter_address: state::emitter_id(&state)
        });

        // Share new state.
        transfer::public_share_object(state);
        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
    }

    /// add new native token to `WormholeNTT`
    public fun add_new_native_token<CoinType>(
        cap: &AdminCap,
        state: &mut State,
        coin_meta: &CoinMetadata<CoinType>,
        treasury_cap: TreasuryCap<CoinType>,
    ) {
        assert_admin_cap(cap, state);

        state::add_new_native_token(state, coin_meta, treasury_cap);
    }

    public fun mint_init_token<CoinType>(
        cap: &mut AdminCap,
        state: &mut State,
        amount: u64,
        ctx: &mut TxContext
    ) {
        assert_admin_cap(cap, state);

        assert!(!cap.mintInitToken, E_TOKEN_MINTED);

        cap.mintInitToken = true;

        let registry = state::borrow_mut_token_registry(state);
        let native_token = token_registry::borrow_mut_native<CoinType>(registry);

        let mint_balance = native_token::mint(native_token, amount);
        sui::transfer::public_transfer(
            coin::from_balance(mint_balance, ctx),
            tx_context::sender(ctx)
        );
    }

    public fun check_native_token<CoinType>(
        state: &mut State,
    ): bool {
        state::check_native_token<CoinType>(state)
    }

    /// add new nft token to `WormholeNTT`
    public fun add_new_nft<T>(
        cap: &AdminCap,
        state: &mut State,
        treasury_cap: NftTreasuryCap<T>,
        ctx: &mut TxContext
    ) {
        assert_admin_cap(cap, state);

        state::add_new_nft(state, treasury_cap, ctx);
    }

    /// set ntt manager peer contract address to the target chain
    public fun set_manager_peer(
        cap: &AdminCap,
        state: &mut State,
        peer_chain_id: u16,
        peer_contract: vector<u8>,
        decimals: u8
    ) {
        assert_admin_cap(cap, state);

        state::set_manager_peer(state, peer_chain_id, peer_contract, decimals);
    }

    public fun check_manager_peer(
        state: &mut State,
        peer_chain_id: u16,
    ): bool {
        state::check_manager_peer(state, peer_chain_id)
    }

    /// set ntt transceiver peer contract address to the target chain
    public fun set_transceiver_peer(
        cap: &AdminCap,
        state: &mut State,
        peer_chain_id: u16,
        peer_contract: vector<u8>,
    ) {
        assert_admin_cap(cap, state);

        let peer_contract_address = external_address::new(bytes32::from_bytes(peer_contract));
        state::set_transceiver_peer(state, peer_chain_id, peer_contract_address);
    }

    public fun check_transceiver_peer(
        state: &mut State,
        peer_chain_id: u16,
    ): bool {
        state::check_transceiver_peer(state, peer_chain_id)
    }

    fun assert_admin_cap(cap: &AdminCap, state: &State) {
        assert!(cap.state_id == state::state_id(state), E_INVALID_ADMIN_CAP)
    }
}
