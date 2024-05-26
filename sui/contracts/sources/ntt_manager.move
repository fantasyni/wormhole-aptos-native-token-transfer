module wormhole_ntt::ntt_manager {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::tx_context::{Self, TxContext};
    use wormhole::external_address;
    use wormhole::external_address::ExternalAddress;

    use wormhole::bytes32::{Self};
    use wormhole_ntt::state::{Self, State};
    use wormhole_ntt::transceiver_message;
    use wormhole_ntt::native_token::{Self};
    use wormhole_ntt::token_registry::{Self};
    use wormhole::publish_message::MessageTicket;
    use wormhole_ntt::native_token_transfer::{Self};
    use wormhole_ntt::token_registry::VerifiedAsset;
    use wormhole_ntt::trimmed_amount::{Self, TrimmedAmount};
    use wormhole_ntt::ntt_manager_message::{Self, NttManagerMessage};

    const E_INVALID_STATE_MODE: u64 = 1;
    const E_INVALID_PEER: u64 = 2;
    const E_INVALID_TARGET_CHAIN: u64 = 3;
    const E_INVALID_MODE: u64 = 4;
    const E_INVALID_PEER_DECIMALS: u64 = 5;

    friend wormhole_ntt::ntt_transceiver;

    struct TransferTicket<phantom CoinType> {
        /// verified asset info
        asset_info: VerifiedAsset<CoinType>,
        /// transfer balance after trim
        transfer_balance: Balance<CoinType>,
        /// trimmed amount to deal with diffent decimals
        trimmed_amount: TrimmedAmount,
        /// recipient chain id
        recipient_chain: u16,
        /// recipient address
        recipient: vector<u8>,
        /// message nonce
        nonce: u32,
    }

    /// used to generate `TransferTicket`
    public fun prepare_transfer<CoinType>(
        state: &mut State,
        asset_info: VerifiedAsset<CoinType>,
        transfer_coin: Coin<CoinType>,
        recipient_chain: u16,
        recipient: vector<u8>,
        nonce: u32
    ): (
        TransferTicket<CoinType>,
        Coin<CoinType>
    ) {
        let (transfer_balance, trimmed_amount)
            = trim_transfer_amount<CoinType>(state, &asset_info, &mut transfer_coin, recipient_chain);

        let ticket = TransferTicket {
            asset_info,
            transfer_balance,
            trimmed_amount,
            recipient_chain,
            recipient,
            nonce
        };

        // The remaining amount of funded may have dust depending on the
        // decimals of this asset.
        (ticket, transfer_coin)
    }

    /// use `TransferTicket` to transfer tokens, and then generate wormhole `MessageTicket`
    public fun transfer_tokens<CoinType>(
        state: &mut State,
        ticket: TransferTicket<CoinType>,
        ctx: &TxContext
    ): MessageTicket {
        let TransferTicket {
            asset_info,
            transfer_balance,
            trimmed_amount,
            recipient_chain,
            recipient,
            nonce
        } = ticket;

        // Handle funds and get canonical token info for encoded transfer.
        let token_address = burn_or_deposit_funds(state, &asset_info, transfer_balance);

        // Ensure that the recipient is a 32-byte address.
        let recipient = external_address::new(bytes32::from_bytes(recipient));

        let sequence: u64 = state::use_message_sequence(state);

        let native_token_transfer =
            native_token_transfer::new(
                trimmed_amount,
                token_address,
                recipient,
                recipient_chain
            );

        let ntt_manager_message = ntt_manager_message::new(
            bytes32::from_u256_be((sequence as u256)),
            external_address::from_address(tx_context::sender(ctx)),
            native_token_transfer::encode_native_token_transfer(native_token_transfer)
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

    /// called from transceiver after attestation received to tokens
    public(friend) fun attestation_received<CoinType>(
        state: &mut State,
        source_chain_id: u16,
        source_ntt_manager_address: ExternalAddress,
        payload: NttManagerMessage,
        ctx: &mut TxContext
    ) {
        let peer_address = state::get_manager_peer_address(state, source_chain_id);
        assert!(external_address::new(bytes32::from_bytes(peer_address)) == source_ntt_manager_address, E_INVALID_PEER);

        let (_, _ , ntt_message_payload) =
            ntt_manager_message::into_message(payload);

        let native_token_transfer =
            native_token_transfer::parse_native_token_transfer(ntt_message_payload);

        let (native_transfer_amount, _, transfer_recipient, to_chain)
            = native_token_transfer::into_message(native_token_transfer);

        let recipient_address = external_address::to_address(transfer_recipient);

        let asset_info = state::verified_asset<CoinType>(state);
        assert!(to_chain == token_registry::token_chain(&asset_info), E_INVALID_TARGET_CHAIN);

        let token_decimals = token_registry::coin_decimals(&asset_info);
        let native_transfer_amount = trimmed_amount::untrim(&native_transfer_amount, token_decimals);

        if (state::is_mode_locking(state)) {
            let registry = state::borrow_mut_token_registry(state);
            let native_token = token_registry::borrow_mut_native<CoinType>(registry);

            let withdraw_balance = native_token::withdraw(native_token, native_transfer_amount);
            sui::transfer::public_transfer(
                coin::from_balance(withdraw_balance, ctx),
                recipient_address
            );
        } else if (state::is_mode_burning(state)) {
            let registry = state::borrow_mut_token_registry(state);
            let native_token = token_registry::borrow_mut_native<CoinType>(registry);

            let mint_balance = native_token::mint(native_token, native_transfer_amount);
            sui::transfer::public_transfer(
                coin::from_balance(mint_balance, ctx),
                recipient_address
            );
        } else {
            abort E_INVALID_MODE
        };
    }

    /// burn or depoist tokens
    fun burn_or_deposit_funds<CoinType>(
        state: &mut State,
        asset_info: &VerifiedAsset<CoinType>,
        transfer_balance: Balance<CoinType>
    ): ExternalAddress {
        if (state::is_mode_locking(state)) {
            let registry = state::borrow_mut_token_registry(state);
            let native_token = token_registry::borrow_mut_native<CoinType>(registry);

            native_token::deposit(native_token, transfer_balance);
        } else if (state::is_mode_burning(state)) {
            let registry = state::borrow_mut_token_registry(state);
            let native_token = token_registry::borrow_mut_native<CoinType>(registry);

            native_token::burn(native_token, transfer_balance);
        } else {
            abort E_INVALID_STATE_MODE
        };

        token_registry::token_address(asset_info)
    }

    /// trim transfer amount
    fun trim_transfer_amount<CoinType>(
        state: &State,
        asset_info: &VerifiedAsset<CoinType>,
        funded: &mut Coin<CoinType>,
        recipient_chain: u16,
    ): (Balance<CoinType>, TrimmedAmount) {
        let to_decimals = state::get_manager_peer_decimals(state, recipient_chain);
        assert!(to_decimals > 0, E_INVALID_PEER_DECIMALS);

        let from_decimals = token_registry::coin_decimals(asset_info);
        let amount = coin::value(funded);
        let trimmed_amount = trimmed_amount::trim(amount, from_decimals, to_decimals);
        let new_amount = trimmed_amount::untrim(&trimmed_amount, from_decimals);

        let truncated =
            balance::split(
                coin::balance_mut(funded),
                new_amount
            );

        (truncated, trimmed_amount)
    }
}
