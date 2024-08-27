module wormhole_ntt::bytes {
    use std::vector::{Self};
    use std::bcs::{Self};
    use wormhole::cursor::{Self, Cursor};

    public fun push_u8(buf: &mut vector<u8>, v: u8) {
        vector::push_back<u8>(buf, v);
    }

    public fun push_u16_be(buf: &mut vector<u8>, value: u16) {
        push_reverse(buf, value);
    }

    public fun push_u32_be(buf: &mut vector<u8>, value: u32) {
        push_reverse(buf, value);
    }

    public fun push_u64_be(buf: &mut vector<u8>, value: u64) {
        push_reverse(buf, value);
    }

    public fun push_u128_be(buf: &mut vector<u8>, value: u128) {
        push_reverse(buf, value);
    }

    public fun push_u256_be(buf: &mut vector<u8>, value: u256) {
        push_reverse(buf, value);
    }

    public fun take_u8(cur: &mut Cursor<u8>): u8 {
        cursor::poke(cur)
    }

    public fun take_u16_be(cur: &mut Cursor<u8>): u16 {
        let out = 0;
        let i = 0;
        while (i < 2) {
            out = (out << 8) + (cursor::poke(cur) as u16);
            i = i + 1;
        };
        out
    }

    public fun take_u32_be(cur: &mut Cursor<u8>): u32 {
        let out = 0;
        let i = 0;
        while (i < 4) {
            out = (out << 8) + (cursor::poke(cur) as u32);
            i = i + 1;
        };
        out
    }

    public fun take_u64_be(cur: &mut Cursor<u8>): u64 {
        let out = 0;
        let i = 0;
        while (i < 8) {
            out = (out << 8) + (cursor::poke(cur) as u64);
            i = i + 1;
        };
        out
    }

    public fun take_u128_be(cur: &mut Cursor<u8>): u128 {
        let out = 0;
        let i = 0;
        while (i < 16) {
            out = (out << 8) + (cursor::poke(cur) as u128);
            i = i + 1;
        };
        out
    }

    public fun take_u256_be(cur: &mut Cursor<u8>): u256 {
        let out = 0;
        let i = 0;
        while (i < 32) {
            out = (out << 8) + (cursor::poke(cur) as u256);
            i = i + 1;
        };
        out
    }

    public fun take_bytes(cur: &mut Cursor<u8>, num_bytes: u64): vector<u8> {
        let out = vector::empty();
        let i = 0;
        while (i < num_bytes) {
            vector::push_back(&mut out, cursor::poke(cur));
            i = i + 1;
        };
        out
    }

    fun push_reverse<T: drop>(buf: &mut vector<u8>, v: T) {
        let data = bcs::to_bytes(&v);
        vector::reverse(&mut data);
        vector::append(buf, data);
    }
}

