module wormhole_ntt::transceiver_message {
    use std::vector::{Self};

    use wormhole::bytes::{Self};
    use wormhole::cursor::{Self};
    use wormhole_ntt::bytes4::{Self};
    use wormhole::external_address::{Self, ExternalAddress};
    use wormhole_ntt::ntt_manager_message::{Self, NttManagerMessage};

    const E_PAYLOAD_TOO_LONG: u64 = 0;
    const E_INCORRECT_PREFIX: u64 = 1;
    const WH_TRANSCEIVER_PAYLOAD_PREFIX: vector<u8> = x"9945FF10";

    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::ntt_transceiver;

    struct TransceiverMessage {
        // Address of the contract that emitted this message, in sui it is the State object id.
        source_ntt_manager_address: ExternalAddress,
        // Address of the NttManager contract that receives this message.
        recipient_ntt_manager_address: ExternalAddress,
        // Payload provided to the Transceiver contract by the NttManager contract.
        ntt_manager_payload: vector<u8>,
        // Optional payload that the transceiver can encode and use for its own message passing purposes.
        transceiver_payload: vector<u8>
    }

    public(friend) fun into_message(
        message: TransceiverMessage
    ): (
        ExternalAddress,
        ExternalAddress,
        vector<u8>,
        vector<u8>
    ) {
        let TransceiverMessage {
            source_ntt_manager_address,
            recipient_ntt_manager_address,
            ntt_manager_payload,
            transceiver_payload
        } = message;

        (source_ntt_manager_address, recipient_ntt_manager_address, ntt_manager_payload, transceiver_payload)
    }

    fun encode_transceiver_message(
        message: TransceiverMessage
    ): vector<u8> {
        let TransceiverMessage {
            source_ntt_manager_address,
            recipient_ntt_manager_address,
            ntt_manager_payload,
            transceiver_payload
        } = message;
        let ntt_manager_payload_length: u16 = (vector::length(&ntt_manager_payload) as u16);
        let transceiver_payload_length: u16 = (vector::length(&transceiver_payload) as u16);

        assert!(ntt_manager_payload_length < (((1<<16)-1) as u16), E_PAYLOAD_TOO_LONG);
        assert!(transceiver_payload_length < (((1<<16)-1) as u16), E_PAYLOAD_TOO_LONG);

        let buf: vector<u8> = vector::empty<u8>();

        vector::append(&mut buf, WH_TRANSCEIVER_PAYLOAD_PREFIX);
        vector::append(&mut buf, external_address::to_bytes(source_ntt_manager_address));
        vector::append(&mut buf, external_address::to_bytes(recipient_ntt_manager_address));
        bytes::push_u16_be(&mut buf, ntt_manager_payload_length);
        vector::append(&mut buf, ntt_manager_payload);
        bytes::push_u16_be(&mut buf, transceiver_payload_length);
        vector::append(&mut buf, transceiver_payload);

        buf
    }

    public(friend) fun build_and_encode_transceiver_message(
        source_ntt_manager_address: ExternalAddress,
        recipient_ntt_manager_address: ExternalAddress,
        ntt_manager_payload: vector<u8>,
        transceiver_payload: vector<u8>
    ): vector<u8> {
        let transeiver_message = TransceiverMessage {
            source_ntt_manager_address,
            recipient_ntt_manager_address,
            ntt_manager_payload,
            transceiver_payload,
        };

        encode_transceiver_message(transeiver_message)
    }

    fun parse_transceiver_message(
        encoded: vector<u8>
    ): TransceiverMessage {
        let cur = cursor::new(encoded);

        let transceiver_prefix = bytes4::take(&mut cur);
        let transceiver_prefix_bytes = bytes4::to_bytes(transceiver_prefix);
        assert!(transceiver_prefix_bytes == WH_TRANSCEIVER_PAYLOAD_PREFIX, E_INCORRECT_PREFIX);

        let source_ntt_manager_address = external_address::take_bytes(&mut cur);
        let recipient_ntt_manager_address = external_address::take_bytes(&mut cur);
        let ntt_manager_payload_length = bytes::take_u16_be(&mut cur);
        let ntt_manager_payload = bytes::take_bytes(&mut cur, (ntt_manager_payload_length as u64));
        let transceiver_payload_length = bytes::take_u16_be(&mut cur);
        let transceiver_payload = bytes::take_bytes(&mut cur, (transceiver_payload_length as u64));

        cursor::destroy_empty(cur);

        TransceiverMessage {
            source_ntt_manager_address,
            recipient_ntt_manager_address,
            ntt_manager_payload,
            transceiver_payload,
        }
    }

    public(friend) fun parse_transceiver_and_ntt_manager_message(
        payload: vector<u8>
    ): (ExternalAddress, ExternalAddress, NttManagerMessage) {
        let parsed_transceiver_message = parse_transceiver_message(payload);
        let (source_ntt_manager_address,
            recipient_ntt_manager_address,
            ntt_manager_payload,
            _) = into_message(parsed_transceiver_message);

        let parsed_ntt_manager_message = ntt_manager_message::parse_ntt_manager_message(ntt_manager_payload);

        (source_ntt_manager_address, recipient_ntt_manager_address, parsed_ntt_manager_message)
    }

    #[test_only]
    public fun into_message_test_only(
        message: TransceiverMessage
    ): (
        ExternalAddress,
        ExternalAddress,
        vector<u8>,
        vector<u8>
    ) {
        into_message(message)
    }

    #[test_only]
    public fun build_and_encode_transceiver_message_test_only(
        source_ntt_manager_address: ExternalAddress,
        recipient_ntt_manager_address: ExternalAddress,
        ntt_manager_payload: vector<u8>,
        transceiver_payload: vector<u8>
    ): vector<u8> {
        build_and_encode_transceiver_message(source_ntt_manager_address, recipient_ntt_manager_address, ntt_manager_payload, transceiver_payload)
    }

    #[test_only]
    public fun parse_transceiver_message_test_only(
        encoded: vector<u8>
    ): TransceiverMessage {
        parse_transceiver_message(encoded)
    }

    #[test_only]
    public fun parse_transceiver_and_ntt_manager_message_test_only(
        payload: vector<u8>
    ): (ExternalAddress, ExternalAddress, NttManagerMessage) {
        parse_transceiver_and_ntt_manager_message(payload)
    }
}
