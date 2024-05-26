#[test_only]
module wormhole_ntt::trimmed_amount_tests {
    use wormhole_ntt::trimmed_amount::{Self};

    #[test]
    public fun new() {
        let trimmed_amount = trimmed_amount::new(10, 8);
        assert!(trimmed_amount::value(&trimmed_amount) == 10, 0);
        assert!(trimmed_amount::decimals(&trimmed_amount) == 8, 0);
    }

    #[test]
    public fun trim() {
        let trimmed_amount = trimmed_amount::trim(90000000, 8, 8);
        assert!(trimmed_amount::value(&trimmed_amount) == 90000000, 0);
        assert!(trimmed_amount::decimals(&trimmed_amount) == 8, 0);

        let trimmed_amount = trimmed_amount::trim(9000000000, 10, 7);
        assert!(trimmed_amount::value(&trimmed_amount) == 9000000, 0);
        assert!(trimmed_amount::decimals(&trimmed_amount) == 7, 0);

        let trimmed_amount = trimmed_amount::trim(8000000000, 10, 9);
        assert!(trimmed_amount::value(&trimmed_amount) == 80000000, 0);
        assert!(trimmed_amount::decimals(&trimmed_amount) == 8, 0);
    }

    #[test]
    public fun untrim() {
        let trimmed_amount = trimmed_amount::trim(90000000, 8, 8);
        let umtrimmed_amount = trimmed_amount::untrim(&trimmed_amount, 8);
        assert!(umtrimmed_amount == 90000000, 0);

        let trimmed_amount = trimmed_amount::trim(9000000000, 10, 7);
        let umtrimmed_amount = trimmed_amount::untrim(&trimmed_amount, 9);
        assert!(umtrimmed_amount == 900000000, 0);

        let trimmed_amount = trimmed_amount::trim(8000000000, 10, 9);
        let umtrimmed_amount = trimmed_amount::untrim(&trimmed_amount, 10);
        assert!(umtrimmed_amount == 8000000000, 0);
    }
}