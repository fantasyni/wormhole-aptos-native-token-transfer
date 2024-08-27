module wormhole_ntt::redeem_message {
    use wormhole_ntt::ntt_external_address::NttExternalAddress;
    use wormhole_ntt::ntt_manager_message::NttManagerMessage;

    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::ntt_transceiver;

    struct RedeemMessage<phantom T> {
        emitter_chain: u16,
        source_ntt_manager_address: NttExternalAddress,
        parsed_ntt_manager_message: NttManagerMessage,
    }

    public(friend) fun new<T>(
        emitter_chain: u16,
        source_ntt_manager_address: NttExternalAddress,
        parsed_ntt_manager_message: NttManagerMessage,
    ): RedeemMessage<T> {
        RedeemMessage<T> {
            emitter_chain,
            source_ntt_manager_address,
            parsed_ntt_manager_message
        }
    }

    public(friend) fun into_redeem_message<T>(
        message: RedeemMessage<T>
    ): (u16, NttExternalAddress, NttManagerMessage) {
        let RedeemMessage<T> {
            emitter_chain,
            source_ntt_manager_address,
            parsed_ntt_manager_message
        } = message;

        (emitter_chain, source_ntt_manager_address, parsed_ntt_manager_message)
    }
}
