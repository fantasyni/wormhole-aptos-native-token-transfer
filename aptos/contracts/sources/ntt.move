module wormhole_ntt::ntt {
    use std::signer;
    use wormhole::wormhole;
    use wormhole::emitter;
    use std::event::{emit};
    use aptos_framework::object;
    use wormhole_ntt::ntt_state;
    use wormhole_ntt::bytes32::{Self};
    use wormhole::external_address::{ExternalAddress};
    use wormhole_ntt::ntt_external_address::{Self, NttExternalAddress};

    const EUNAUTHORIZED: u64 = 1;
    const E_TOKEN_MINTED: u64 = 2;

    struct AdminCap has key {
        admin: address,
        mintInitToken: bool
    }

    #[event]
    struct CreateNttEvent has drop, store {
        ntt_address: NttExternalAddress,
        emitter_address: ExternalAddress
    }

    // fun init_module(sender: &signer) {
    //     let constructor_ref = &object::create_named_object(sender, ntt_state::get_package_symbol());
    //     let metadata_object_signer = &object::generate_signer(constructor_ref);
    //
    //     move_to(metadata_object_signer, AdminCap {
    //         admin: @admin_addr
    //     });
    //
    //     let emitter_cap = wormhole::register_emitter();
    //     let extend_ref = object::generate_extend_ref(constructor_ref);
    //     ntt_state::init_wormhole_ntt_state(metadata_object_signer, emitter_cap, extend_ref);
    // }

    public entry fun create_ntt(
        sender: &signer,
        mode: u8
    ) {
        let sender_address = signer::address_of(sender);

        let constructor_ref = &object::create_object(sender_address);
        let ntt_address = object::address_from_constructor_ref(constructor_ref);

        let object_signer = &object::generate_signer(constructor_ref);

        move_to(object_signer, AdminCap {
            admin: sender_address,
            mintInitToken: false
        });

        let emitter_cap = wormhole::register_emitter();

        emit(CreateNttEvent {
            ntt_address: ntt_external_address::from_address(ntt_address),
            emitter_address: emitter::get_external_address(&emitter_cap)
        });

        let extend_ref = object::generate_extend_ref(constructor_ref);
        ntt_state::init_wormhole_ntt_state(object_signer, emitter_cap, extend_ref, mode);
    }

    public entry fun set_mode(
        object_address: address,
        sender: &signer,
        mode: u8
    ) acquires AdminCap {
        let admin = borrow_global<AdminCap>(object_address);
        assert_is_admin(admin, sender);

        ntt_state::set_mode(object_address, mode);
    }

    /// add new native token to `WormholeNTT`
    public entry fun add_new_native_token(
        sender: &signer,
        object_address: address,
        name: vector<u8>,
        symbol: vector<u8>,
        decimals: u8
    ) acquires AdminCap {
        let admin = borrow_global<AdminCap>(object_address);
        assert_is_admin(admin, sender);

        ntt_state::add_new_native_token(object_address, sender, name, symbol, decimals);
    }

    public entry fun mint_init_token(
        sender: &signer,
        object_address: address,
        token_address: address,
        amount: u64
    ) acquires AdminCap {
        let admin = borrow_global_mut<AdminCap>(object_address);
        assert_is_admin(admin, sender);

        assert!(!admin.mintInitToken, E_TOKEN_MINTED);

        admin.mintInitToken = true;

        ntt_state::mint_native_token(token_address, signer::address_of(sender), amount);
    }

    public entry fun add_new_token(
        sender: &signer,
        object_address: address,
        token_address: address,
    ) acquires AdminCap {
        let admin = borrow_global<AdminCap>(object_address);
        assert_is_admin(admin, sender);

        ntt_state::set_native_asset_type_info(object_address, token_address);
    }

    /// set ntt manager peer contract address to the target chain
    public entry fun set_manager_peer(
        sender: &signer,
        object_address: address,
        peer_chain_id: u16,
        peer_contract: vector<u8>,
        decimals: u8
    ) acquires AdminCap {
        let admin = borrow_global<AdminCap>(object_address);
        assert_is_admin(admin, sender);

        ntt_state::set_manager_peer(object_address, peer_chain_id, peer_contract, decimals);
    }

    /// set ntt transceiver peer contract address to the target chain
    public entry fun set_transceiver_peer(
        sender: &signer,
        object_address: address,
        peer_chain_id: u16,
        peer_contract: vector<u8>
    ) acquires AdminCap {
        let admin = borrow_global<AdminCap>(object_address);
        assert_is_admin(admin, sender);
        let peer_contract_address = ntt_external_address::new(bytes32::from_bytes(peer_contract));
        ntt_state::set_transceiver_peer(object_address, peer_chain_id, peer_contract_address);
    }

    public entry fun set_peer(
        sender: &signer,
        object_address: address,
        peer_chain_id: u16,
        manager_peer_contract: vector<u8>,
        decimals: u8,
        tranceiver_peer_contract: vector<u8>
    ) acquires AdminCap {
        let admin = borrow_global<AdminCap>(object_address);
        assert_is_admin(admin, sender);

        ntt_state::set_manager_peer(object_address, peer_chain_id, manager_peer_contract, decimals);

        let peer_contract_address = ntt_external_address::new(bytes32::from_bytes(tranceiver_peer_contract));
        ntt_state::set_transceiver_peer(object_address, peer_chain_id, peer_contract_address);
    }

    fun assert_is_admin(admin: &AdminCap, minter: &signer) {
        let minter_addr = signer::address_of(minter);
        assert!(minter_addr == admin.admin, EUNAUTHORIZED)
    }
}
