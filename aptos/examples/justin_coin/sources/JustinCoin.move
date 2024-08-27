module JustinCoin::justin_coin {
    struct JustinCoin {}

    fun init_module(sender: &signer) {
        aptos_framework::managed_coin::initialize<JustinCoin>(
            sender,
            b"Justin Coin",
            b"Justin",
            9,
            false,
        );
    }
}
