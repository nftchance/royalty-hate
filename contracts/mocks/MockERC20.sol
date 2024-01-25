// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {ERC20} from "solady/src/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20() {}

    function mint(address $to, uint256 $amount) external {
        _mint($to, $amount);
    }

    function name() public pure override returns (string memory) {
        return "MockERC20";
    }

    function symbol() public pure override returns (string memory) {
        return "MERC20";
    }
}
