module wormhole_ntt::ntt_transceiver {
    use wormhole_ntt::bytes32;
    use wormhole_ntt::ntt_manager;
    use wormhole::u16::{Self as U16};
    use wormhole_ntt::ntt_vaa::{Self};
    use wormhole_ntt::ntt_state::{Self};
    use wormhole_ntt::redeem_message::{Self};
    use wormhole::vaa::{Self as wormhole_vaa};
    use wormhole_ntt::transceiver_message::{Self};
    use wormhole_ntt::ntt_external_address::{Self, NttExternalAddress};

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
        emitter_address: NttExternalAddress,
        sequence: u64
    }

    public entry fun submit_vaa(
        object_address: address,
        token_address: address,
        vaa: vector<u8>
    ) {
        let vaa = ntt_vaa::parse_verify_and_replay_protect(object_address, vaa);
        let emitter_chain = wormhole_vaa::get_emitter_chain(&vaa);
        let emitter_address = wormhole_vaa::get_emitter_address(&vaa);
        let payload = wormhole_vaa::destroy(vaa);

        let emitter_chain_u16: u16 = ((U16::to_u64(emitter_chain)) as u16);

        let transceiver_peer_address = ntt_state::get_transceiver_peer_address(object_address, emitter_chain_u16);
        let transceiver_peer_address_wormhole = ntt_external_address::to_wormhole_external_address(transceiver_peer_address);
        assert!(transceiver_peer_address_wormhole == emitter_address, E_INVALID_TRANSCEIVER_PEER);

        let (source_ntt_manager_address, recipient_ntt_manager_address, parsed_ntt_manager_message)
            = transceiver_message::parse_transceiver_and_ntt_manager_message(payload);

        let ntt_manager_address = ntt_state::package_address(object_address);

        assert!(recipient_ntt_manager_address == ntt_external_address::new(
            bytes32::from_address(ntt_manager_address)), E_UNEXPECTED_RECIPIENT_NTT_MANAGER_ADDRESS);

        let message = redeem_message::new(emitter_chain_u16, source_ntt_manager_address, parsed_ntt_manager_message);

        ntt_manager::attestation_received(object_address, token_address, message);
    }

    public entry fun submit_vaa_entry(
        object_address: address,
        token_address: address,
        vaa: vector<u8>
    ) {
        submit_vaa(object_address, token_address, vaa);
    }
}