import type {
  AccountAddress,
  Chain,
  ChainAddress,
  ChainsConfig,
  Contracts,
  Network,
  TokenAddress,
  UnsignedTransaction
} from "@wormhole-foundation/sdk-connect";

import {
  nativeChainIds,
  serialize,
  toChainId,
} from "@wormhole-foundation/sdk-connect";

import {
  Ntt,
  WormholeNttTransceiver,
} from "@wormhole-foundation/sdk-definitions-ntt";

import type {
  AptosChains,
  AptosPlatformType,
} from "@wormhole-foundation/sdk-aptos";
import {
  AptosPlatform,
  AptosUnsignedTransaction,
} from "@wormhole-foundation/sdk-aptos";
import type { AptosClient, Types } from "aptos";

import "@wormhole-foundation/sdk-aptos-core";

export type AptosContracts = {
  packageId: string;
  tokenType: string;
};

export class AptosNtt<N extends Network, C extends AptosChains> implements Ntt<N, C> {
  readonly chainId: bigint;
  nttPackageId: string;
  tokenType: string;

  constructor(
    readonly network: N,
    readonly chain: C,
    readonly connection: AptosClient,
    readonly contracts: Contracts & { ntt?: AptosContracts },
  ) {
    if (!contracts.ntt) throw new Error("No Ntt Contracts provided");

    this.chainId = nativeChainIds.networkChainToNativeChainId.get(network, chain) as bigint;
    this.nttPackageId = contracts.ntt.packageId;
    this.tokenType = contracts.ntt.tokenType;
  }

  static async fromRpc<N extends Network>(
    connection: AptosClient,
    config: ChainsConfig<N, AptosPlatformType>,
  ): Promise<AptosNtt<N, AptosChains>> {
    const [network, chain] = await AptosPlatform.chainFromRpc(connection);
    const conf = config[chain]!;
    if (conf.network !== network)
      throw new Error("Network mismatch " + conf.network + " !== " + network);
    return new AptosNtt(network as N, chain, connection, conf.contracts);
  }

  async *transfer(
    sender: AccountAddress<C>,
    amount: bigint,
    destination: ChainAddress,
    options: Ntt.TransferOptions
  ): AsyncGenerator<AptosUnsignedTransaction<N, C>> {

    const nonce = 0n;
    const dstAddress = destination.address.toUniversalAddress().toUint8Array();
    const dstChain = toChainId(destination.chain);

    yield this.createUnsignedTx(
      {
        function: `${this.nttPackageId}::ntt_manager::transfer_tokens`,
        type_arguments: [this.tokenType],
        arguments: [amount, dstChain, dstAddress, nonce],
      },
      "Aptos.transfer",
    );
  }

  async *redeem(attestations: Ntt.Attestation[]) {
    const wormholeNTT = attestations[0]! as WormholeNttTransceiver.VAA;
    const vaa = serialize(wormholeNTT);

    yield this.createUnsignedTx(
      {
        function: `${this.nttPackageId}::ntt_transceiver::submit_vaa`,
        type_arguments: [this.tokenType],
        arguments: [vaa],
      },
      "Aptos.redeem",
    );
  }

  async *setPeer(
    peer: ChainAddress<C>,
    tokenDecimals: number,
    inboundLimit: bigint
  ) {

  }

  async *setWormholeTransceiverPeer(peer: ChainAddress<C>) {

  }

  async *transfer_nft(
    sender: AccountAddress<C>,
    token_ids: number[],
    token_id_width: number,
    destination: ChainAddress,
    options: Ntt.TransferOptions
  ): AsyncGenerator<AptosUnsignedTransaction<N, C>> {
  }

  isRelayingAvailable(
    destination: Chain
  ): Promise<boolean> {
    throw new Error("Method not implemented.");
  }

  quoteDeliveryPrice(
    destination: Chain,
    options: Ntt.TransferOptions
  ): Promise<bigint> {
    throw new Error("Method not implemented.");
  }

  getVersion(
    payer?: AccountAddress<C> | undefined
  ): Promise<string> {
    throw new Error("Method not implemented.");
  }

  getCustodyAddress(): Promise<string> {
    throw new Error("Method not implemented.");
  }

  getTokenDecimals(): Promise<number> {
    throw new Error("Method not implemented.");
  }

  getCurrentOutboundCapacity(): Promise<bigint> {
    throw new Error("Method not implemented.");
  }

  getCurrentInboundCapacity(fromChain: Chain): Promise<bigint> {
    throw new Error("Method not implemented.");
  }

  getIsApproved(attestation: any): Promise<boolean> {
    throw new Error("Method not implemented.");
  }

  getIsExecuted(attestation: any): Promise<boolean> {
    throw new Error("Method not implemented.");
  }

  getInboundQueuedTransfer(
    fromChain: Chain,
    transceiverMessage: Ntt.Message
  ): Promise<Ntt.InboundQueuedTransfer<C> | null> {
    throw new Error("Method not implemented.");
  }

  completeInboundQueuedTransfer(
    fromChain: Chain,
    transceiverMessage: Ntt.Message,
    token: TokenAddress<C>, payer?: AccountAddress<C> | undefined
  ): AsyncGenerator<UnsignedTransaction<N, C>, any, unknown> {
    throw new Error("Method not implemented.");
  }

  private createUnsignedTx(
    txReq: Types.EntryFunctionPayload,
    description: string,
    parallelizable: boolean = false,
  ): AptosUnsignedTransaction<N, C> {
    return new AptosUnsignedTransaction(
      txReq,
      this.network,
      this.chain,
      description,
      parallelizable,
    );
  }
}
