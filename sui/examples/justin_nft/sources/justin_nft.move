/// Module: justin_nft
module justin_nft::justin_nft {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    
    use wormhole_ntt::nft::{Self, TreasuryCap};

    struct JUSTIN_NFT has drop {}

    fun init(coin_witness: JUSTIN_NFT, ctx: &mut TxContext) {
        let name = b"JUSTIN_NFT";
        let description = b"justin nft description";
        let base_url = b"https://avatars.githubusercontent.com/u/1411347?v=";

        let treasury_cap = nft::create_nft(
            coin_witness,
            name,
            description,
            base_url,
            ctx
        );

        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    public fun mint(cap: &mut TreasuryCap<JUSTIN_NFT>, token_id: u256, recipient: address, ctx: &mut TxContext) {
        transfer::public_transfer(nft::mint(cap, token_id, ctx), recipient)
    }
}

/*
export GAS_BUDGET=100000000
export PACKAGE_ID=0x7d69e6268080a452e1577412108257a637fa16b21e1a1b67471b5b7fbdd205ab
export TREASURY_CAP=0x6e35bc509996c2c38d41c274a6e044a0e036635fa3a3b48cb358d79dcf4e5379
export ADDRESS=0x7e3b752c4c49fda9af01caeb34ec39475f3d7f9002ee06e53fa275421d7b7f2c
sui client call --function mint --package $PACKAGE_ID --module justin_nft --args $TREASURY_CAP 1 $ADDRESS --gas-budget $GAS_BUDGET
*/