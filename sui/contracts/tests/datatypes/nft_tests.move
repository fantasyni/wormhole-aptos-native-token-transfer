#[test_only]
module wormhole_ntt::nft_tests {
    use std::debug;
    use sui::test_scenario;
    use wormhole_ntt::nft::{Self, TreasuryCap};
    use wormhole_ntt::justin_nft::{Self, JUSTIN_NFT};

    #[test]
    public fun test_nft() {
        let caller = @0xC0B2;
        let my_scenario = test_scenario::begin(caller);
        let scenario = &mut my_scenario;

        justin_nft::init_test_only(test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, caller);

        let treasury_cap = test_scenario::take_from_sender<TreasuryCap<JUSTIN_NFT>>(scenario);

        let token_id_1 = 10086;
        let token_id_2 = 12345;

        let nft1 = nft::mint(&mut treasury_cap, token_id_1, test_scenario::ctx(scenario));
        assert!(nft::token_id(&nft1) == token_id_1, 0);

        let nft2 = nft::mint(&mut treasury_cap, token_id_2, test_scenario::ctx(scenario));
        assert!(nft::token_id(&nft2) == token_id_2, 0);

        debug::print(&nft::nft_url(&nft1));
        debug::print(&nft::nft_url(&nft2));

        nft::burn(&mut treasury_cap, nft1);
        nft::burn(&mut treasury_cap, nft2);

        nft::destroy_treasury_cap(treasury_cap);
        
        test_scenario::end(my_scenario);
    }
}
