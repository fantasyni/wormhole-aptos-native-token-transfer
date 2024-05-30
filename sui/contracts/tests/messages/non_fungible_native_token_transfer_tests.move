#[test_only]
module wormhole_ntt::non_fungible_native_token_transfer_tests {
    use std::vector;

    use wormhole::bytes32::{Self};
    use wormhole::external_address;
    use wormhole_ntt::non_fungible_native_token_transfer::{Self, NonFungibleNativeTokenTransfer};

    fun new_non_fungible_native_token_transfer(): NonFungibleNativeTokenTransfer {
        let to = external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678911111"
        ));

        let to_chain: u16 = 1;
        let token_ids: vector<u256> = vector[];
        vector::push_back(&mut token_ids, 12);
        vector::push_back(&mut token_ids, 23);

        let payload: vector<u8> = vector[];

        non_fungible_native_token_transfer::new_test_only(to, to_chain, token_ids, payload)
    }

    #[test]
    public fun new_encode_decode() {
        let non_fungible_native_token_transfer = new_non_fungible_native_token_transfer();
        let token_id_width = 1;
        let encoded = non_fungible_native_token_transfer::encode_non_fungible_native_token_transfer_test_only(non_fungible_native_token_transfer, token_id_width);
        let decoded_non_fungible_native_token_transfer = non_fungible_native_token_transfer::parse_non_fungible_native_token_transfer_test_only(encoded);

        let (to, to_chain, token_ids, _) = non_fungible_native_token_transfer::into_message_test_only(decoded_non_fungible_native_token_transfer);
        assert!(to == external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678911111"
        )), 0);

        assert!(to_chain == 1, 0);
        assert!(*vector::borrow(&token_ids, 0) == 12, 0);
        assert!(*vector::borrow(&token_ids, 1) == 23, 0);
    }
}
