#[test_only]
module wormhole_ntt::wormhole_ntt_scenario {
    use sui::test_scenario::{Self, Scenario};

    use wormhole_ntt::state::{State};

    public fun person(): address {
        wormhole::wormhole_scenario::person()
    }

    public fun two_people(): (address, address) {
        wormhole::wormhole_scenario::two_people()
    }

    public fun three_people(): (address, address, address) {
        wormhole::wormhole_scenario::three_people()
    }

    public fun take_state(scenario: &Scenario): State {
        test_scenario::take_shared(scenario)
    }

    public fun return_state(token_bridge_state: State) {
        test_scenario::return_shared(token_bridge_state);
    }
}
