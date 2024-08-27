// SPDX-License-Identifier: Apache 2

/// This module implements a custom type for a 32-byte standardized address,
/// which is meant to represent an address from any other network.
module wormhole_ntt::ntt_external_address {
    use aptos_std::from_bcs;
    use wormhole::cursor::{Cursor};
    use wormhole_ntt::bytes32::{Self, Bytes32};
    use wormhole::external_address::{Self, ExternalAddress};

    /// Underlying data is all zeros.
    const E_ZERO_ADDRESS: u64 = 0;

    /// Container for `Bytes32`.
    struct NttExternalAddress has copy, drop, store {
        value: Bytes32,
    }

    /// Create `ExternalAddress`.
    public fun new(value: Bytes32): NttExternalAddress {
        NttExternalAddress { value }
    }

    /// Create `ExternalAddress` of all zeros.`
    public fun default(): NttExternalAddress {
        new(bytes32::default())
    }

    /// Create `ExternalAddress` ensuring that not all bytes are zero.
    public fun new_nonzero(value: Bytes32): NttExternalAddress {
        assert!(bytes32::is_nonzero(&value), E_ZERO_ADDRESS);
        new(value)
    }

    /// Destroy `ExternalAddress` for underlying bytes as `vector<u8>`.
    public fun to_bytes(ext: NttExternalAddress): vector<u8> {
        bytes32::to_bytes(to_bytes32(ext))
    }

    /// Destroy 'ExternalAddress` for underlying data.
    public fun to_bytes32(ext: NttExternalAddress): Bytes32 {
        let NttExternalAddress { value } = ext;
        value
    }

    /// Drain 32 elements of `Cursor<u8>` to create `ExternalAddress`.
    public fun take_bytes(cur: &mut Cursor<u8>): NttExternalAddress {
        new(bytes32::take_bytes(cur))
    }

    /// Drain 32 elements of `Cursor<u8>` to create `ExternalAddress` ensuring
    /// that not all bytes are zero.
    public fun take_nonzero(cur: &mut Cursor<u8>): NttExternalAddress {
        new_nonzero(bytes32::take_bytes(cur))
    }

    /// Destroy `ExternalAddress` to represent its underlying data as `address`.
    public fun to_address(ext: NttExternalAddress): address {
        from_bcs::to_address(to_bytes(ext))
    }

    /// Create `ExternalAddress` from `address`.
    public fun from_address(addr: address): NttExternalAddress {
        new(bytes32::from_address(addr))
    }

    /// Check whether underlying data is not all zeros.
    public fun is_nonzero(self: &NttExternalAddress): bool {
        bytes32::is_nonzero(&self.value)
    }

    public fun to_wormhole_external_address(self: NttExternalAddress): ExternalAddress {
        external_address::from_bytes(to_bytes(self))
    }
}
