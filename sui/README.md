# Sui 

## Prequisities

Make sure your Cargo version is at least 1.65.0 and then follow the steps below:

- https://docs.sui.io/build/install

- https://docs.sui.io/guides/developer/getting-started/sui-install

Install the `Sui` CLI. This tool is used to compile the contracts and run the tests.

## Design Overview

### Message Lifecycle (Sui)

1. **Transfer**

Client use Sui's Programmable Transaction Blocks(PTB) to call smart contracts functions on Sui.  

the core step is call ntt `prepare_transfer` function to generate `TransferTicket`  
and then use this `TransferTicket` to call ntt `transfer_tokens` to generate wormhole core `MessageTicket`  
and then use this `MessageTicket` to call wormhole core `publish_message` to emit the `WormholeMessage` event

```
const tx = new TransactionBlock();
    
const [transferCoin] = (() => {
    if (coinType === SUI_TYPE_ARG) {
        return tx.splitCoins(tx.gas, [tx.pure(amount)]);
    } else {
        const primaryCoinInput = tx.object(primaryCoin.coinObjectId);
        if (mergeCoins.length) {
            tx.mergeCoins(
            primaryCoinInput,
            mergeCoins.map((coin) => tx.object(coin.coinObjectId)),
            );
        }
        return tx.splitCoins(primaryCoinInput, [tx.pure(amount)]);
    }
})();

const [feeCoin] = tx.splitCoins(tx.gas, [tx.pure(feeAmount)]);
const [assetInfo] = tx.moveCall({
    target: `${this.nttPackageId}::state::verified_asset`,
    arguments: [tx.object(this.stateObjectId)],
    typeArguments: [coinType],
});

const [transferTicket, dust] = tx.moveCall({
    target: `${this.nttPackageId}::ntt_manager::prepare_transfer`,
    arguments: [
        tx.object(this.stateObjectId),
        assetInfo!,
        transferCoin!,
        tx.pure(toChainId(destination.chain)),
        tx.pure(uint8ArrayToBCS(destination.address.toUint8Array())),
        tx.pure(nonce),
    ],
    typeArguments: [coinType],
});

tx.moveCall({
    target: `${this.nttPackageId}::coin_utils::return_nonzero`,
    arguments: [dust!],
    typeArguments: [coinType],
});

const [messageTicket] = tx.moveCall({
    target: `${this.nttPackageId}::ntt_manager::transfer_tokens`,
    arguments: [tx.object(this.stateObjectId), transferTicket!],
    typeArguments: [coinType],
});

tx.moveCall({
    target: `${this.coreBridgePackageId}::publish_message::publish_message`,
    arguments: [
        tx.object(this.coreBridgeObjectId),
        feeCoin!,
        messageTicket!,
        tx.object(SUI_CLOCK_OBJECT_ID),
    ],
});
```

2. **Receive**
The Wormhole Transceiver receives a verified Wormhole message on sui via Wormhole core `vaa::parse_and_verify` to generate parsed `VAA` message  
and then use this `VAA` message to call `ntt_transceiver::verify_only_once` to generate `nttTransceiverMessage`  
and then use this `nttTransceiverMessage` to call `ntt_transceiver::redeem` to generate `redeemMessage`
and then use this `redeemMessage` to call `ntt_manager::attestation_received` to mint or unlock tokens

```
const tx = new TransactionBlock();
const [verifiedVAA] = tx.moveCall({
    target: `${this.coreBridgePackageId}::vaa::parse_and_verify`,
    arguments: [
    tx.object(this.coreBridgeObjectId),
    tx.pure(uint8ArrayToBCS(serialize(wormholeNTT))),
    tx.object(SUI_CLOCK_OBJECT_ID),
    ],
});

const [nttTransceiverMessage] = tx.moveCall({
    target: `${this.nttPackageId}::ntt_transceiver::verify_only_once`,
    arguments: [tx.object(this.stateObjectId), verifiedVAA!],
});

const [redeemMessage] = tx.moveCall({
    target: `${this.nttPackageId}::ntt_transceiver::redeem`,
    arguments: [tx.object(this.stateObjectId), nttTransceiverMessage!],
    typeArguments: [this.tokenType!],
});

tx.moveCall({
    target: `${this.nttPackageId}::ntt_manager::attestation_received`,
    arguments: [tx.object(this.stateObjectId), redeemMessage!],
    typeArguments: [this.tokenType!],
});
```

3. **Mint or Unlock**

Once a transfer has been successfully verified, the tokens can be minted (if the mode is "burning") or unlocked (if the mode is "locking") to the recipient on the destination chain. Note that the source token decimals are bounded betweeen 0 and `TRIMMED_DECIMALS` as enforced in the wire format. The transfer amount is untrimmed (scaled-up) if the destination chain token decimals exceed `TRIMMED_DECIMALS`. Once the approriate number of tokens have been minted or unlocked to the recipient, the `TransferRedeemed` event is emitted.

```
struct TransferRedeemed has drop, copy {
    emitter_chain: u16,
    emitter_address: ExternalAddress,
    sequence: u64
}
```

## Testing

The test files are loacated in the `contracts/tests` directory

simply run tests use the following commands in the `sui/contracts` directory

```sh
sui move test
```

## Deploy Wormhole NTT

- publish `WormholeNtt` Sui Contracts package

run this command in the `sui/contracts` directory

```
sui client publish
```

take a note of `PackageId`、`AdminCap` object id

- Use PTB to call `{PackageId}::setup::complete` function to generate `WormholeNtt` state object

mode param is used to determine whether is LOCKING or BURNING

contract interface
```
public fun complete(
    _: &AdminCap,
    mode: u8,
    emitter_cap: EmitterCap,
    ctx: &mut TxContext
) {
    
}
```

examples of PTB code scripts
```
let txb = new TransactionBlock();

let emitterCap = txb.moveCall({
    target: `{WormholeCorePackageId}::emitter::new`,
    arguments: [
        txb.object("{WormholeCoreStateObjectId}"), 
    ]
});

txb.moveCall({
    target: `{PackageId}::setup::complete`,
    arguments: [
        txb.object("{AdminCap}"), 
        txb.pure(1),
        emitterCap
    ]
});
```

`Notes`: when generate `emitterCap` it will emit an event `EmitterCreated` in this transcation  
keep a note of `emitter_cap` object id, this will be used as `EmitterAddress` in VAA

- call `{PackageId}::setup::add_new_native_token` to add new native token to the WormholeNtt

contract interface
```
public fun add_new_native_token<CoinType>(
    _: &AdminCap,
    state: &mut State,
    coin_meta: &CoinMetadata<CoinType>,
    treasury_cap: TreasuryCap<CoinType>,
) {
}
```

examples of PTB code scripts
```
let txb = new TransactionBlock();

txb.moveCall({
    target: `{PackageId}::setup::add_new_native_token`,
    arguments: [
        txb.object("{AdminCap}"), 
        txb.object("{NttStateObjectId}"),
        txb.object("{CoinMetaObjectId}"),
        txb.object("{TreasuryCapObjectId}"),
    ],
    typeArguments: ["{CoinType}"],
});
```

- set NttManager peer for target chain contracts

contract interface
```
public fun set_manager_peer(
    _: &AdminCap,
    state: &mut State,
    peer_chain_id: u16,
    peer_contract: vector<u8>,
    decimals: u8
) {
    
}
```

examples of PTB code scripts
```
const tx = new TransactionBlock();

tx.moveCall({
    target: `${PackageId}::setup::set_manager_peer`,
    arguments: [
        tx.object("{AdminCap}"), 
        tx.object("{NttStateObjectId}"), 
        tx.pure(peer_chain_id), 
        tx.pure(uint8ArrayToBCS(peer_contract)), 
        tx.pure(decimals)],
    });
```

- set Wormhole transceiver peer for target chain contracts

contract interface
```
public fun set_transceiver_peer(
    _: &AdminCap,
    state: &mut State,
    peer_chain_id: u16,
    peer_contract: vector<u8>,
)
```

examples of PTB code scripts
```
const tx = new TransactionBlock();

tx.moveCall({
    target: `${PackageId}::setup::set_transceiver_peer`,
    arguments: [
        tx.object("{AdminCap}"), 
        tx.object("{NttStateObjectId}"), 
        tx.pure(peer_chain_id), 
        tx.pure(uint8ArrayToBCS(peer_contract))],
    });
```

## TypeScript Client SDK

Sui Contracts Consts
```
export type SuiContracts = {
  stateObjectId: string;
  packageId: string;
  coreBridgeObjectId: string;
  coreBridgePackageId: string;
  coinType: string;
  adminCapObjectId: string;
  emitterCapId: string;
};
```

```
 /**
   * transfer sends a message to the Ntt manager to initiate a transfer
   * @param sender the address of the sender
   * @param amount the amount to transfer
   * @param destination the destination chain
   * @param transfer options
   */
  transfer(
    sender: AccountAddress<C>,
    amount: bigint,
    destination: ChainAddress,
    options: Ntt.TransferOptions
  ): AsyncGenerator<UnsignedTransaction<N, C>>;
```

```
/**
   * redeem redeems a set of Attestations to the corresponding transceivers on the destination chain
   * @param attestations The attestations to redeem, the length should be equal to the number of transceivers
   */
  redeem(
    attestations: Ntt.Attestation[],
    payer?: AccountAddress<C>
  ): AsyncGenerator<UnsignedTransaction<N, C>>;
```

examples
```
import {
    TransactionId,
    signSendWait,
    wormhole,
  } from "@wormhole-foundation/sdk";

  import evm from "@wormhole-foundation/sdk/evm";
  import sui from "@wormhole-foundation/sdk/sui";
  
  // register protocol implementations
  import "@wormhole-foundation/sdk-evm-ntt";
  import "@wormhole-foundation/sdk-sui-ntt";
  
  import { TEST_NTT_TOKENS, SUI_NTT_CONTRACTS } from "./consts.js";
  import { getSigner } from "./helpers.js";
  
  (async function () {
    const wh = await wormhole("Testnet", [sui, evm]);
    const src = wh.getChain("Sui");
    const dst = wh.getChain("Fantom");
  
    const srcSigner = await getSigner(src);
    const dstSigner = await getSigner(dst);
  
    const srcNtt = await src.getProtocol("Ntt", {
      ntt: SUI_NTT_CONTRACTS,
    });
    const dstNtt = await dst.getProtocol("Ntt", {
      ntt: TEST_NTT_TOKENS[dst.chain],
    });
  
    // Initiate the transfer (or set to recoverTxids to complete transfer)
    const txids: TransactionId[] = await signSendWait(src,
      srcNtt.transfer(srcSigner.address.address, 1000_000_000n, dstSigner.address, {
        queue: false,
        automatic: false,
        gasDropoff: 0n,
      }),
      srcSigner.signer
    )
    console.log("Source txs", txids);
  
    const vaa = await wh.getVaa(txids[0]!.txid, "Ntt:WormholeTransfer");

    const dstTxids = await signSendWait(dst,
      dstNtt.redeem([vaa!]),
      dstSigner.signer
    );
    console.log("dstTxids", dstTxids);
  })();
  
```