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
  
    let peer_address = Wormhole.chainAddress(dst.chain, "0x9727d9fc676eba9b5322d41bd4d259d455013a3e");
    // Initiate the transfer (or set to recoverTxids to complete transfer)
    let txids = await signSendWait(src,
      srcNtt.setPeer(peer_address, 18, 10000000n),
      srcSigner.signer
    );
    console.log("Source txs", txids);

    peer_address = Wormhole.chainAddress(dst.chain, "0xf6234aaa554437c780c992dCC4593A1Df30c0800");
    txids = await signSendWait(src,
      srcNtt.setWormholeTransceiverPeer(peer_address),
      srcSigner.signer
    );
    console.log("Source txs", txids);
  })();
  