module wormhole_ntt::ntt {
    use std::signer;
    use wormhole::wormhole;
    use aptos_framework::object;
    use wormhole_ntt::ntt_state;
    use wormhole_ntt::bytes32::{Self};
    use wormhole_ntt::ntt_external_address;

    const EUNAUTHORIZED: u64 = 1;

    struct AdminCap has key {
        admin: address
    }

    fun init_module(sender: &signer) {
        let constructor_ref = &object::create_named_object(sender, ntt_state::get_package_symbol());
        let metadata_object_signer = &object::generate_signer(constructor_ref);

        move_to(metadata_object_signer, AdminCap {
            admin: @admin_addr
        });

        let emitter_cap = wormhole::register_emitter();
        let extend_ref = object::generate_extend_ref(constructor_ref);
        ntt_state::init_wormhole_ntt_state(metadata_object_signer, emitter_cap, extend_ref);
    }

    public entry fun set_mode(sender: &signer, mode: u8) acquires AdminCap {
        assert_is_admin(sender);

        ntt_state::set_mode(mode);
    }

    /// add new native token to `WormholeNTT`
    public entry fun add_new_native_token<CoinType>(sender: &signer, name: vector<u8>, symbol: vector<u8>, decimals: u8, monitor_supply: bool) acquires AdminCap {
        assert_is_admin(sender);

        ntt_state::add_new_native_token<CoinType>(sender, name, symbol, decimals, monitor_supply);
    }

    public entry fun add_new_token<CoinType>(sender: &signer) acquires AdminCap {
        assert_is_admin(sender);

        ntt_state::set_native_asset_type_info<CoinType>();
    }

    /// set ntt manager peer contract address to the target chain
    public entry fun set_manager_peer(sender: &signer, peer_chain_id: u16, peer_contract: vector<u8>, decimals: u8) acquires AdminCap {
        assert_is_admin(sender);

        ntt_state::set_manager_peer(peer_chain_id, peer_contract, decimals);
    }

    /// set ntt transceiver peer contract address to the target chain
    public entry fun set_transceiver_peer(sender: &signer, peer_chain_id: u16, peer_contract: vector<u8>) acquires AdminCap {
        assert_is_admin(sender);
        let peer_contract_address = ntt_external_address::new(bytes32::from_bytes(peer_contract));
        ntt_state::set_transceiver_peer(peer_chain_id, peer_contract_address);
    }

    fun assert_is_admin(minter: &signer) acquires AdminCap {
        let adminCap = borrow_global<AdminCap>(ntt_state::package_address());
        let minter_addr = signer::address_of(minter);
        assert!(minter_addr == adminCap.admin, EUNAUTHORIZED);
    }
}
