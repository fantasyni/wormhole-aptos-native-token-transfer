// SPDX-License-Identifier: Apache 2

pragma solidity >=0.8.8 <0.9.0;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

contract JustinToken is ERC20, ERC1967Upgrade {
    constructor() ERC20("JustinToken", "Justin") {}

    function mint(address to, uint256 amount) public virtual {
        _mint(to, amount);
    }

    function burnFrom(address, uint256) public virtual {
        revert("No nttManager should call 'burnFrom()'");
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function upgrade(address newImplementation) public {
        _upgradeTo(newImplementation);
    }
}