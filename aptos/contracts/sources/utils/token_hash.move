/// 32 byte hash representing an arbitrary Aptos token, to be used in VAAs to
/// refer to coins.
module wormhole_ntt::token_hash {
    use std::hash;
    use std::string;
    use aptos_framework::type_info;

    use wormhole_ntt::bytes32::{Self};
    use wormhole_ntt::ntt_external_address::{Self, NttExternalAddress};

    struct TokenHash has drop, copy, store {
        // 32 bytes
        hash: vector<u8>,
    }

    public fun get_external_address(a: &TokenHash): NttExternalAddress {
        ntt_external_address::new(bytes32::from_bytes(a.hash))
    }

    /// Get the 32 token address of an arbitary CoinType
    public fun derive<CoinType>(): TokenHash {
        let type_name = type_info::type_name<CoinType>();
        let hash = hash::sha3_256(*string::bytes(&type_name));
        TokenHash { hash }
    }

}