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
  