module wormhole_ntt::nft {
    use std::vector;
    use sui::url::{Self, Url};
    use sui::object::{Self, UID};
    use sui::table::{Self, Table};
    use sui::tx_context::TxContext;
    use std::string::{Self, String};

    const EBadWitness: u64 = 0;
    const ETokenIdMinted: u64 = 1;

    /// A NFT of type `T` worth `value`. Transferable and storable
    struct NFT<phantom T> has key, store {
        id: UID,
        token_id: u256,
        name: String,
        description: String,
        url: Url,
    }

    /// Capability allowing the bearer to mint and burn NFT of type `T`.
    struct TreasuryCap<phantom T> has key, store {
        id: UID,
        name: String,
        description: String,
        base_url: String,
        token_ids: Table<u256, bool>
    }

    /// Create a new NFT type `T` as and return the `TreasuryCap` for
    /// `T` to the caller. Can only be called with a `one-time-witness`
    /// type, ensuring that there's only one `TreasuryCap` per `T`.
    public fun create_nft<T: drop>(
        witness: T,
        name: vector<u8>,
        description: vector<u8>,
        base_url: vector<u8>,
        ctx: &mut TxContext
    ): TreasuryCap<T> {
        // Make sure there's only one instance of the type T
        assert!(sui::types::is_one_time_witness(&witness), EBadWitness);

        TreasuryCap {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            base_url: string::utf8(base_url),
            token_ids: table::new(ctx)
        }
    }

    /// mint nft for token id
    public fun mint<T>(
        cap: &mut TreasuryCap<T>,
        token_id: u256,
        ctx: &mut TxContext
    ): NFT<T> {
        assert!(table::contains(&cap.token_ids, token_id) == false, ETokenIdMinted);

        table::add(&mut cap.token_ids, token_id, true);

        let new_url = cap.base_url;
        string::append(&mut new_url, string::utf8(uint_to_bytes(token_id)));

        NFT<T> {
            id: object::new(ctx),
            token_id,
            name: cap.name,
            description: cap.description,
            url: url::new_unsafe(string::to_ascii(new_url))
        }
    }

    /// burn nft
    public fun burn<T>(
        cap: &mut TreasuryCap<T>,
        nft: NFT<T>
    ) {
        let NFT<T> { id, token_id, name: _, description: _, url: _ } = nft;

        table::remove(&mut cap.token_ids, token_id);

        object::delete(id);
    }

    /// Retrieve nft name
    public fun nft_name<T>(self: &NFT<T>): String {
        self.name
    }

    /// Retrieve nft description
    public fun nft_description<T>(self: &NFT<T>): String {
        self.description
    }

    /// Retrieve nft url
    public fun nft_url<T>(self: &NFT<T>): Url {
        self.url
    }

    /// Retrieve nft token id
    public fun token_id<T>(self: &NFT<T>): u256 {
        self.token_id
    }

    /// Retrieve nft name from `TreasuryCap`
    public fun name<T>(cap: &TreasuryCap<T>): String {
        cap.name
    }

    /// Retrieve nft description from `TreasuryCap`
    public fun description<T>(cap: &TreasuryCap<T>): String {
        cap.description
    }

    /// Retrieve nft base_url from `TreasuryCap`
    public fun base_url<T>(cap: &TreasuryCap<T>): String {
        cap.base_url
    }

    fun uint_to_bytes(num: u256): vector<u8> {
        let buf: vector<u8> = vector[];

        while (num > 0) {
            vector::push_back(&mut buf, ((num % 10 + 48) as u8));
            num = num / 10;
        };

        vector::reverse(&mut buf);
        buf
    }

    #[test_only]
    public fun destroy_treasury_cap<T>(cap: TreasuryCap<T>) {
        let TreasuryCap<T> {
            id,
            name: _,
            description: _,
            base_url: _,
            token_ids
        } = cap;

        table::destroy_empty(token_ids);
        object::delete(id);
    }

    #[test]
    fun test() {
        use std::debug;

        let buf: vector<u8> = vector[];

        vector::append(&mut buf, uint_to_bytes(51233229567));

        let res = string::utf8(buf);
        debug::print(&res);

        let a = string::utf8(b"https://cn.bing.com/");
        string::append(&mut a, string::utf8(uint_to_bytes(51233229567)));
        debug::print(&a);
    }
}
