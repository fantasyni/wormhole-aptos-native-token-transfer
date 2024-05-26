import type {
  AccountAddress,
  Chain,
  ChainAddress,
  ChainsConfig,
  Contracts,
  Network,
  Platform,
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

import {
  SuiPlatform,
  SuiUnsignedTransaction,
  getPackageId,
  isSameType,
  uint8ArrayToBCS,
} from "@wormhole-foundation/sdk-sui";

import { SuiChains } from "@wormhole-foundation/sdk-sui";

import type { SuiClient } from "@mysten/sui.js/client";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { SUI_CLOCK_OBJECT_ID, SUI_TYPE_ARG  } from "@mysten/sui.js/utils";

import "@wormhole-foundation/sdk-sui-core";

export type SuiContracts = {
  stateObjectId: string;
  packageId: string;
  coreBridgeObjectId: string;
  coreBridgePackageId: string;
  coinType: string;
  adminCapObjectId: string;
  emitterCapId: string;
};

export class SuiNtt<N extends Network, C extends SuiChains> implements Ntt<N, C> {
  readonly chainId: bigint;
  stateObjectId: string;
  nttPackageId: string;
  coreBridgeObjectId: string;
  coreBridgePackageId: string;
  coinType: string;
  adminCapObjectId: string;

  constructor(
    readonly network: N,
    readonly chain: C,
    readonly provider: SuiClient,
    readonly contracts: Contracts & { ntt?: SuiContracts },
  ) {
    if (!contracts.ntt) throw new Error("No Ntt Contracts provided");

    this.chainId = nativeChainIds.networkChainToNativeChainId.get(network, chain) as bigint;
    this.stateObjectId = contracts.ntt.stateObjectId;
    this.nttPackageId = contracts.ntt.packageId;
    this.coreBridgeObjectId = contracts.ntt.coreBridgeObjectId;
    this.coreBridgePackageId = contracts.ntt.coreBridgePackageId;
    this.coinType = contracts.ntt.coinType;
    this.adminCapObjectId = contracts.ntt.adminCapObjectId;
  }

  static async fromRpc<N extends Network>(
    provider: SuiClient,
    config: ChainsConfig<N, Platform>,
  ): Promise<SuiNtt<N, SuiChains>> {
    const [network, chain] = await SuiPlatform.chainFromRpc(provider);

    const conf = config[chain]!;
    if (conf.network !== network)
      throw new Error(`Network mismatch: ${conf.network} != ${network}`);

    return new SuiNtt(network as N, chain, provider, conf.contracts);
  }

  async *setPeer(
    peer: ChainAddress<C>,
    tokenDecimals: number,
    inboundLimit: bigint
  ) {
    const tx = new TransactionBlock();
    const package_id = this.nttPackageId;
    var adminCapObjectId = this.adminCapObjectId;
    var peer_chain_id = toChainId(peer.chain);
    
    tx.moveCall({
      target: `${package_id}::setup::set_manager_peer`,
      arguments: [
        tx.object(adminCapObjectId), 
        tx.object(this.stateObjectId), 
        tx.pure(peer_chain_id), 
        tx.pure(uint8ArrayToBCS(peer.address.toUint8Array())), 
        tx.pure(tokenDecimals)],
    });

    yield this.createUnsignedTx(tx, "Sui.NTT.SetPeer");
  }

  async *setWormholeTransceiverPeer(peer: ChainAddress<C>) {
    const tx = new TransactionBlock();
    const package_id = this.nttPackageId;
    var adminCapObjectId = this.adminCapObjectId;
    var peer_chain_id = toChainId(peer.chain);

    tx.moveCall({
      target: `${package_id}::setup::set_transceiver_peer`,
      arguments: [
        tx.object(adminCapObjectId), 
        tx.object(this.stateObjectId), 
        tx.pure(peer_chain_id), 
        tx.pure(uint8ArrayToBCS(peer.address.toUint8Array()))],
    });

    yield this.createUnsignedTx(tx, "Sui.NTT.SetTransceiverPeer");
  }

  async *transfer(
    sender: AccountAddress<C>,
    amount: bigint,
    destination: ChainAddress,
    options: Ntt.TransferOptions
  ): AsyncGenerator<SuiUnsignedTransaction<N, C>> {
    const feeAmount = 0n;
    const nonce = 0;
    const senderAddress = sender.toString();

    const coinType = this.coinType;

    const coins = (
      await this.provider.getCoins({
        owner: senderAddress,
        coinType,
      })
    ).data;

    const [primaryCoin, ...mergeCoins] = coins.filter((coin) =>
      isSameType(coin.coinType, coinType),
    );
    if (primaryCoin === undefined)
      throw new Error(`Coins array doesn't contain any coins of type ${coinType}`);

    const tx = new TransactionBlock();
    
    const [transferCoin] = (() => {
      if (coinType === SUI_TYPE_ARG) {
        return tx.splitCoins(tx.gas, [tx.pure(amount)]);
      } else {
        const primaryCoinInput = tx.object(primaryCoin.coinObjectId);
        if (mergeCoins.length) {
          tx.mergeCoins(
            primaryCoinInput,
            mergeCoins.map((coin) => tx.object(coin.coinObjectId)),
          );
        }
        return tx.splitCoins(primaryCoinInput, [tx.pure(amount)]);
      }
    })();

    const [feeCoin] = tx.splitCoins(tx.gas, [tx.pure(feeAmount)]);
    const [assetInfo] = tx.moveCall({
      target: `${this.nttPackageId}::state::verified_asset`,
      arguments: [tx.object(this.stateObjectId)],
      typeArguments: [coinType],
    });

    const [transferTicket, dust] = tx.moveCall({
      target: `${this.nttPackageId}::ntt_manager::prepare_transfer`,
      arguments: [
        tx.object(this.stateObjectId),
        assetInfo!,
        transferCoin!,
        tx.pure(toChainId(destination.chain)),
        tx.pure(uint8ArrayToBCS(destination.address.toUint8Array())),
        tx.pure(nonce),
      ],
      typeArguments: [coinType],
    });

    tx.moveCall({
      target: `${this.nttPackageId}::coin_utils::return_nonzero`,
      arguments: [dust!],
      typeArguments: [coinType],
    });

    const [messageTicket] = tx.moveCall({
      target: `${this.nttPackageId}::ntt_manager::transfer_tokens`,
      arguments: [tx.object(this.stateObjectId), transferTicket!],
      typeArguments: [coinType],
    });

    tx.moveCall({
      target: `${this.coreBridgePackageId}::publish_message::publish_message`,
      arguments: [
        tx.object(this.coreBridgeObjectId),
        feeCoin!,
        messageTicket!,
        tx.object(SUI_CLOCK_OBJECT_ID),
      ],
    });

    yield this.createUnsignedTx(tx, "Sui.NTT.Transfer");
  }

  async *redeem(attestations: Ntt.Attestation[]) {
    const wormholeNTT = attestations[0]! as WormholeNttTransceiver.VAA;

    const tx = new TransactionBlock();
    const [verifiedVAA] = tx.moveCall({
      target: `${this.coreBridgePackageId}::vaa::parse_and_verify`,
      arguments: [
        tx.object(this.coreBridgeObjectId),
        tx.pure(uint8ArrayToBCS(serialize(wormholeNTT))),
        tx.object(SUI_CLOCK_OBJECT_ID),
      ],
    });

    const [nttTransceiverMessage] = tx.moveCall({
      target: `${this.nttPackageId}::ntt_transceiver::verify_only_once`,
      arguments: [tx.object(this.stateObjectId), verifiedVAA!],
    });

    tx.moveCall({
      target: `${this.nttPackageId}::ntt_transceiver::redeem`,
      arguments: [tx.object(this.stateObjectId), nttTransceiverMessage!],
      typeArguments: [this.coinType!],
    });

    yield this.createUnsignedTx(tx, "Sui.NTT.Redeem");
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

  async getNttPackageId(): Promise<string> {
    if (!this.nttPackageId) {
      this.nttPackageId = await getPackageId(this.provider, this.stateObjectId);
    }

    return this.nttPackageId;
  }

  private createUnsignedTx(
    txReq: TransactionBlock,
    description: string,
    parallelizable: boolean = false,
  ): SuiUnsignedTransaction<N, C> {
    return new SuiUnsignedTransaction(txReq, this.network, this.chain, description, parallelizable);
  }
}
