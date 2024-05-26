import { registerProtocol } from "@wormhole-foundation/sdk-connect";
import { _platform } from "@wormhole-foundation/sdk-sui";
import { SuiNtt } from "./ntt.js";
import "@wormhole-foundation/sdk-definitions-ntt";

registerProtocol(_platform, "Ntt", SuiNtt);

export * from "./ntt.js";
