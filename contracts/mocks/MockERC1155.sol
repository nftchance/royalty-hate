// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {ERC1155} from "solady/src/tokens/ERC1155.sol";

contract MockERC1155 is ERC1155 {
    constructor() ERC1155() {}

    function mint(address to, uint256 tokenId, uint256 amount) external {
        _mint(to, tokenId, amount, "");
    }

    function uri(uint256) public pure virtual override returns (string memory) {
        return "MockERC1155";
    }
}
