module justin_coin::justin_coin {
    use std::option;
    use sui::coin::{Self, TreasuryCap};
    use sui::transfer;
    use sui::tx_context;
    use sui::tx_context::TxContext;

    public struct JUSTIN_COIN has drop {}

    #[allow(unused_function)]
    fun init(witness: JUSTIN_COIN, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<JUSTIN_COIN>(witness, 9, b"Justin", b"", b"", option::none(), ctx);
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx))
    }

    public entry fun mint(treasury_cap: &mut TreasuryCap<JUSTIN_COIN>, amount: u64, recipient: address, ctx: &mut TxContext) {
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }
}