module wormhole_ntt::transceiver_init {
    use std::vector::{Self};

    use wormhole::bytes::{Self};
    use wormhole::cursor::{Self};
    use wormhole_ntt::bytes4::{Self, Bytes4};
    use wormhole::external_address::{Self, ExternalAddress};

    const E_INCORRECT_PREFIX: u64 = 0;

    struct TransceiverInit {
        transceiver_identifer: Bytes4,
        ntt_manager_address: ExternalAddress,
        ntt_manager_mode: u8,
        token_address: ExternalAddress,
        token_decimals: u8
    }

    public(friend) fun new(
        transceiver_identifer: Bytes4,
        ntt_manager_address: ExternalAddress,
        ntt_manager_mode: u8,
        token_address: ExternalAddress,
        token_decimals: u8
    ): TransceiverInit {
        TransceiverInit {
            transceiver_identifer,
            ntt_manager_address,
            ntt_manager_mode,
            token_address,
            token_decimals
        }
    }

    public(friend) fun encode_transceiver_init(message: TransceiverInit): vector<u8> {
        let TransceiverInit {
            transceiver_identifer,
            ntt_manager_address,
            ntt_manager_mode,
            token_address,
            token_decimals
        } = message;

        let buf: vector<u8> = vector::empty<u8>();

        vector::append(&mut buf, bytes4::to_bytes(transceiver_identifer));
        vector::append(&mut buf, external_address::to_bytes(ntt_manager_address));
        bytes::push_u8(&mut buf, ntt_manager_mode);
        vector::append(&mut buf, external_address::to_bytes(token_address));
        bytes::push_u8(&mut buf, token_decimals);

        buf
    }

    public(friend) fun decode_transceiver_init(expected_prefix: Bytes4, encoded: vector<u8>): TransceiverInit {
        let cur = cursor::new(encoded);

        let transceiver_identifer = bytes4::take(&mut cur);
        assert!(transceiver_identifer == expected_prefix, E_INCORRECT_PREFIX);

        let ntt_manager_address = external_address::take_bytes(&mut cur);
        let ntt_manager_mode = bytes::take_u8(&mut cur);
        let token_address = external_address::take_bytes(&mut cur);
        let token_decimals = bytes::take_u8(&mut cur);

        cursor::destroy_empty(cur);

        TransceiverInit {
            transceiver_identifer,
            ntt_manager_address,
            ntt_manager_mode,
            token_address,
            token_decimals,
        }
    }
}
