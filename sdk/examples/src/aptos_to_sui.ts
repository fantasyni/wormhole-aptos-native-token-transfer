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
