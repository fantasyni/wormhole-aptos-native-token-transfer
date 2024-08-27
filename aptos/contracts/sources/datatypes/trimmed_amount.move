module wormhole_ntt::trimmed_amount {
    /// TrimmedAmount is to handle token amounts with different decimals
    struct TrimmedAmount has store, copy, drop {
        amount: u64,
        decimals: u8
    }

    const TRIMMED_DECIMALS: u8 = 8;

    // create new TrimmedAmount
    public fun new(amount: u64, decimals: u8): TrimmedAmount {
        TrimmedAmount {
            amount,
            decimals
        }
    }

    /// trim the amount to target decimals.
    /// The actual resulting decimals is the minimum of TRIMMED_DECIMALS,
    /// fromDecimals, and toDecimals.
    public fun trim(amount: u64, from_decimals: u8, to_decimals: u8): TrimmedAmount {
        let actual_to_decimals = min_uint8(min_uint8(TRIMMED_DECIMALS, from_decimals), to_decimals);
        let amount_scaled = scale(amount, from_decimals, actual_to_decimals);

        new(amount_scaled, actual_to_decimals)
    }

    /// Retrieve value of the TrimmedAmount.
    public fun value(self: &TrimmedAmount): u64 {
        self.amount
    }

    /// Retrieve decimals of the TrimmedAmount.
    public fun decimals(self: &TrimmedAmount): u8 {
        self.decimals
    }

    /// untrim the TrimmedAmount to the orignal amount based on the decimal
    public fun untrim(self: &TrimmedAmount, to_decimals: u8): u64 {
        scale(self.amount, self.decimals, to_decimals)
    }

    /// scale the amount from original decimals to target decimals (base 10)
    fun scale(amount: u64, from_decimals: u8, to_decimals: u8): u64 {
        if (from_decimals == to_decimals) {
            return amount
        };

        if (from_decimals > to_decimals) {
            let n = from_decimals - to_decimals;
            while (n > 0) {
                amount = amount / 10;
                n = n - 1;
            }
        } else {
            let n = to_decimals - from_decimals;
            while (n > 0) {
                amount = amount * 10;
                n = n - 1;
            }
        };

        amount
    }

    /// help min function
    fun min_uint8(a: u8, b: u8): u8 {
        if (a < b) {
            a
        } else {
            b
        }
    }
}
