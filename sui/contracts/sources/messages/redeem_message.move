module wormhole_ntt::redeem_message {
    use wormhole::external_address::ExternalAddress;
    use wormhole_ntt::ntt_manager_message::NttManagerMessage;

    friend wormhole_ntt::ntt_manager;
    friend wormhole_ntt::ntt_transceiver;
    friend wormhole_ntt::non_fungible_ntt_manager;

    struct RedeemMessage<phantom T> {
        emitter_chain: u16,
        source_ntt_manager_address: ExternalAddress,
        parsed_ntt_manager_message: NttManagerMessage,
    }

    public(friend) fun new<T>(
        emitter_chain: u16,
        source_ntt_manager_address: ExternalAddress,
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
    ): (u16, ExternalAddress, NttManagerMessage) {
        let RedeemMessage<T> {
            emitter_chain,
            source_ntt_manager_address,
            parsed_ntt_manager_message
        } = message;

        (emitter_chain, source_ntt_manager_address, parsed_ntt_manager_message)
    }
}
