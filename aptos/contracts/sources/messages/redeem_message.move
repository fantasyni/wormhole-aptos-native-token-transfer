module wormhole_ntt::redeem_message {
    use wormhole_ntt::ntt_external_address::NttExternalAddress;
    use wormhole_ntt::ntt_manager_message::NttManagerMessage;

    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::ntt_transceiver;

    struct RedeemMessage {
        emitter_chain: u16,
        source_ntt_manager_address: NttExternalAddress,
        parsed_ntt_manager_message: NttManagerMessage,
    }

    public(friend) fun new(
        emitter_chain: u16,
        source_ntt_manager_address: NttExternalAddress,
        parsed_ntt_manager_message: NttManagerMessage,
    ): RedeemMessage {
        RedeemMessage {
            emitter_chain,
            source_ntt_manager_address,
            parsed_ntt_manager_message
        }
    }

    public(friend) fun into_redeem_message(
        message: RedeemMessage
    ): (u16, NttExternalAddress, NttManagerMessage) {
        let RedeemMessage {
            emitter_chain,
            source_ntt_manager_address,
            parsed_ntt_manager_message
        } = message;

        (emitter_chain, source_ntt_manager_address, parsed_ntt_manager_message)
    }
}
