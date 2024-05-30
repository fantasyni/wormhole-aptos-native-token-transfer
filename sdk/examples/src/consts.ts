import { Chain } from "@wormhole-foundation/sdk";
import { Ntt } from "@wormhole-foundation/sdk-definitions-ntt";
import { NttRoute } from "@wormhole-foundation/sdk-route-ntt";
import { SuiContracts } from "@wormhole-foundation/sdk-sui-ntt";

type NttContracts = {
  [key in Chain]?: Ntt.Contracts;
};

export const SUI_NTT_CONTRACTS: SuiContracts = {
  stateObjectId: "0xdf754b9fa363f15292dc7ff4f6b29653afa18201f4c7b55fef6f0414db181a02",
  packageId: "0xa0501c44671d952d9703617150a05107cce9be42c4db946d07b618d42b2ef21a",
  coreBridgeObjectId: "0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790",
  coreBridgePackageId: "0xf47329f4344f3bf0f8e436e2f7b485466cff300f12a166563995d3888c296a94",
  tokenType: "0x7d69e6268080a452e1577412108257a637fa16b21e1a1b67471b5b7fbdd205ab::justin_nft::JUSTIN_NFT",
  adminCapObjectId: "0xca8c69a7ae00014c562e349ae06d46ee3938210ef621b70b7999eb6e78e66502",
  emitterCapId: "0x656668c254307a926280abd1586d716ec4da18cf60d9a6f88827747cc5c7111b",
  nftType: "0xa0501c44671d952d9703617150a05107cce9be42c4db946d07b618d42b2ef21a::nft::NFT<0x7d69e6268080a452e1577412108257a637fa16b21e1a1b67471b5b7fbdd205ab::justin_nft::JUSTIN_NFT>"
}

export const JITO_NTT_CONTRACTS: NttContracts = {
  Solana: {
    token: "E3W7KwMH8ptaitYyWtxmfBUpqcuf2XieaFtQSn1LVXsA",
    manager: "WZLm4bJU4BNVmzWEwEzGVMQ5XFUc4iBmMSLutFbr41f",
    transceiver: { wormhole: "WZLm4bJU4BNVmzWEwEzGVMQ5XFUc4iBmMSLutFbr41f" },
    quoter: "Nqd6XqA8LbsCuG8MLWWuP865NV6jR1MbXeKxD4HLKDJ",
  },
  ArbitrumSepolia: {
    token: "0x87579Dc40781e99b870DDce46e93bd58A0e58Ae5",
    manager: "0xdA5a8e05e276AAaF4d79AB5b937a002E5221a4D8",
    transceiver: { wormhole: "0xd2940c256a3D887833D449eF357b6D639Cb98e12" },
  },
};

export const TEST_NTT_TOKENS: NttContracts = {
  Sepolia: {
    token: "0x738141EFf659625F2eAD4feECDfCD94155C67f18",
    manager: "0x06413c42e913327Bc9a08B7C1E362BAE7C0b9598",
    transceiver: { wormhole: "0x649fF7B32C2DE771043ea105c4aAb2D724497238" },
  },
  ArbitrumSepolia: {
    token: "0x395D3C74232D12916ecA8952BA352b4d27818035",
    manager: "0xCeC6FB4F352bf3DC2b95E1c41831E4D2DBF9a35D",
    transceiver: { wormhole: "0xfA42603152E4f133F5F3DA610CDa91dF5821d8bc" },
  },
  OptimismSepolia: {
    token: "0x1d30E78B7C7fbbcef87ae6e97B5389b2e470CA4a",
    manager: "0x27F9Fdd3eaD5aA9A5D827Ca860Be28442A1e7582",
    transceiver: { wormhole: "0xeCF0496DE01e9Aa4ADB50ae56dB550f52003bdB7" },
  },
  BaseSepolia: {
    token: "0xdDFeABcCf2063CD66f53a1218e23c681Ba6e7962",
    manager: "0x8b9E328bE1b1Bc7501B413d04EBF7479B110775c",
    transceiver: { wormhole: "0x149987472333cD48ac6D28293A338a1EEa6Be7EE" },
  },
  Solana: {
    token: "EetppHswYvV1jjRWoQKC1hejdeBDHR9NNzNtCyRQfrrQ",
    manager: "NTtAaoDJhkeHeaVUHnyhwbPNAN6WgBpHkHBTc6d7vLK",
    transceiver: { wormhole: "NTtAaoDJhkeHeaVUHnyhwbPNAN6WgBpHkHBTc6d7vLK" },
    quoter: "Nqd6XqA8LbsCuG8MLWWuP865NV6jR1MbXeKxD4HLKDJ",
  },
  Celo: {
    token: "0x5651b006Bc23054490483EF2C911eb62595c152b",
    manager: "0xFe756f2D911fA62F7F6703fB7BfA139B106A12c5",
    transceiver: { wormhole: "0x405a3fcfb4c86909eded67db3f05a73b15b25ea8" },
  },
  Fantom: {
    token: "0xf8a5d3c00b8f6cd93cef89d562baf82847bb9a86",
    manager: "0x9727d9fc676eba9b5322d41bd4d259d455013a3e",
    transceiver: { wormhole: "0xf6234aaa554437c780c992dCC4593A1Df30c0800" },
  }
};

// Reformat NTT contracts to fit TokenConfig for Route
function reformat(contracts: NttContracts) {
  return Object.entries(TEST_NTT_TOKENS).map(([chain, contracts]) => {
    const { token, manager, transceiver: xcvrs, quoter } = contracts;
    const transceiver = Object.entries(xcvrs).map(([k, v]) => {
      return { type: k as NttRoute.TransceiverType, address: v };
    });
    return { chain: chain as Chain, token, manager, quoter, transceiver };
  });
}

export const NttTokens = {
  Test: reformat(TEST_NTT_TOKENS),
};
