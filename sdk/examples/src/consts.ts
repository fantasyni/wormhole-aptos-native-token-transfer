import { Chain } from "@wormhole-foundation/sdk";
import { Ntt } from "@wormhole-foundation/sdk-definitions-ntt";
import { NttRoute } from "@wormhole-foundation/sdk-route-ntt";
import { SuiContracts } from "@wormhole-foundation/sdk-sui-ntt";

type NttContracts = {
  [key in Chain]?: Ntt.Contracts;
};

export const SUI_NTT_CONTRACTS: SuiContracts = {
  stateObjectId: "0x0ba804ae497349ae5a5c797a070e990a3960882472eba8faa9f248103c45b598",
  packageId: "0x408be43f5d9f173fcdda13d1ffef24bc9fc7fe553698616a09277855c5c5a030",
  coreBridgeObjectId: "0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790",
  coreBridgePackageId: "0xf47329f4344f3bf0f8e436e2f7b485466cff300f12a166563995d3888c296a94",
  coinType: "0x6a047dba20efbc109e882c1972500d08d91c9b52186a39c3cb664d1d0a149112::justin_coin::JUSTIN_COIN",
  adminCapObjectId: "0x44e94a2184aaa0c29767cd9a04872c278e146012e9959247286fb6cbbcadd2df",
  emitterCapId: "0xf1d11d19df22e3f37f885e2b030c83ef1690edff25a8397923f21ca3f62788bc",
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
