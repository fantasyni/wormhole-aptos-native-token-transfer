import {
    signSendWait,
    wormhole,
    Wormhole
  } from "@wormhole-foundation/sdk";
  import evm from "@wormhole-foundation/sdk/evm";
  import sui from "@wormhole-foundation/sdk/sui";
  import aptos from "@wormhole-foundation/sdk/aptos";
  
  // register protocol implementations
  import "@wormhole-foundation/sdk-evm-ntt";
  import "@wormhole-foundation/sdk-sui-ntt";
  
  import { SUI_NTT_CONTRACTS } from "./consts.js";
  import { getSigner } from "./helpers.js";
  
  (async function () {
    const wh = await wormhole("Testnet", [sui, aptos]);
    const src = wh.getChain("Sui");
    const dst = wh.getChain("Aptos");
  
    const srcSigner = await getSigner(src);
  
    const srcNtt = await src.getProtocol("Ntt", {
      ntt: SUI_NTT_CONTRACTS,
    });
  
    let peer_address = Wormhole.chainAddress(dst.chain, "0xfdf5c5c3552d1798335858f92722d5a09b8e1c5b9fc00d69e872a97eb706836d");
    // Initiate the transfer (or set to recoverTxids to complete transfer)
    let txids = await signSendWait(src,
      srcNtt.setPeer(peer_address, 9, 10000000n),
      srcSigner.signer
    );
    console.log("Source txs", txids);

    peer_address = Wormhole.chainAddress(dst.chain, "0000000000000000000000000000000000000000000000000000000000000072");
    txids = await signSendWait(src,
      srcNtt.setWormholeTransceiverPeer(peer_address),
      srcSigner.signer
    );
    console.log("Source txs", txids);
  })();
  