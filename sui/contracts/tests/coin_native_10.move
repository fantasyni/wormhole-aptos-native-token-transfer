#[test_only]
module wormhole_ntt::coin_native_10 {
    use std::option::{Self};
    use sui::transfer::{Self};
    use sui::tx_context::{TxContext};
    use sui::test_scenario::{Self, Scenario};
    use sui::coin::{Self, CoinMetadata, TreasuryCap};

    struct COIN_NATIVE_10 has drop {}

    // This module creates a Sui-native token for testing purposes,
    // for example in complete_transfer, where we create a native coin,
    // mint some and deposit in the wormhole_ntt
    // and ultimately transfer a portion of those native coins to a recipient.
    fun init(coin_witness: COIN_NATIVE_10, ctx: &mut TxContext) {
        let (
            treasury_cap,
            coin_metadata
        ) =
            coin::create_currency(
                coin_witness,
                10,
                b"DEC10",
                b"Decimals 10",
                b"Coin with 10 decimals for testing purposes.",
                option::none(),
                ctx
            );

        // Let's make the metadata shared.
        transfer::public_share_object(coin_metadata);

        // Give everyone access to `TrasuryCap`.
        transfer::public_share_object(treasury_cap);
    }

    #[test_only]
    public fun init_test_only(ctx: &mut TxContext) {
        init(COIN_NATIVE_10 {}, ctx);
    }

    public fun take_metadata(
        scenario: &Scenario
    ): CoinMetadata<COIN_NATIVE_10> {
        test_scenario::take_shared(scenario)
    }

    public fun return_metadata(
        metadata: CoinMetadata<COIN_NATIVE_10>
    ) {
        test_scenario::return_shared(metadata);
    }

    public fun take_treasury_cap(
        scenario: &Scenario
    ): TreasuryCap<COIN_NATIVE_10> {
        test_scenario::take_shared(scenario)
    }

    public fun return_treasury_cap(
        treasury_cap: TreasuryCap<COIN_NATIVE_10>
    ) {
        test_scenario::return_shared(treasury_cap);
    }

    public fun take_globals(
        scenario: &Scenario
    ): (
        TreasuryCap<COIN_NATIVE_10>,
        CoinMetadata<COIN_NATIVE_10>
    ) {
        (
            take_treasury_cap(scenario),
            take_metadata(scenario)
        )
    }

    public fun return_globals(
        treasury_cap: TreasuryCap<COIN_NATIVE_10>,
        metadata: CoinMetadata<COIN_NATIVE_10>
    ) {
        return_treasury_cap(treasury_cap);
        return_metadata(metadata);
    }
}
