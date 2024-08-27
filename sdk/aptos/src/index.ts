import { registerProtocol } from "@wormhole-foundation/sdk-connect";
import { _platform } from "@wormhole-foundation/sdk-aptos";
import { AptosNtt } from "./ntt.js";
import "@wormhole-foundation/sdk-definitions-ntt";

registerProtocol(_platform, "Ntt", AptosNtt);

export * from "./ntt.js";
