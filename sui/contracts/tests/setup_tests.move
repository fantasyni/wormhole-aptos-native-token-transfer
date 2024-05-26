#[test_only]
module wormhole_ntt::setup_tests {
    use sui::test_scenario::{Self};

    use wormhole::emitter::{Self};
    use wormhole_ntt::state::{Self, State};
    use wormhole_ntt::setup::{Self, AdminCap};

    #[test]
    public fun test_setup() {
        let caller = @0xC0B2;
        let my_scenario = test_scenario::begin(caller);
        let scenario = &mut my_scenario;

        setup::init_test_only(test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, caller);

        let admin_cap = test_scenario::take_from_sender<AdminCap>(scenario);
        setup::complete(&admin_cap, 1, emitter::dummy(), test_scenario::ctx(scenario));

        test_scenario::next_tx(scenario, caller);

        let state = test_scenario::take_shared<State>(scenario);
        assert!(state::is_mode_burning(&state), 0);

        setup::set_manager_peer(&admin_cap, &mut state, 11, x"Fe756f2D911fA62F7F6703fB7BfA139B106A12c6", 18);
        setup::set_manager_peer(&admin_cap, &mut state, 11, x"Fe756f2D911fA62F7F6703fB7BfA139B106A12c5", 18);

        setup::set_transceiver_peer(&admin_cap, &mut state, 11, x"Fe756f2D911fA62F7F6703fB7BfA139B106A12c6");
        setup::set_transceiver_peer(&admin_cap, &mut state, 11, x"Fe756f2D911fA62F7F6703fB7BfA139B106A12c5");

        test_scenario::return_shared(state);
        test_scenario::return_to_sender(scenario, admin_cap);
        test_scenario::end(my_scenario);
    }
}
