// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {ERC721} from "solady/src/tokens/ERC721.sol";

contract MockERC721 is ERC721 {
    constructor() ERC721() {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }

    function name() public pure virtual override returns (string memory) {
        return "MockERC721";
    }

    function symbol() public pure virtual override returns (string memory) {
        return "MOCK";
    }

    function tokenURI(
        uint256
    ) public pure virtual override returns (string memory) {
        return "MockERC721";
    }
}
