module wormhole_ntt::native_token {
    use sui::object::{Self};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, CoinMetadata, TreasuryCap};

    use wormhole::state::{chain_id};
    use wormhole::external_address::{Self, ExternalAddress};

    friend wormhole_ntt::setup;
    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::token_registry;

    /// Container for storing token address, custodied `Balance`, and `TreasuryCap` .
    struct NativeToken<phantom C> has store {
        custody: Balance<C>,
        treasury_cap: TreasuryCap<C>,
        token_address: ExternalAddress,
        decimals: u8
    }

    /// Create Native Token
    public(friend) fun new<C>(
        metadata: &CoinMetadata<C>,
        treasury_cap: TreasuryCap<C>
    ): NativeToken<C> {
        NativeToken {
            custody: balance::zero(),
            token_address: canonical_address(metadata),
            decimals: coin::get_decimals(metadata),
            treasury_cap,
        }
    }

    /// WormholeNtt identifies native assets using `CoinMetadata` object `ID`.
    /// This method converts this `ID` to `ExternalAddress`.
    public fun canonical_address<C>(
        metadata: &CoinMetadata<C>
    ): ExternalAddress {
        external_address::from_id(object::id(metadata))
    }

    /// Retrieve canonical token address.
    public fun token_address<C>(
        self: &NativeToken<C>
    ): ExternalAddress {
        self.token_address
    }

    /// Retrieve decimals, which originated from `CoinMetadata`.
    public fun decimals<C>(
        self: &NativeToken<C>
    ): u8 {
        self.decimals
    }

    /// Retrieve canonical token chain ID (Sui's) and token address.
    public fun canonical_info<C>(
        self: &NativeToken<C>
    ): (u16, ExternalAddress) {
        (chain_id(), token_address(self))
    }

    /// Retrieve custodied `Balance` value.
    public fun custody<C>(
        self: &NativeToken<C>
    ): u64 {
        balance::value(&self.custody)
    }

    /// Retrieve total_supply of the native token.
    public fun total_supply<C>(self: &NativeToken<C>): u64 {
        coin::total_supply(&self.treasury_cap)
    }

    /// Burn a given `Balance`. `Balance` originates from an outbound token
    public(friend) fun burn<C>(
        self: &mut NativeToken<C>,
        burned: Balance<C>
    ) {
        let total_supply = coin::supply_mut(&mut self.treasury_cap);
        balance::decrease_supply(total_supply, burned);
    }

    /// Mint a given amount. This amount is determined by an inbound token
    public(friend) fun mint<C>(
        self: &mut NativeToken<C>,
        amount: u64
    ): Balance<C> {
        coin::mint_balance(&mut self.treasury_cap, amount)
    }

    /// Deposit a given `Balance`. `Balance` originates from an outbound token
    public(friend) fun deposit<C>(
        self: &mut NativeToken<C>,
        deposited: Balance<C>
    ) {
        balance::join(&mut self.custody, deposited);
    }

    /// Withdraw a given amount from custody. This amount is determiend by an
    /// inbound token transfer payload for a native asset.
    public(friend) fun withdraw<C>(
        self: &mut NativeToken<C>,
        amount: u64
    ): Balance<C> {
        balance::split(&mut self.custody, amount)
    }

    #[test_only]
    public fun new_test_only<C>(
        metadata: &CoinMetadata<C>,
        treasury_cap: TreasuryCap<C>
    ): NativeToken<C> {
        new(metadata, treasury_cap)
    }

    #[test_only]
    public fun burn_test_only<C>(
        self: &mut NativeToken<C>,
        burned: Balance<C>
    ) {
        burn(self, burned)
    }

    #[test_only]
    public fun mint_test_only<C>(
        self: &mut NativeToken<C>,
        amount: u64
    ): Balance<C> {
        mint(self, amount)
    }

    #[test_only]
    public fun deposit_test_only<C>(
        self: &mut NativeToken<C>,
        deposited: Balance<C>
    ) {
        deposit(self, deposited)
    }

    #[test_only]
    public fun withdraw_test_only<C>(
        self: &mut NativeToken<C>,
        amount: u64
    ): Balance<C> {
        withdraw(self, amount)
    }

    #[test_only]
    public fun destroy<C>(asset: NativeToken<C>) {
        let NativeToken {
            custody,
            token_address: _,
            decimals: _,
            treasury_cap
        } = asset;
        balance::destroy_for_testing(custody);
        sui::test_utils::destroy(treasury_cap);
    }
}
