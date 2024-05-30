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
  
  import {SuiNtt} from "@wormhole-foundation/sdk-sui-ntt";
  import { TEST_NTT_TOKENS, SUI_NTT_CONTRACTS } from "./consts.js";
  import { getSigner } from "./helpers.js";
  import axios from "axios";
  import { encoding } from "@wormhole-foundation/sdk-base";

  interface ApiVaa {
    sequence: number;
    id: string;
    version: number;
    emitterChain: number;
    emitterAddr: string;
    emitterNativeAddr: string;
    guardianSetIndex: number;
    vaa: string;
    timestamp: string;
    updatedAt: string;
    indexedAt: string;
    txHash: string;
  }

  async function getVaaByTxHash(rpcUrl: string, txid: string): Promise<ApiVaa | null> {
    const url = `${rpcUrl}/api/v1/vaas?txHash=${txid}`;
    try {
      const response = await axios.get<{ data: ApiVaa[] }>(url);
      if (response.data.data.length > 0) return response.data.data[0]!;
    } catch (error) {
      if (!error) return null;
      if (typeof error === "object") {
        // A 404 error means the VAA is not yet available
        // since its not available yet, we return null signaling it can be tried again
        if (axios.isAxiosError(error) && error.response?.status === 404) return null;
        if ("status" in error && error.status === 404) return null;
      }
      throw error;
    }
    return null;
  }

  (async function () {
    const wh = await wormhole("Testnet", [sui, evm]);
    const src = wh.getChain("Sui");
    const dst = wh.getChain("Fantom");
  
    const srcSigner = await getSigner(src);
    const dstSigner = await getSigner(dst);
  
    const srcNtt = await src.getProtocol("Ntt", {
      ntt: SUI_NTT_CONTRACTS,
    }) as SuiNtt<"Testnet", "Sui">;
    const dstNtt = await dst.getProtocol("Ntt", {
      ntt: TEST_NTT_TOKENS[dst.chain],
    });
  
    const token_ids = [14];
    const token_id_width = 1;

    // Initiate the transfer (or set to recoverTxids to complete transfer)
    const txids: TransactionId[] = await signSendWait(src,
      srcNtt.transfer_nft(srcSigner.address.address, token_ids, token_id_width, dstSigner.address, {
        queue: false,
        automatic: false,
        gasDropoff: 0n,
      }),
      srcSigner.signer
    )
    console.log("Source txs", txids);
  
    const txid = txids[0]!.txid;
    // const vaa = await wh.getVaa(txid, "Ntt:WormholeTransfer");
    const vaa = await getVaaByTxHash("https://api.testnet.wormholescan.io", txid);
    if (vaa) {
      const bytes = encoding.b64.decode(vaa.vaa);
      console.log(bytes);
    } 
    console.log(vaa);
    
    // const dstTxids = await signSendWait(dst,
    //   dstNtt.redeem([vaa!]),
    //   dstSigner.signer
    // );
    // console.log("dstTxids", dstTxids);
  })();
  