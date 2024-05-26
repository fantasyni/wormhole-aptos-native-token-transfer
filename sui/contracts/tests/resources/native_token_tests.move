#[test_only]
module wormhole_ntt::native_token_tests {
    use sui::object::{Self};
    use sui::balance::{Self};
    use sui::test_scenario::{Self};

    use wormhole_ntt::native_token;
    use wormhole::state::{chain_id};
    use wormhole::external_address::{Self};
    use wormhole_ntt::coin_native_6::{Self};

    #[test]
    public fun test_native_token() {
        let caller = @0xC0B1;
        let my_scenario = test_scenario::begin(caller);
        let scenario = &mut my_scenario;

        coin_native_6::init_test_only(test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, caller);

        let coin_meta = coin_native_6::take_metadata(scenario);
        let coin_treasury_cap = coin_native_6::take_treasury_cap(scenario);
        let coin_token_address = external_address::from_id(object::id(&coin_meta));

        let native_token = native_token::new_test_only(&coin_meta, coin_treasury_cap);

        assert!(native_token::decimals(&native_token) == 6, 0);
        assert!(native_token::custody(&native_token) == 0, 0);

        let (token_chain_id, token_address) = native_token::canonical_info(&native_token);
        assert!(token_chain_id == chain_id(), 0);
        assert!(token_address == coin_token_address, 0);

        let deposit_amount = 1000;
        native_token::deposit_test_only(&mut native_token, balance::create_for_testing(deposit_amount));
        assert!(native_token::custody(&native_token) == 1000, 0);

        let withdraw_balance = native_token::withdraw_test_only(&mut native_token, 100);
        assert!(balance::value(&withdraw_balance) == 100, 0);
        assert!(native_token::custody(&native_token) == 900, 0);

        let mint_amount = 520;
        let minted_balance = native_token::mint_test_only(&mut native_token, mint_amount);
        assert!(balance::value(&minted_balance) == mint_amount, 0);
        assert!(native_token::total_supply(&native_token) == mint_amount, 0);

        let burned_amount = 50;
        let burned_balance = balance::split(&mut minted_balance, burned_amount);
        assert!(balance::value(&burned_balance) == burned_amount, 0);
        native_token::burn_test_only(&mut native_token, burned_balance);
        assert!(native_token::total_supply(&native_token) == mint_amount - burned_amount, 0);
        native_token::burn_test_only(&mut native_token, minted_balance);
        assert!(native_token::total_supply(&native_token) == 0, 0);

        balance::destroy_for_testing(withdraw_balance);
        coin_native_6::return_metadata(coin_meta);
        native_token::destroy(native_token);
        test_scenario::end(my_scenario);
    }
}
