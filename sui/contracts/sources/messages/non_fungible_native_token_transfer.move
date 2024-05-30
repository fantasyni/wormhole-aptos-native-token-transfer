module wormhole_ntt::non_fungible_native_token_transfer {
    use std::vector::{Self};

    use wormhole_ntt::bytes4;
    use wormhole::bytes::{Self};
    use wormhole::cursor::{Self};
    use wormhole::external_address::{Self, ExternalAddress};

    /// Prefix for all NonFungibleNativeTokenTransfer payloads
    /// This is 0x99'N''F''T'
    const NON_FUNGIBLE_NTT_PREFIX: vector<u8> = x"994E4654";

    const E_TOKEN_ID_TOO_LARGE: u64 = 0;
    const E_INCORRECT_PREFIX: u64 = 1;

    friend wormhole_ntt::non_fungible_ntt_manager;

    struct NonFungibleNativeTokenTransfer {
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes.
        to: ExternalAddress,
        // Chain ID of the target chain.
        to_chain: u16,
        // transfer nft token id list
        token_ids: vector<u256>,
        // transfer payload
        payload: vector<u8>
    }

    public(friend) fun new(
        to: ExternalAddress,
        to_chain: u16,
        token_ids: vector<u256>,
        payload: vector<u8>
    ): NonFungibleNativeTokenTransfer {
        NonFungibleNativeTokenTransfer {
            to,
            to_chain,
            token_ids,
            payload
        }
    }

    public(friend) fun into_message(
        message: NonFungibleNativeTokenTransfer
    ): (ExternalAddress, u16, vector<u256>, vector<u8>) {
        let NonFungibleNativeTokenTransfer {
            to,
            to_chain,
            token_ids,
            payload
        } = message;
        (to, to_chain, token_ids, payload)
    }

    public(friend) fun encode_non_fungible_native_token_transfer(
        message: NonFungibleNativeTokenTransfer,
        token_id_width: u8
    ): vector<u8> {
        let NonFungibleNativeTokenTransfer {
            to,
            to_chain,
            token_ids,
            payload
        } = message;

        let buf = vector::empty<u8>();

        vector::append(&mut buf, NON_FUNGIBLE_NTT_PREFIX);

        vector::append(&mut buf, external_address::to_bytes(to));
        bytes::push_u16_be(&mut buf, to_chain);
        let token_ids_length = (vector::length(&token_ids) as u16);
        bytes::push_u16_be(&mut buf, token_ids_length);
        bytes::push_u8(&mut buf, token_id_width);

        let i = 0;
        while (i < token_ids_length) {
            let token_id = *vector::borrow(&token_ids, (i as u64));
            if (token_id_width == 1) {
                assert!(token_id <= ((1 << 8) - 1), E_TOKEN_ID_TOO_LARGE);
                bytes::push_u8(&mut buf, (token_id as u8));
            } else if (token_ids_length == 2) {
                assert!(token_id <= ((1 << 16) - 1), E_TOKEN_ID_TOO_LARGE);
                bytes::push_u16_be(&mut buf, (token_id as u16));
            } else if (token_id_width == 4) {
                assert!(token_id <= ((1 << 32) - 1), E_TOKEN_ID_TOO_LARGE);
                bytes::push_u32_be(&mut buf, (token_id as u32));
            } else if (token_id_width == 8) {
                assert!(token_id <= ((1 << 64) - 1), E_TOKEN_ID_TOO_LARGE);
                bytes::push_u64_be(&mut buf, (token_id as u64));
            } else if (token_id_width == 16) {
                assert!(token_id <= ((1 << 128) - 1), E_TOKEN_ID_TOO_LARGE);
                bytes::push_u128_be(&mut buf, (token_id as u128));
            } else {
                bytes::push_u256_be(&mut buf, token_id);
            };
            i = i + 1;
        };

        let payload_length = (vector::length(&payload) as u16);
        bytes::push_u16_be(&mut buf, payload_length);
        vector::append(&mut buf, payload);

        buf
    }

    public(friend) fun parse_non_fungible_native_token_transfer(
        buf: vector<u8>
    ): NonFungibleNativeTokenTransfer {
        let cur = cursor::new(buf);

        let ntt_prefix = bytes4::take(&mut cur);
        let ntt_prefix_bytes = bytes4::to_bytes(ntt_prefix);
        assert!(ntt_prefix_bytes == NON_FUNGIBLE_NTT_PREFIX, E_INCORRECT_PREFIX);

        let to = external_address::take_bytes(&mut cur);
        let to_chain = bytes::take_u16_be(&mut cur);

        let token_ids_length = bytes::take_u16_be(&mut cur);
        let token_id_width = bytes::take_u8(&mut cur);
        let token_ids: vector<u256> = vector[];

        let i: u16 = 0;

        while (i < token_ids_length) {
            if (token_id_width == 1) {
                let token_id = bytes::take_u8(&mut cur);
                vector::push_back(&mut token_ids, (token_id as u256));
            } else if (token_id_width == 2) {
                let token_id = bytes::take_u16_be(&mut cur);
                vector::push_back(&mut token_ids, (token_id as u256));
            } else if (token_id_width == 4) {
                let token_id = bytes::take_u32_be(&mut cur);
                vector::push_back(&mut token_ids, (token_id as u256));
            } else if (token_id_width == 8) {
                let token_id = bytes::take_u64_be(&mut cur);
                vector::push_back(&mut token_ids, (token_id as u256));
            } else if (token_id_width == 16) {
                let token_id = bytes::take_u128_be(&mut cur);
                vector::push_back(&mut token_ids, (token_id as u256));
            } else {
                let token_id = bytes::take_u256_be(&mut cur);
                vector::push_back(&mut token_ids, token_id);
            };
            i = i + 1;
        };

        let payload_length = bytes::take_u16_be(&mut cur);
        let payload = bytes::take_bytes(&mut cur, (payload_length as u64));

        cursor::destroy_empty(cur);

        NonFungibleNativeTokenTransfer {
            to,
            to_chain,
            token_ids,
            payload
        }
    }

    #[test_only]
    public fun new_test_only(
        to: ExternalAddress,
        to_chain: u16,
        token_ids: vector<u256>,
        payload: vector<u8>
    ): NonFungibleNativeTokenTransfer {
        new(to, to_chain, token_ids, payload)
    }

    #[test_only]
    public fun into_message_test_only(
        message: NonFungibleNativeTokenTransfer
    ): (ExternalAddress, u16, vector<u256>, vector<u8>) {
        into_message(message)
    }

    #[test_only]
    public fun encode_non_fungible_native_token_transfer_test_only(
        message: NonFungibleNativeTokenTransfer,
        token_id_width: u8
    ): vector<u8> {
        encode_non_fungible_native_token_transfer(message, token_id_width)
    }

    #[test_only]
    public fun parse_non_fungible_native_token_transfer_test_only(
        buf: vector<u8>
    ): NonFungibleNativeTokenTransfer {
        parse_non_fungible_native_token_transfer(buf)
    }
}
