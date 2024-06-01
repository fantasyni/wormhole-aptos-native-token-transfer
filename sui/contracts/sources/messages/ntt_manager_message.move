module wormhole_ntt::ntt_manager_message {
    use std::vector::{Self};

    use wormhole::bytes::{Self};
    use wormhole::cursor::{Self};
    use wormhole::bytes32::{Self, Bytes32};
    use wormhole::external_address::{Self, ExternalAddress};

    struct NttManagerMessage {
        // unique message identifier
        id: Bytes32,
        // original message sender address.
        sender: ExternalAddress,
        // payload that corresponds to the type.
        payload: vector<u8>,
    }

    const E_PAYLOAD_TOO_LONG: u64 = 0;

    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::transceiver_message;
    friend wormhole_ntt::non_fungible_ntt_manager;

    public(friend) fun new(
        id: Bytes32,
        sender: ExternalAddress,
        payload: vector<u8>
    ): NttManagerMessage {
        NttManagerMessage {
            id,
            sender,
            payload
        }
    }

    public(friend) fun into_message(
        message: NttManagerMessage
    ):(
        Bytes32,
        ExternalAddress,
        vector<u8>
    ) {
        let NttManagerMessage {
            id,
            sender,
            payload
        } = message;
        (id, sender, payload)
    }

    public(friend) fun encode_ntt_manager_message(
        message: NttManagerMessage
    ): vector<u8> {
        let NttManagerMessage {id, sender, payload} = message;
        assert!(vector::length(&payload) < (((1<<16)-1) as u64), E_PAYLOAD_TOO_LONG);
        let payload_length = (vector::length(&payload) as u16);

        let buf: vector<u8> = vector::empty<u8>();

        vector::append(&mut buf, bytes32::to_bytes(id));
        vector::append(&mut buf, external_address::to_bytes(sender));
        bytes::push_u16_be(&mut buf, payload_length);
        vector::append(&mut buf, payload);

        buf
    }

    public(friend) fun parse_ntt_manager_message(
        buf: vector<u8>
    ): NttManagerMessage {
        let cur = cursor::new(buf);

        let id = bytes32::take_bytes(&mut cur);
        let sender = external_address::take_bytes(&mut cur);
        let payload_length = bytes::take_u16_be(&mut cur);
        let payload = bytes::take_bytes(&mut cur, (payload_length as u64));

        cursor::destroy_empty(cur);

        NttManagerMessage {
            id,
            sender,
            payload
        }
    }

    #[test_only]
    public fun new_test_only(
        id: Bytes32,
        sender: ExternalAddress,
        payload: vector<u8>
    ): NttManagerMessage {
        new(id, sender, payload)
    }

    #[test_only]
    public fun into_message_test_only(
        message: NttManagerMessage
    ):(
        Bytes32,
        ExternalAddress,
        vector<u8>
    ) {
        into_message(message)
    }

    #[test_only]
    public fun encode_ntt_manager_message_test_only(
        message: NttManagerMessage
    ): vector<u8> {
        encode_ntt_manager_message(message)
    }

    #[test_only]
    public fun parse_ntt_manager_message_test_only(
        buf: vector<u8>
    ): NttManagerMessage {
        parse_ntt_manager_message(buf)
    }
}
