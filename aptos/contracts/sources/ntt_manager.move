module wormhole_ntt::ntt_manager {
    use std::signer;
    use aptos_framework::aptos_account;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::aptos_coin::AptosCoin;

    use wormhole_ntt::bytes32::{Self};
    use wormhole_ntt::ntt_state::{Self};
    use wormhole_ntt::transceiver_message;
    use wormhole_ntt::ntt_manager_message::{Self};
    use wormhole_ntt::native_token_transfer::{Self};
    use wormhole_ntt::trimmed_amount::{Self, TrimmedAmount};
    use wormhole_ntt::redeem_message::{Self, RedeemMessage};
    use wormhole_ntt::ntt_external_address::{Self, NttExternalAddress};

    const E_INVALID_STATE_MODE: u64 = 1;
    const E_INVALID_PEER: u64 = 2;
    const E_INVALID_TARGET_CHAIN: u64 = 3;
    const E_INVALID_MODE: u64 = 4;
    const E_INVALID_PEER_DECIMALS: u64 = 5;
    const E_NATIVE_ASSET_REGISTERED_INVALID: u64 = 6;

    /// used to generate `TransferTicket`
    public entry fun transfer_tokens<CoinType>(sender: &signer, amount: u64, recipient_chain: u16, recipient: vector<u8>, nonce: u64)  {
        assert!(ntt_state::is_registered_native_asset<CoinType>(), E_NATIVE_ASSET_REGISTERED_INVALID);

        let sender_address = signer::address_of(sender);

        let transfer_coins = coin::withdraw<CoinType>(sender, amount);
        let wormhole_fee = wormhole::state::get_message_fee();
        let wormhole_fee_coins = coin::withdraw<AptosCoin>(sender, wormhole_fee);

        let (trimmed_coins, trimmed_amount)
            = trim_transfer_amount<CoinType>(&mut transfer_coins, recipient_chain);

        let trimmed_value: u64 = trimmed_amount::value(&trimmed_amount);
        if (amount > trimmed_value && coin::value(&transfer_coins) > 0) {
            coin::deposit<CoinType>(sender_address, transfer_coins);
        } else {
            coin::destroy_zero<CoinType>(transfer_coins);
        };

        // Handle funds and get canonical token info for encoded transfer.
        let token_address = burn_or_deposit_funds(trimmed_coins);

        // Ensure that the recipient is a 32-byte address.
        let recipient = ntt_external_address::new(bytes32::from_bytes(recipient));

        let sequence: u64 = ntt_state::use_message_sequence();

        let native_token_transfer = native_token_transfer::new(
            trimmed_amount,
            token_address,
            recipient,
            recipient_chain
        );

        let ntt_manager_message = ntt_manager_message::new(
            bytes32::from_u256_be((sequence as u256)),
            ntt_external_address::from_address(sender_address),
            native_token_transfer::encode_native_token_transfer(native_token_transfer)
        );

        let encoded_ntt_manager_payload =
            ntt_manager_message::encode_ntt_manager_message(ntt_manager_message);

        let ntt_manager_address = ntt_state::package_address();
        let recipient_ntt_manager_address = ntt_state::get_manager_peer_address(recipient_chain);

        // Prepare Wormhole message with encoded `Transfer`.
        let encoded_transceiver_message = transceiver_message::build_and_encode_transceiver_message(
            ntt_external_address::new(bytes32::from_address(ntt_manager_address)),
            ntt_external_address::new(bytes32::from_bytes(recipient_ntt_manager_address)),
            encoded_ntt_manager_payload,
            vector[]
        );

        ntt_state::publish_message(
            nonce,
            encoded_transceiver_message,
            wormhole_fee_coins
        );
    }

    /// attestation received to tokens
    public fun attestation_received<CoinType>(message: RedeemMessage<CoinType>) {
        assert!(ntt_state::is_registered_native_asset<CoinType>(), E_NATIVE_ASSET_REGISTERED_INVALID);

        let (source_chain_id, source_ntt_manager_address, payload) = redeem_message::into_redeem_message(message);

        let peer_address = ntt_state::get_manager_peer_address(source_chain_id);
        assert!(ntt_external_address::new(bytes32::from_bytes(peer_address)) == source_ntt_manager_address, E_INVALID_PEER);

        let (_, _ , ntt_message_payload) =
            ntt_manager_message::into_message(payload);

        let native_token_transfer =
            native_token_transfer::parse_native_token_transfer(ntt_message_payload);

        let (native_transfer_amount, _, transfer_recipient, to_chain)
            = native_token_transfer::into_message(native_token_transfer);

        let recipient_address = ntt_external_address::to_address(transfer_recipient);

        assert!(to_chain == ntt_state::chain_id(), E_INVALID_TARGET_CHAIN);

        let token_decimals = coin::decimals<CoinType>();
        let native_transfer_amount = trimmed_amount::untrim(&native_transfer_amount, token_decimals);

        if (ntt_state::is_mode_locking()) {
            let wormhole_ntt = ntt_state::wormhole_ntt_signer();
            let withdraw_coin = coin::withdraw<CoinType>(&wormhole_ntt, native_transfer_amount);
            aptos_account::deposit_coins(recipient_address, withdraw_coin);
        } else if (ntt_state::is_mode_burning()) {
            let coins = ntt_state::mint_native_token<CoinType>(native_transfer_amount);
            aptos_account::deposit_coins(recipient_address, coins);
        } else {
            abort E_INVALID_MODE
        };
    }

    /// burn or depoist tokens
    fun burn_or_deposit_funds<CoinType>(transfer_balance: Coin<CoinType>): NttExternalAddress {
        ntt_state::check_account_registered<CoinType>();

        if (ntt_state::is_mode_locking()) {
            coin::deposit<CoinType>(ntt_state::package_address(), transfer_balance);
        }
        else if (ntt_state::is_mode_burning()) {
            ntt_state::burn_native_token<CoinType>(transfer_balance);
        }
        else {
            abort E_INVALID_STATE_MODE
        };

        ntt_external_address::from_address(ntt_state::token_address<CoinType>())
    }

    /// trim transfer amount
    fun trim_transfer_amount<CoinType>(funded: &mut Coin<CoinType>, recipient_chain: u16): (Coin<CoinType>, TrimmedAmount) {
        let to_decimals = ntt_state::get_manager_peer_decimals(recipient_chain);
        assert!(to_decimals > 0, E_INVALID_PEER_DECIMALS);

        let from_decimals = coin::decimals<CoinType>();
        let amount = coin::value(funded);
        let trimmed_amount = trimmed_amount::trim(amount, from_decimals, to_decimals);
        let new_amount = trimmed_amount::untrim(&trimmed_amount, from_decimals);

        let truncated = coin::extract(funded, new_amount);

        (truncated, trimmed_amount)
    }
}
