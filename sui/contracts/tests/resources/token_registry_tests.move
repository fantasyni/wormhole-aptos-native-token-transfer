#[test_only]
module wormhole_ntt::token_registry_tests {
    use sui::object::{Self};
    use sui::test_scenario::{Self};
    use wormhole::external_address;

    use wormhole::state::{chain_id};
    use wormhole_ntt::token_registry;
    use wormhole_ntt::native_token;
    use wormhole_ntt::coin_native_6::{Self, COIN_NATIVE_6};

    #[test]
    public fun test_token_registry() {
        let caller = @0xC0B2;
        let my_scenario = test_scenario::begin(caller);
        let scenario = &mut my_scenario;

        let token_registry = token_registry::new_test_only(test_scenario::ctx(scenario));

        coin_native_6::init_test_only(test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, caller);

        let coin_meta = coin_native_6::take_metadata(scenario);
        let coin_treasury_cap = coin_native_6::take_treasury_cap(scenario);
        token_registry::add_new_native_token_test_only(&mut token_registry, &coin_meta, coin_treasury_cap);
        assert!(token_registry::num_tokens(&token_registry) == 1, 0);

        let native_token = token_registry::borrow_native<COIN_NATIVE_6>(&token_registry);
        assert!(native_token::decimals(native_token) == 6, 0);

        let coin_address = external_address::from_id(object::id(&coin_meta));
        let verified_asset = token_registry::verified_asset<COIN_NATIVE_6>(&token_registry);
        assert!(token_registry::coin_decimals(&verified_asset) == 6, 0);
        assert!(token_registry::token_address(&verified_asset) == coin_address, 0);
        assert!(token_registry::token_chain(&verified_asset) == chain_id(), 0);

        let removed_token = token_registry::remove_new_native_token_test_only<COIN_NATIVE_6>(&mut token_registry);

        native_token::destroy(removed_token);
        coin_native_6::return_metadata(coin_meta);
        token_registry::destroy_test_only(token_registry);
        test_scenario::end(my_scenario);
    }

    // #[test]
    // #[expected_failure(abort_code = sui::dynamic_field::EFieldAlreadyExists)]
    // public fun test_cannot_add_new_native_token_again() {
    //     let caller = @0xC0B2;
    //     let my_scenario = test_scenario::begin(caller);
    //     let scenario = &mut my_scenario;
    //
    //     let token_registry = token_registry::new_test_only(test_scenario::ctx(scenario));
    //
    //     coin_native_6::init_test_only(test_scenario::ctx(scenario));
    //
    //     test_scenario::next_tx(scenario, caller);
    //
    //     let coin_meta_6 = coin_native_6::take_metadata(scenario);
    //     let coin_treasury_cap_6 = coin_native_6::take_treasury_cap(scenario);
    //     token_registry::add_new_native_token_test_only(&mut token_registry, &coin_meta_6, coin_treasury_cap_6);
    //
    //     coin_native_6::init_test_only(test_scenario::ctx(scenario));
    //
    //     test_scenario::next_tx(scenario, caller);
    //
    //     let coin_meta = coin_native_6::take_metadata(scenario);
    //     let coin_treasury_cap = coin_native_6::take_treasury_cap(scenario);
    //     token_registry::add_new_native_token_test_only(&mut token_registry, &coin_meta, coin_treasury_cap);
    //
    //     abort 10
    // }
}
