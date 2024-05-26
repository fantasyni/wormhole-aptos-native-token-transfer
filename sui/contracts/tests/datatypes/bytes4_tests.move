#[test_only]
module wormhole_ntt::bytes4_tests {
    use std::vector::{Self};

    use wormhole_ntt::bytes4::{Self};

    #[test]
    public fun new() {
        let data = x"deadbeef";
        assert!(vector::length(&data) == 4, 0);
        let actual = bytes4::new(data);

        assert!(bytes4::data(&actual) == data, 0);
    }

    #[test]
    public fun default() {
        let actual = bytes4::default();
        let expected = x"00000000";
        assert!(bytes4::data(&actual) == expected, 0);
    }

    #[test]
    public fun from_bytes() {
        let actual = bytes4::from_bytes(x"deadbeef");
        let expected = x"deadbeef";
        assert!(bytes4::data(&actual) == expected, 0);
    }

    #[test]
    public fun is_nonzero() {
        let data = x"deadbeef";
        let actual = bytes4::new(data);
        assert!(bytes4::is_nonzero(&actual), 0);

        let zeros = bytes4::default();
        assert!(!bytes4::is_nonzero(&zeros), 0);
    }

    #[test]
    #[expected_failure(abort_code = bytes4::E_INVALID_BYTES4)]
    public fun cannot_new_non_4_byte_vector() {
        let data = x"deadbeefdeadbeef";
        assert!(vector::length(&data) != 4, 0);
        bytes4::new(data);
    }
}