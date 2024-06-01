import {
    signSendWait,
    wormhole,
    Wormhole
  } from "@wormhole-foundation/sdk";
  import evm from "@wormhole-foundation/sdk/evm";
  import sui from "@wormhole-foundation/sdk/sui";
  
  // register protocol implementations
  import "@wormhole-foundation/sdk-evm-ntt";
  import "@wormhole-foundation/sdk-sui-ntt";
  
  import { SUI_NTT_CONTRACTS } from "./consts.js";
  import { getSigner } from "./helpers.js";
  
  (async function () {
    const wh = await wormhole("Testnet", [sui, evm]);
    const src = wh.getChain("Sui");
    const dst = wh.getChain("Fantom");
  
    const srcSigner = await getSigner(src);
  
    const srcNtt = await src.getProtocol("Ntt", {
      ntt: SUI_NTT_CONTRACTS,
    });
  
    let peer_address = Wormhole.chainAddress(dst.chain, "0x04b05134353c0150498d851c3d1a196ddd4a2a5a");
    // Initiate the transfer (or set to recoverTxids to complete transfer)
    let txids = await signSendWait(src,
      srcNtt.setPeer(peer_address, 18, 10000000n),
      srcSigner.signer
    );
    console.log("Source txs", txids);

    peer_address = Wormhole.chainAddress(dst.chain, "0x16cf26bdd9d31f7337d72a42a696861364244431");
    txids = await signSendWait(src,
      srcNtt.setWormholeTransceiverPeer(peer_address),
      srcSigner.signer
    );
    console.log("Source txs", txids);
  })();
  