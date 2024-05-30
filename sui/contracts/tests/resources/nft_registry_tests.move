#[test_only]
module wormhole_ntt::nft_registry_tests {
    use sui::test_scenario;

    use wormhole_ntt::nft_token::{Self};
    use wormhole_ntt::nft::{TreasuryCap};
    use wormhole_ntt::nft_registry::{Self};
    use wormhole_ntt::justin_nft::{Self, JUSTIN_NFT};

    #[test]
    public fun test_nft_registry() {
        let caller = @0xC0B2;
        let my_scenario = test_scenario::begin(caller);
        let scenario = &mut my_scenario;

        justin_nft::init_test_only(test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, caller);

        let treasury_cap = test_scenario::take_from_sender<TreasuryCap<JUSTIN_NFT>>(scenario);

        let nft_registry = nft_registry::new_test_only(test_scenario::ctx(scenario));
        nft_registry::add_new_nft_test_only(&mut nft_registry, treasury_cap, test_scenario::ctx(scenario));

        assert!(nft_registry::num_nfts(&nft_registry) == 1, 0);

        let _verified_nft = nft_registry::verified_nft<JUSTIN_NFT>(&nft_registry);

        let nft_token = nft_registry::remove_new_nft_test_only<JUSTIN_NFT>(&mut nft_registry);

        nft_token::destroy(nft_token);

        nft_registry::destroy_test_only(nft_registry);

        test_scenario::end(my_scenario);
    }
}
