// SPDX-License-Identifier: Apache 2
pragma solidity >=0.8.8 <0.9.0;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/Script.sol";

import {ERC1967Proxy} from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {JustinToken} from "../src/mocks/JustinToken.sol";

contract DeployJustinToken is Script {
    function run() public {
        vm.startBroadcast();

        JustinToken implementation = new JustinToken();

        JustinToken justinTokenProxy =
            JustinToken(address(new ERC1967Proxy(address(implementation), "")));

        vm.stopBroadcast();
    }
}
