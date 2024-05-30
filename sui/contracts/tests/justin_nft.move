#[test_only]
module wormhole_ntt::justin_nft {
    use sui::transfer;
    use std::string::{Self};
    use sui::tx_context::{Self, TxContext};

    use wormhole_ntt::nft::{Self};

    struct JUSTIN_NFT has drop {}

    fun init(coin_witness: JUSTIN_NFT, ctx: &mut TxContext) {
        let name = b"JUSTIN_MFT";
        let description = b"justin nft description";
        let base_url = b"https://justin.com/";

        let treasury_cap = nft::create_nft(
            coin_witness,
            name,
            description,
            base_url,
            ctx
        );

        assert!(nft::name(&treasury_cap) == string::utf8(name), 0);
        assert!(nft::description(&treasury_cap) == string::utf8(description), 0);
        assert!(nft::base_url(&treasury_cap) == string::utf8(base_url), 0);

        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    #[test_only]
    public fun init_test_only(ctx: &mut TxContext) {
        init(JUSTIN_NFT {}, ctx);
    }
}
