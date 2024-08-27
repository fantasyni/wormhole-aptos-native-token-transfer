//:!:>justin
script {
    fun register(account: &signer) {
        aptos_framework::managed_coin::register<JustinCoin::justin_coin::JustinCoin>(account)
    }
}
//<:!:justin
