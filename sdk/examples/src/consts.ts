import { Chain } from "@wormhole-foundation/sdk";
import { Ntt } from "@wormhole-foundation/sdk-definitions-ntt";
import { NttRoute } from "@wormhole-foundation/sdk-route-ntt";
import { SuiContracts } from "@wormhole-foundation/sdk-sui-ntt";
import { AptosContracts } from "@wormhole-foundation/sdk-aptos-ntt";

type NttContracts = {
  [key in Chain]?: Ntt.Contracts;
};

export const SUI_NTT_CONTRACTS: SuiContracts = {
  stateObjectId: "0x2bbbc8a3c3a4aa922515c76b75559d3e1cb1d1d3c03550bd27ddaba0ba923506",
  packageId: "0x8d143847d58cdd495b886e04f1a69d98f67b70c9cb0bcc96e76ac6ef71900041",
  coreBridgeObjectId: "0x31358d198147da50db32eda2562951d53973a0c0ad5ed738e9b17d88b213d790",
  coreBridgePackageId: "0xf47329f4344f3bf0f8e436e2f7b485466cff300f12a166563995d3888c296a94",
  tokenType: "0x76388c6a660c9662aaaa7d950cfbb15e0472a7e60f6c09f7bbf6e3363f045237::justin_coin::JUSTIN_COIN",
  adminCapObjectId: "0xb4721d5a0b5ee7c4c182b1b93c81b9b05e0e06532136f92080f7e025f4a30978",
  emitterCapId: "0x1da0ee1573ccd4232765c16b9e1a61d898477cadec8b41e2173b812a5b115d55",
  nftType: "",
}

export const APTOS_NTT_CONTRACTS: AptosContracts = {
  packageId: "0x2b76176b725bca5b8894244e23da1fd8b739f79b767b4fc6884ac6ba66ebc5dc",
  tokenType: "0x9b2916b5f46b5600d72c3a32624794d05bbad5e50de62853baeaad97887c386d::justin_coin::JustinCoin"
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
    token: "0xf85e513341444c6cb1a5b05f788bfe3cc17e2ce9",
    manager: "0x04b05134353c0150498d851c3d1a196ddd4a2a5a",
    transceiver: { wormhole: "0x16cf26bdd9d31f7337d72a42a696861364244431" },
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
