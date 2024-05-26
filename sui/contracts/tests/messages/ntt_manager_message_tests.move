#[test_only]
module wormhole_ntt::ntt_manager_message_tests {
    use wormhole::bytes32;
    use wormhole::external_address;
    use wormhole_ntt::ntt_manager_message::{Self, NttManagerMessage};

    fun new_ntt_manager_message(): NttManagerMessage {
        let id = bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678912345"
        );

        let sender = external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678911111"
        ));

        let payload = x"12345678";
        let ntt_manager_message = ntt_manager_message::new_test_only(id, sender, payload);
        ntt_manager_message
    }

    #[test]
    public fun new_encode_decode() {
        let ntt_manager_message = new_ntt_manager_message();

        let encoded = ntt_manager_message::encode_ntt_manager_message_test_only(ntt_manager_message);
        let decoded_ntt_manager_message = ntt_manager_message::parse_ntt_manager_message_test_only(encoded);

        let (id, sender, payload) = ntt_manager_message::into_message_test_only(decoded_ntt_manager_message);
        assert!(id == bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678912345"
        ), 0);
        assert!(sender == external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678911111"
        )), 0);
        assert!(payload == x"12345678", 0);
    }
}
