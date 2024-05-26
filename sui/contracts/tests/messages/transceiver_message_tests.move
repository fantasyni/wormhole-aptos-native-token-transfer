#[test_only]
module wormhole_ntt::transceiver_message_tests {
    use std::vector;
    use wormhole::bytes32::{Self};
    use wormhole::external_address;
    use wormhole_ntt::transceiver_message::{Self};

    #[test]
    public fun new_encode_decode() {
        let source_ntt_manager_address = external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678912345"
        ));

        let recipient_ntt_manager_address = external_address::new(bytes32::new(
            x"1234567891234567891234567891234512345678912345678912345678911111"
        ));

        let ntt_manager_payload = x"12345678";
        let transceiver_payload = vector::empty<u8>();

        let encoded = transceiver_message::build_and_encode_transceiver_message_test_only(source_ntt_manager_address, recipient_ntt_manager_address, ntt_manager_payload, transceiver_payload);
        let decoded_transceiver_message = transceiver_message::parse_transceiver_message_test_only(encoded);
        let (source_ntt_manager_address_2, recipient_ntt_manager_address_2, ntt_manager_payload_2, transceiver_payload_2)
            = transceiver_message::into_message_test_only(decoded_transceiver_message);
        assert!(source_ntt_manager_address == source_ntt_manager_address_2, 0);
        assert!(recipient_ntt_manager_address == recipient_ntt_manager_address_2, 0);
        assert!(ntt_manager_payload == ntt_manager_payload_2, 0);
        assert!(transceiver_payload == transceiver_payload_2, 0);
    }
}
