module wormhole_ntt::non_fungible_ntt_manager {
    use std::vector;
    use sui::tx_context::{Self, TxContext};

    use wormhole_ntt::nft_token;
    use wormhole_ntt::nft::{NFT};
    use wormhole::bytes32::{Self};
    use wormhole::external_address;
    use wormhole_ntt::transceiver_message;
    use wormhole_ntt::ntt_manager_message;
    use wormhole_ntt::state::{Self, State};
    use wormhole::publish_message::MessageTicket;
    use wormhole_ntt::nft_registry::{Self, VerifiedNFT};
    use wormhole_ntt::non_fungible_native_token_transfer;
    use wormhole_ntt::redeem_message::{Self, RedeemMessage};

    const E_INVALID_STATE_MODE: u64 = 1;
    const E_INVALID_PEER: u64 = 2;
    const E_INVALID_TARGET_CHAIN: u64 = 3;
    const E_INVALID_MODE: u64 = 4;
    const E_INVALID_TOKEN_ID_WIDTH: u64 = 5;

    struct TransferTicket<phantom T> {
        /// transfer nft token id list
        transfer_token_ids: vector<u256>,
        /// recipient chain id
        recipient_chain: u16,
        /// recipient address
        recipient: vector<u8>,
        /// message nonce
        nonce: u32,
        /// token id width
        token_id_width: u8
    }

    /// used to generate `TransferTicket`
    public fun prepare_transfer<T>(
        state: &mut State,
        _asset_info: VerifiedNFT<T>,
        transfer_nfts: vector<NFT<T>>,
        recipient_chain: u16,
        recipient: vector<u8>,
        token_id_width: u8,
        nonce: u32
    ): TransferTicket<T> {
        assert!(token_id_width == 1 || token_id_width == 2 || token_id_width == 4 || token_id_width == 8 || token_id_width == 16 || token_id_width == 32, E_INVALID_TOKEN_ID_WIDTH);

        let transfer_token_ids = burn_or_deposit_funds(state, transfer_nfts);

        let ticket = TransferTicket {
            transfer_token_ids,
            recipient_chain,
            recipient,
            token_id_width,
            nonce
        };

        // The remaining amount of funded may have dust depending on the
        // decimals of this asset.
        ticket
    }

    /// use `TransferTicket` to transfer tokens, and then generate wormhole `MessageTicket`
    public fun transfer_tokens<T>(
        state: &mut State,
        ticket: TransferTicket<T>,
        ctx: &TxContext
    ): MessageTicket {
        let TransferTicket {
            transfer_token_ids,
            recipient_chain,
            recipient,
            token_id_width,
            nonce
        } = ticket;

        // Ensure that the recipient is a 32-byte address.
        let recipient = external_address::new(bytes32::from_bytes(recipient));

        let sequence: u64 = state::use_message_sequence(state);

        let nft_token_transfer = non_fungible_native_token_transfer::new(recipient, recipient_chain, transfer_token_ids, vector[]);

        let ntt_manager_message = ntt_manager_message::new(
            bytes32::from_u256_be((sequence as u256)),
            external_address::from_address(tx_context::sender(ctx)),
            non_fungible_native_token_transfer::encode_non_fungible_native_token_transfer(nft_token_transfer, token_id_width)
        );

        let encoded_ntt_manager_payload =
            ntt_manager_message::encode_ntt_manager_message(ntt_manager_message);

        let ntt_manager_address = state::get_state_address(state);
        let recipient_ntt_manager_address = state::get_manager_peer_address(state, recipient_chain);

        // Prepare Wormhole message with encoded `Transfer`.
        let encoded_transceiver_message = transceiver_message::build_and_encode_transceiver_message(
            external_address::new(bytes32::from_bytes(ntt_manager_address)),
            external_address::new(bytes32::from_bytes(recipient_ntt_manager_address)),
            encoded_ntt_manager_payload,
            vector[]
        );

        state::prepare_wormhole_message(
            state,
            nonce,
            encoded_transceiver_message
        )
    }

    /// attestation received to tokens
    public fun attestation_received<T>(
        state: &mut State,
        message: RedeemMessage<T>,
        ctx: &mut TxContext
    ) {
        let (source_chain_id, source_ntt_manager_address, payload) = redeem_message::into_redeem_message(message);

        let peer_address = state::get_manager_peer_address(state, source_chain_id);
        assert!(external_address::new(bytes32::from_bytes(peer_address)) == source_ntt_manager_address, E_INVALID_PEER);

        let (_, _ , ntt_message_payload) =
            ntt_manager_message::into_message(payload);

        let nft_token_transfer = non_fungible_native_token_transfer::parse_non_fungible_native_token_transfer(ntt_message_payload);

        let (to, to_chain, token_ids, _) = non_fungible_native_token_transfer::into_message(nft_token_transfer);

        let recipient_address = external_address::to_address(to);

        let asset_info = state::verified_nft<T>(state);
        assert!(to_chain == nft_registry::token_chain(&asset_info), E_INVALID_TARGET_CHAIN);

        let nfts_number = vector::length(&token_ids);

        if (state::is_mode_locking(state)) {
            let registry = state::borrow_mut_nft_registry(state);
            let nft_token = nft_registry::borrow_mut_native<T>(registry);

            let i = 0;
            while (i < nfts_number) {
                let token_id = vector::pop_back(&mut token_ids);
                let nft = nft_token::withdraw(nft_token, token_id);
                sui::transfer::public_transfer(nft, recipient_address);
                i = i + 1;
            };
        } else if (state::is_mode_burning(state)) {
            let registry = state::borrow_mut_nft_registry(state);
            let nft_token = nft_registry::borrow_mut_native<T>(registry);

            let i = 0;
            while (i < nfts_number) {
                let token_id = vector::pop_back(&mut token_ids);
                let nft = nft_token::mint(nft_token, token_id, ctx);
                sui::transfer::public_transfer(nft, recipient_address);
                i = i + 1;
            };
        } else {
            abort E_INVALID_MODE
        };
    }

    /// burn or depoist tokens
    fun burn_or_deposit_funds<T>(
        state: &mut State,
        transfer_nfts: vector<NFT<T>>
    ): vector<u256> {
        let transfer_token_ids: vector<u256> = vector[];
        let nfts_number = vector::length(&transfer_nfts);

        if (state::is_mode_locking(state)) {
            let registry = state::borrow_mut_nft_registry(state);
            let nft_token = nft_registry::borrow_mut_native<T>(registry);

            let i = 0;
            while (i < nfts_number) {
                let nft = vector::pop_back(&mut transfer_nfts);
                let token_id = nft_token::deposit(nft_token, nft);
                vector::push_back(&mut transfer_token_ids, token_id);
                i = i + 1;
            };
        } else if (state::is_mode_burning(state)) {
            let registry = state::borrow_mut_nft_registry(state);
            let nft_token = nft_registry::borrow_mut_native<T>(registry);

            let i = 0;
            while (i < nfts_number) {
                let nft = vector::pop_back(&mut transfer_nfts);
                let token_id = nft_token::burn(nft_token, nft);
                vector::push_back(&mut transfer_token_ids, token_id);
                i = i + 1;
            };
        } else {
            abort E_INVALID_STATE_MODE
        };

        vector::destroy_empty(transfer_nfts);

        transfer_token_ids
    }
}
