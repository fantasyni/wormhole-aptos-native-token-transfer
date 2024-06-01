module wormhole_ntt::ntt_transceiver {
    use wormhole::bytes32;
    use wormhole::vaa::{Self, VAA};
    use wormhole_ntt::state::{Self, State};
    use wormhole_ntt::transceiver_message::{Self};
    use wormhole::external_address::{Self, ExternalAddress};
    use wormhole_ntt::redeem_message::{Self, RedeemMessage};

    const E_UNEXPECTED_RECIPIENT_NTT_MANAGER_ADDRESS: u64 = 0;
    const E_INVALID_TRANSCEIVER_PEER: u64 = 1;

    struct NttTransceiverMessage {
        /// Wormhole chain ID from which network the message originated from.
        emitter_chain: u16,
        /// Sequence number of WormholeNtt's Wormhole message.
        sequence: u64,
        /// ntt transceiver message payload.
        payload: vector<u8>
    }

    /// Emitted when a transfer has been redeemed
    struct TransferRedeemed has drop, copy {
        emitter_chain: u16,
        emitter_address: ExternalAddress,
        sequence: u64
    }

    /// verify VAA message and then generate `NttTransceiverMessage`
    public fun verify_only_once(
        state: &mut State,
        verified_vaa: VAA
    ): NttTransceiverMessage {
        // This capability ensures that the current build version is used.
        // First parse and verify VAA using Wormhole. This also consumes the VAA
        // hash to prevent replay.
        vaa::consume(
            state::borrow_mut_consumed_vaas(state),
            &verified_vaa
        );

        // Take emitter info, sequence and payload.
        let sequence = vaa::sequence(&verified_vaa);
        let (
            emitter_chain,
            emitter_address,
            payload
        ) = vaa::take_emitter_info_and_payload(verified_vaa);

        let transceiver_peer_address = state::get_transceiver_peer_address(state, emitter_chain);
        assert!(transceiver_peer_address == emitter_address, E_INVALID_TRANSCEIVER_PEER);

        sui::event::emit(TransferRedeemed {
            emitter_chain,
            emitter_address,
            sequence
        });

        NttTransceiverMessage {
            emitter_chain,
            sequence,
            payload
        }
    }

    /// redeem NttTransceiverMessage
    public fun redeem<T>(
        state: &mut State,
        message: NttTransceiverMessage,
    ) : RedeemMessage<T> {
        let NttTransceiverMessage {
            emitter_chain,
            sequence: _,
            payload
        } = message;

        let (source_ntt_manager_address, recipient_ntt_manager_address, parsed_ntt_manager_message)
            = transceiver_message::parse_transceiver_and_ntt_manager_message(payload);

        let ntt_manager_address = state::get_state_address(state);

        assert!(recipient_ntt_manager_address == external_address::new(
            bytes32::from_bytes(ntt_manager_address)), E_UNEXPECTED_RECIPIENT_NTT_MANAGER_ADDRESS);

        redeem_message::new<T>(emitter_chain, source_ntt_manager_address, parsed_ntt_manager_message)
    }
}
