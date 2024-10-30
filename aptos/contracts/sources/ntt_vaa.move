/// Token Bridge VAA utilities
module wormhole_ntt::ntt_vaa {
    use wormhole::vaa::{Self, VAA};
    use wormhole_ntt::ntt_state::{Self};

    /// We have no registration for this chain
    const E_UNKNOWN_CHAIN: u64 = 0;
    /// We have a registration, but it's different from what's given
    const E_UNKNOWN_EMITTER: u64 = 1;

    /// Aborts if the VAA has already been consumed. Marks the VAA as consumed
    /// the first time around.
    public(friend) fun replay_protect(object_address: address, vaa: &VAA) {
        // this calls set::add which aborts if the element already exists
        ntt_state::set_vaa_consumed(object_address, vaa::get_hash(vaa));
    }

    /// Parses, verifies, and replay protects a token bridge VAA.
    /// Aborts if the VAA is not from a known token bridge emitter.
    ///
    /// Has a 'friend' visibility so that it's only callable by the token bridge
    /// (otherwise the replay protection could be abused to DoS the bridge)
    public fun parse_verify_and_replay_protect(object_address: address, vaa: vector<u8>): VAA {
        let vaa = parse_and_verify(vaa);
        replay_protect(object_address, &vaa);
        vaa
    }

    /// Parses, and verifies a token bridge VAA.
    /// Aborts if the VAA is not from a known token bridge emitter.
    public fun parse_and_verify(vaa: vector<u8>): VAA {
        let vaa = vaa::parse_and_verify(vaa);
        vaa
    }
}