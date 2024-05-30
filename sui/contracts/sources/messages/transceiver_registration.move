module wormhole_ntt::transceiver_registration {
    use std::vector::{Self};

    use wormhole::bytes::{Self};
    use wormhole::cursor::{Self};
    use wormhole_ntt::bytes4::{Self, Bytes4};
    use wormhole::external_address::{Self, ExternalAddress};

    const E_INCORRECT_PREFIX: u64 = 0;

    struct TransceiverRegistration {
        transceiver_identifier: Bytes4,
        transceiver_chainId: u16,
        transceiver_address: ExternalAddress
    }

    public(friend) fun new(
        transceiver_identifier: Bytes4,
        transceiver_chainId: u16,
        transceiver_address: ExternalAddress
    ): TransceiverRegistration {
        TransceiverRegistration {
            transceiver_identifier,
            transceiver_chainId,
            transceiver_address
        }
    }

    public(friend) fun encode_transceiver_registration(
        message: TransceiverRegistration
    ): vector<u8> {
        let TransceiverRegistration {
            transceiver_identifier,
            transceiver_chainId,
            transceiver_address
        } = message;

        let buf: vector<u8> = vector::empty<u8>();

        vector::append(&mut buf, bytes4::to_bytes(transceiver_identifier));
        bytes::push_u16_be(&mut buf, transceiver_chainId);
        vector::append(&mut buf, external_address::to_bytes(transceiver_address));

        buf
    }

    public(friend) fun decode_transceiver_registration(
        expected_prefix: Bytes4,
        encoded: vector<u8>
    ): TransceiverRegistration {
        let cur = cursor::new(encoded);

        let transceiver_identifier = bytes4::take(&mut cur);
        assert!(transceiver_identifier == expected_prefix, E_INCORRECT_PREFIX);

        let transceiver_chainId = bytes::take_u16_be(&mut cur);
        let transceiver_address = external_address::take_bytes(&mut cur);

        cursor::destroy_empty(cur);

        TransceiverRegistration {
            transceiver_identifier,
            transceiver_chainId,
            transceiver_address
        }
    }
}
