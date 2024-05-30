module wormhole_ntt::nft_token {
    use std::vector;
    use std::string::String;
    use sui::table::{Self, Table};
    use sui::tx_context::TxContext;

    use wormhole::state::{chain_id};
    use wormhole_ntt::nft::{Self, NFT, TreasuryCap};

    friend wormhole_ntt::nft_registry;
    friend wormhole_ntt::non_fungible_ntt_manager;

    /// Container for storing NFTs, `token_ids`, and `TreasuryCap` .
    struct NFTToken<phantom C> has store {
        nfts: Table<u256, NFT<C>>,
        token_ids: vector<u256>,
        treasury_cap: TreasuryCap<C>,
    }

    /// create new NFTToken
    public(friend) fun new<C>(
        treasury_cap: TreasuryCap<C>,
        ctx: &mut TxContext
    ): NFTToken<C> {
        NFTToken {
            nfts: table::new<u256, NFT<C>>(ctx),
            token_ids: vector[],
            treasury_cap,
        }
    }

    /// Retrieve chain id from `NFTToken`.
    public fun chain<C>(
        _nft: &NFTToken<C>
    ): u16 {
        chain_id()
    }

    /// Retrieve nft name from `NFTToken`.
    public fun name<C>(
        nft: &NFTToken<C>
    ): String {
        nft::name(&nft.treasury_cap)
    }

    /// Retrieve nft description from `NFTToken`.
    public fun description<C>(
        nft: &NFTToken<C>
    ): String {
        nft::description(&nft.treasury_cap)
    }

    /// Retrieve nft base_url from `NFTToken`.
    public fun base_url<C>(
        nft: &NFTToken<C>
    ): String {
        nft::base_url(&nft.treasury_cap)
    }

    /// burn nft
    public(friend) fun burn<C>(
        self: &mut NFTToken<C>,
        nft: NFT<C>,
    ): u256 {
        let token_id = nft::token_id(&nft);
        nft::burn(&mut self.treasury_cap, nft);
        token_id
    }

    /// mint nft for token_id
    public(friend) fun mint<C>(
        self: &mut NFTToken<C>,
        token_id: u256,
        ctx: &mut TxContext
    ): NFT<C> {
        nft::mint(&mut self.treasury_cap, token_id, ctx)
    }

    /// deposit nft to store in `NFTToken`
    public(friend) fun deposit<C>(
        self: &mut NFTToken<C>,
        nft: NFT<C>
    ): u256 {
        let token_id = nft::token_id(&nft);
        table::add(&mut self.nfts, token_id, nft);

        vector::push_back(&mut self.token_ids, token_id);
        token_id
    }

    /// withdraw nft with token_id from `NFTToken`
    public(friend) fun withdraw<C>(
        self: &mut NFTToken<C>,
        token_id: u256
    ): NFT<C> {
        let nft = table::remove(&mut self.nfts, token_id);

        let (_, i) = vector::index_of(&self.token_ids, &token_id);
        vector::remove(&mut self.token_ids, i);

        nft
    }

    #[test_only]
    public fun new_test_only<C>(
        treasury_cap: TreasuryCap<C>,
        ctx: &mut TxContext
    ): NFTToken<C> {
        new(treasury_cap, ctx)
    }

    #[test_only]
    public fun burn_test_only<C>(
        self: &mut NFTToken<C>,
        nft: NFT<C>,
    ): u256 {
        burn(self, nft)
    }

    #[test_only]
    public fun mint_test_only<C>(
        self: &mut NFTToken<C>,
        token_id: u256,
        ctx: &mut TxContext
    ): NFT<C> {
        mint(self, token_id, ctx)
    }

    #[test_only]
    public fun deposit_test_only<C>(
        self: &mut NFTToken<C>,
        nft: NFT<C>
    ): u256 {
        deposit(self, nft)
    }

    #[test_only]
    public fun withdraw_test_only<C>(
        self: &mut NFTToken<C>,
        token_id: u256
    ): NFT<C> {
        withdraw(self, token_id)
    }

    #[test_only]
    public fun destroy<C>(asset: NFTToken<C>) {
        let NFTToken {
            nfts,
            token_ids,
            treasury_cap
        } = asset;

        let i = 0;
        let num = vector::length(&token_ids);
        while (i < num) {
            let token_id = vector::pop_back(&mut token_ids);
            let nft = table::remove(&mut nfts, token_id);
            nft::burn(&mut treasury_cap, nft);

            i = i + 1;
        };

        vector::destroy_empty(token_ids);
        table::destroy_empty(nfts);
        sui::test_utils::destroy(treasury_cap);
    }
}
