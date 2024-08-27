# Aptos 

## Prequisities

Make sure install aptos cli

- https://aptos.dev/en/build/cli

Install the `Aptos` CLI. This tool is used to compile the contracts and run the tests.

## Design Overview

### Message Lifecycle (Sui)

1. **transfer**

transfer token through calling aptos move function **ntt_manager::transfer_tokens**
```
public entry fun transfer_tokens<CoinType>(
    sender: &signer, 
    amount: u64, 
    recipient_chain: u16, 
    recipient: vector<u8>, 
    nonce: u64
)  {
}
```

2. **redeem**
receive token through calling aptos move function **ntt_transceiver::submit_vaa**

```
public entry fun submit_vaa<CoinType>(vaa: vector<u8>) {
}
```


## Deploy Wormhole NTT

- publish `WormholeNtt` Aptos Contracts package

in Move.toml you can configure **admin_addr** to setup role of admin

and then run the following command in the `aptos/contracts` directory, publish package as object

```
aptos move create-object-and-publish-package --address-name wormhole_ntt
```

then you will get object address as your PackageId

- there are two modes for ntt
**LOCKING** you should deploy your own aptos move contract, can call move function `{PackageId}::ntt::add_new_token` to register token
**BURNING** you should call move function `{PackageId}::ntt::add_new_native_token` to deploy token

- Call Move function `{PackageId}::ntt::set_manager_peer` setup ntt manager peer address
- Call Move function `{PackageId}::ntt::set_transceiver_peer` setup ntt transceiver peer address

## TypeScript Client SDK

Aptos Contracts Consts
```
export type AptosContracts = {
  packageId: string;
  tokenType: string;
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
async *transfer(
    sender: AccountAddress<C>,
    amount: bigint,
    destination: ChainAddress,
    options: Ntt.TransferOptions
): AsyncGenerator<AptosUnsignedTransaction<N, C>> {
   
}
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

import aptos from "@wormhole-foundation/sdk/aptos";
import sui from "@wormhole-foundation/sdk/sui";

// register protocol implementations
import "@wormhole-foundation/sdk-aptos-ntt";
import "@wormhole-foundation/sdk-sui-ntt";

import { SUI_NTT_CONTRACTS, APTOS_NTT_CONTRACTS } from "./consts.js";
import { getSigner } from "./helpers.js";

(async function () {
  const wh = await wormhole("Testnet", [sui, aptos]);
  const src = wh.getChain("Aptos");
  const dst = wh.getChain("Sui");

  const srcSigner = await getSigner(src);
  const dstSigner = await getSigner(dst);

  const srcNtt = await src.getProtocol("Ntt", {
    ntt: APTOS_NTT_CONTRACTS,
  });
  const dstNtt = await dst.getProtocol("Ntt", {
    ntt: SUI_NTT_CONTRACTS,
  });

  const txids: TransactionId[] = await signSendWait(src,
    srcNtt.transfer(srcSigner.address.address, 1_000_000_0n, dstSigner.address, {
      queue: false,
      automatic: false,
      gasDropoff: 0n,
    }),
    srcSigner.signer
  )
  console.log("Source txs", txids);

  const vaa = await wh.getVaa(txids[txids.length - 1]!.txid, "Ntt:WormholeTransfer");

  const dstTxids = await signSendWait(
    dst,
    dstNtt.redeem([vaa!]),
    dstSigner.signer
  );
  console.log("dstTxids", dstTxids);
})();
```