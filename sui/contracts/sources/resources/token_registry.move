module wormhole_ntt::token_registry {
    use sui::dynamic_field::{Self};
    use sui::object::{Self, UID};
    use sui::tx_context::{TxContext};
    use sui::coin::{TreasuryCap, CoinMetadata};

    use wormhole::external_address::ExternalAddress;
    use wormhole_ntt::native_token::{Self, NativeToken};

    friend wormhole_ntt::state;
    friend wormhole_ntt::ntt_manager;

    /// Asset is not registered yet.
    const E_UNREGISTERED: u64 = 0;

    /// This container is used to store native tokens type as dynamic fields under its `UID`.
    struct TokenRegistry has key, store {
        id: UID,
        num_tokens: u64,
    }

    /// Container to provide convenient checking of whether an asset is native
    /// `VerifiedAsset` can only be created by passing in a resource with `CoinType`
    ///  to verify the native token is exists in `TokenRegistry`
    struct VerifiedAsset<phantom CoinType> has drop {
        chain: u16,
        addr: ExternalAddress,
        coin_decimals: u8
    }

    /// Wrapper of coin type to act as dynamic field key.
    struct Key<phantom CoinType> has copy, drop, store {}

    /// Wrapper of nft type to act as dynamic field key.
    struct NFTKey<phantom NFTType> has copy, drop, store {}

    /// Determine whether a particular coin type is registered.
    public fun has<CoinType>(self: &TokenRegistry): bool {
        dynamic_field::exists_(&self.id, Key<CoinType> {})
    }

    /// Determine whether a particular coin type is registered with assert.
    public fun assert_has<CoinType>(self: &TokenRegistry) {
        assert!(has<CoinType>(self), E_UNREGISTERED);
    }

    /// used to create the `VerifiedAsset`
    public fun verified_asset<CoinType>(
        self: &TokenRegistry
    ): VerifiedAsset<CoinType> {
        let asset = borrow_native<CoinType>(self);
        let (chain, addr) = native_token::canonical_info(asset);
        let coin_decimals = native_token::decimals(asset);

        VerifiedAsset { chain, addr, coin_decimals }
    }

    /// create new `TokenRegistry`
    public(friend) fun new(
        ctx: &mut TxContext
    ): TokenRegistry {
        TokenRegistry {
            id: object::new(ctx),
            num_tokens: 0,
        }
    }

    /// borrow native token
    public fun borrow_native<CoinType>(
        self: &TokenRegistry
    ): &NativeToken<CoinType> {
        dynamic_field::borrow(&self.id, Key<CoinType> {})
    }

    /// borrow mut native token
    public(friend) fun borrow_mut_native<CoinType>(
        self: &mut TokenRegistry
    ): &mut NativeToken<CoinType> {
        dynamic_field::borrow_mut(&mut self.id, Key<CoinType> {})
    }

    /// Retrieve number of tokens registered in `TokenRegistry`.
    public fun num_tokens(
        self: &TokenRegistry
    ): u64 {
        self.num_tokens
    }

    /// Retrieve canonical token chain id from `VerifiedAsset`.
    public fun token_chain<CoinType>(
        verified: &VerifiedAsset<CoinType>
    ): u16 {
        verified.chain
    }

    /// Retrieve canonical token address from `VerifiedAsset`.
    public fun token_address<CoinType>(
        verified: &VerifiedAsset<CoinType>
    ): ExternalAddress {
        verified.addr
    }

    /// Retrieve decimals for a `VerifiedAsset`.
    public fun coin_decimals<CoinType>(
        verified: &VerifiedAsset<CoinType>
    ): u8 {
        verified.coin_decimals
    }

    /// Add a new native token to the registry
    public(friend) fun add_new_native_token<CoinType>(
        self: &mut TokenRegistry,
        coin_metadata: &CoinMetadata<CoinType>,
        treasury_cap: TreasuryCap<CoinType>,
    ) {
        // Create new native asset.
        let token = native_token::new(coin_metadata, treasury_cap);

        // Add to registry.
        dynamic_field::add(&mut self.id, Key<CoinType> {}, token);
        self.num_tokens = self.num_tokens + 1;
    }

    #[test_only]
    public fun new_test_only(
        ctx: &mut TxContext
    ): TokenRegistry {
        new(ctx)
    }

    #[test_only]
    public fun add_new_native_token_test_only<CoinType>(
        self: &mut TokenRegistry,
        coin_metadata: &CoinMetadata<CoinType>,
        treasury_cap: TreasuryCap<CoinType>,
    ) {
        add_new_native_token(self, coin_metadata, treasury_cap)
    }

    #[test_only]
    public fun remove_new_native_token_test_only<CoinType>(
        self: &mut TokenRegistry,
    ): NativeToken<CoinType> {
        dynamic_field::remove<Key<CoinType>, NativeToken<CoinType>>(&mut self.id, Key<CoinType> {})
    }

    #[test_only]
    public fun destroy_test_only(
        registry: TokenRegistry
    ) {
        let TokenRegistry {
            id,
            num_tokens: _
        } = registry;
        object::delete(id);
    }
}
