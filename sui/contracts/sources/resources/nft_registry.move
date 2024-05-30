module wormhole_ntt::nft_registry {
    use sui::object::{Self, UID};
    use sui::dynamic_field::{Self};
    use sui::tx_context::{TxContext};

    use wormhole_ntt::nft_token;
    use wormhole_ntt::nft::{TreasuryCap};
    use wormhole_ntt::nft_token::NFTToken;

    friend wormhole_ntt::state;
    friend wormhole_ntt::non_fungible_ntt_manager;

    /// NFT is not registered yet.
    const E_UNREGISTERED: u64 = 0;

    /// This container is used to store nft type as dynamic fields under its `UID`.
    struct NFTRegistry has key, store {
        id: UID,
        num_nfts: u64,
    }

    /// Container to provide convenient checking of whether an NFT is native
    /// `VerifiedNFT` can only be created by passing in a resource with `T`
    ///  to verify the nft token is exists in `NFTRegistry`
    struct VerifiedNFT<phantom T> has drop {
        chain: u16,
    }

    /// Wrapper of nft type to act as dynamic field key.
    struct Key<phantom T> has copy, drop, store {}

    /// Determine whether a particular nft type is registered.
    public fun has<T>(self: &NFTRegistry): bool {
        dynamic_field::exists_(&self.id, Key<T> {})
    }

    /// Determine whether a particular nft type is registered with assert.
    public fun assert_has<T>(self: &NFTRegistry) {
        assert!(has<T>(self), E_UNREGISTERED);
    }

    /// used to create the `VerifiedNFT`
    public fun verified_nft<T>(
        self: &NFTRegistry
    ): VerifiedNFT<T> {
        let nft_token = borrow_native<T>(self);

        VerifiedNFT { chain: nft_token::chain(nft_token) }
    }

    /// create new `NFTRegistry`
    public(friend) fun new(
        ctx: &mut TxContext
    ): NFTRegistry {
        NFTRegistry {
            id: object::new(ctx),
            num_nfts: 0,
        }
    }

    /// borrow nft token
    public fun borrow_native<T>(
        self: &NFTRegistry
    ): &NFTToken<T> {
        dynamic_field::borrow(&self.id, Key<T> {})
    }

    /// borrow mut nft token
    public(friend) fun borrow_mut_native<T>(
        self: &mut NFTRegistry
    ): &mut NFTToken<T> {
        dynamic_field::borrow_mut(&mut self.id, Key<T> {})
    }

    /// Retrieve number of nfts registered in `NFTRegistry`.
    public fun num_nfts(
        self: &NFTRegistry
    ): u64 {
        self.num_nfts
    }

    /// Retrieve chain id from `VerifiedNFT`.
    public fun token_chain<T>(
        verified: &VerifiedNFT<T>
    ): u16 {
        verified.chain
    }

    /// Add a new native nft to the registry
    public(friend) fun add_new_nft<T>(
        self: &mut NFTRegistry,
        treasury_cap: TreasuryCap<T>,
        ctx: &mut TxContext
    ) {
        let nft_token = nft_token::new(treasury_cap, ctx);

        // Add to registry.
        dynamic_field::add(&mut self.id, Key<T> {}, nft_token);
        self.num_nfts = self.num_nfts + 1;
    }

    #[test_only]
    public fun new_test_only(
        ctx: &mut TxContext
    ): NFTRegistry {
        new(ctx)
    }

    #[test_only]
    public fun add_new_nft_test_only<T>(
        self: &mut NFTRegistry,
        treasury_cap: TreasuryCap<T>,
        ctx: &mut TxContext
    ) {
        add_new_nft(self, treasury_cap, ctx)
    }

    #[test_only]
    public fun remove_new_nft_test_only<T>(
        self: &mut NFTRegistry,
    ): NFTToken<T> {
        dynamic_field::remove<Key<T>, NFTToken<T>>(&mut self.id, Key<T> {})
    }

    #[test_only]
    public fun destroy_test_only(
        registry: NFTRegistry
    ) {
        let NFTRegistry {
            id,
            num_nfts: _
        } = registry;
        object::delete(id);
    }
}
