#[test_only]
module wormhole_ntt::native_token_transfer_tests {
    use wormhole::bytes32::{Self};
    use wormhole::external_address;
    use wormhole_ntt::trimmed_amount::{Self};
    use wormhole_ntt::native_token_transfer::{Self, NativeTokenTransfer};

    fun new_native_token_transfer(): NativeTokenTransfer {
        let trimmed_amount = trimmed_amount::new(900, 3);
        let source_token = external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678912345"
        ));

        let to = external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678911111"
        ));

        let to_chain: u16 = 1;
        let native_token_transfer = native_token_transfer::new_test_only(trimmed_amount, source_token, to, to_chain);
        native_token_transfer
    }

    #[test]
    public fun new_encode_decode() {
        let native_token_transfer= new_native_token_transfer();

        let encoded = native_token_transfer::encode_native_token_transfer_test_only(native_token_transfer);
        let decoded_native_token_transfer = native_token_transfer::parse_native_token_transfer_test_only(encoded);

        let (amount, source_token, to, to_chain) = native_token_transfer::into_message_test_only(decoded_native_token_transfer);
        assert!(amount == trimmed_amount::new(900, 3), 0);
        assert!(source_token == external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678912345"
        )), 0);
        assert!(to == external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678911111"
        )), 0);
        assert!(to_chain == 1, 0);
    }
}
