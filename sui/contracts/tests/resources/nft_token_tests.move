#[test_only]
module wormhole_ntt::nft_token_tests {
    use sui::test_scenario;

    use wormhole_ntt::nft_token::{Self};
    use wormhole_ntt::nft::{Self, TreasuryCap};
    use wormhole_ntt::justin_nft::{Self, JUSTIN_NFT};

    #[test]
    fun test_nft_token() {
        let caller = @0xC0B2;
        let my_scenario = test_scenario::begin(caller);
        let scenario = &mut my_scenario;

        justin_nft::init_test_only(test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, caller);

        let treasury_cap = test_scenario::take_from_sender<TreasuryCap<JUSTIN_NFT>>(scenario);

        let nft_token_data = nft_token::new_test_only(treasury_cap, test_scenario::ctx(scenario));

        let token_id_1 = 10086;
        let token_id_2 = 12345;
        let token_id_3 = 32009;

        let nft1 = nft_token::mint_test_only(&mut nft_token_data, token_id_1, test_scenario::ctx(scenario));
        assert!(nft::token_id(&nft1) == token_id_1, 0);

        let nft2 = nft_token::mint_test_only(&mut nft_token_data, token_id_2, test_scenario::ctx(scenario));
        assert!(nft::token_id(&nft2) == token_id_2, 0);

        assert!(nft_token::burn_test_only(&mut nft_token_data, nft1) == token_id_1, 0);
        assert!(nft_token::burn_test_only(&mut nft_token_data, nft2) == token_id_2, 0);

        let nft3 = nft_token::mint_test_only(&mut nft_token_data, token_id_3, test_scenario::ctx(scenario));
        assert!(nft::token_id(&nft3) == token_id_3, 0);

        assert!(nft_token::deposit_test_only(&mut nft_token_data, nft3) == token_id_3, 0);
        let nft3_withdraw = nft_token::withdraw_test_only(&mut nft_token_data, token_id_3);
        assert!(nft::token_id(&nft3_withdraw) == token_id_3, 0);
        assert!(nft_token::burn_test_only(&mut nft_token_data, nft3_withdraw) == token_id_3, 0);

        nft_token::destroy(nft_token_data);

        test_scenario::end(my_scenario);
    }
}
