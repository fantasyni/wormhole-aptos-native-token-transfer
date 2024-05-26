module wormhole_ntt::native_token_transfer {
    use std::vector::{Self};

    use wormhole::bytes::{Self};
    use wormhole::cursor::{Self};
    use wormhole_ntt::bytes4::{Self};
    use wormhole_ntt::trimmed_amount::{Self, TrimmedAmount};
    use wormhole::external_address::{Self, ExternalAddress};

    /// Prefix for all NativeTokenTransfer payloads
    ///      This is 0x99'N''T''T'
    const NTT_PREFIX: vector<u8> = x"994E5454";

    const E_INCORRECT_PREFIX: u64 = 0;

    friend wormhole_ntt::ntt_manager;

    struct NativeTokenTransfer {
        // Amount being transferred.
        amount: TrimmedAmount,
        // Address of the token. Left-zero-padded if shorter than 32 bytes.
        source_token: ExternalAddress,
        // Address of the recipient. Left-zero-padded if shorter than 32 bytes.
        to: ExternalAddress,
        // Chain ID of the target chain.
        to_chain: u16,
    }

    public(friend) fun new(
        amount: TrimmedAmount,
        source_token: ExternalAddress,
        to: ExternalAddress,
        to_chain: u16
    ): NativeTokenTransfer {
        NativeTokenTransfer {
            amount,
            source_token,
            to,
            to_chain
        }
    }

    public(friend) fun into_message(
        message: NativeTokenTransfer
    ): (
        TrimmedAmount,
        ExternalAddress,
        ExternalAddress,
        u16,
    ) {
        let NativeTokenTransfer {
            amount,
            source_token,
            to,
            to_chain
        } = message;
        (amount, source_token, to, to_chain)
    }

    public(friend) fun encode_native_token_transfer(
        message: NativeTokenTransfer
    ): vector<u8> {
        let NativeTokenTransfer {
            amount,
            source_token,
            to,
            to_chain
        } = message;

        let buf = vector::empty<u8>();

        vector::append(&mut buf, NTT_PREFIX);
        bytes::push_u8(&mut buf, trimmed_amount::decimals(&amount));
        bytes::push_u64_be(&mut buf, trimmed_amount::value(&amount));
        vector::append(&mut buf, external_address::to_bytes(source_token));
        vector::append(&mut buf, external_address::to_bytes(to));
        bytes::push_u16_be(&mut buf, to_chain);

        buf
    }

    public(friend) fun parse_native_token_transfer(
        buf: vector<u8>
    ): NativeTokenTransfer {
        let cur = cursor::new(buf);

        let ntt_prefix = bytes4::take(&mut cur);
        let ntt_prefix_bytes = bytes4::to_bytes(ntt_prefix);
        assert!(ntt_prefix_bytes == NTT_PREFIX, E_INCORRECT_PREFIX);
        let decimals = bytes::take_u8(&mut cur);
        let amount = bytes::take_u64_be(&mut cur);
        let amount = trimmed_amount::new(amount, decimals);
        let source_token = external_address::take_bytes(&mut cur);
        let to = external_address::take_bytes(&mut cur);
        let to_chain = bytes::take_u16_be(&mut cur);

        cursor::destroy_empty(cur);

        NativeTokenTransfer {
            amount,
            source_token,
            to,
            to_chain
        }
    }

    #[test_only]
    public fun new_test_only(
        amount: TrimmedAmount,
        source_token: ExternalAddress,
        to: ExternalAddress,
        to_chain: u16
    ): NativeTokenTransfer {
        new(amount, source_token, to, to_chain)
    }

    #[test_only]
    public fun into_message_test_only(
        message: NativeTokenTransfer
    ): (
        TrimmedAmount,
        ExternalAddress,
        ExternalAddress,
        u16,
    ) {
        into_message(message)
    }

    #[test_only]
    public fun encode_native_token_transfer_test_only(
        message: NativeTokenTransfer
    ): vector<u8> {
        encode_native_token_transfer(message)
    }

    #[test_only]
    public fun parse_native_token_transfer_test_only(
        buf: vector<u8>
    ): NativeTokenTransfer {
        parse_native_token_transfer(buf)
    }
}
