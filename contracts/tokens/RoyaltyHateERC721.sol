// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";

import {ERC721} from "solady/src/tokens/ERC721.sol";

contract RoyaltyHateERC721 is ERC721, ReentrancyGuard {
    /// @notice The underlying token.
    ERC721 public immutable underlying;

    /// @dev Initialize the contract with the underlying asset.
    constructor(address $underlying) ERC721() {
        underlying = ERC721($underlying);
    }

    /// @dev Wrap the tokens.
    /// @param $receiver The receiver of the token.
    /// @param $tokenIds The token ids of the token to wrap.
    function make(
        address $receiver,
        uint256[] memory $tokenIds
    ) external virtual nonReentrant {
        for (uint256 i; i < $tokenIds.length; i++) {
            uint256 tokenId = $tokenIds[i];

            /// @dev Transfer the token being wrapped to this contract.
            underlying.safeTransferFrom(msg.sender, address(this), tokenId);

            /// @dev Mint the token to the receiver.
            _safeMint($receiver, tokenId);
        }
    }

    /// @dev Unwrap the tokens.
    /// @param $receiver The receiver of the token.
    /// @param $tokenIds The token ids of the token to unwrap.
    function take(
        address $receiver,
        uint256[] memory $tokenIds
    ) external virtual nonReentrant {
        for (uint256 i; i < $tokenIds.length; i++) {
            uint256 tokenId = $tokenIds[i];

            /// @dev Burn the token being unwrapped.
            _burn(msg.sender, tokenId);

            /// @dev Transfer the token being unwrapped to the receiver.
            underlying.safeTransferFrom(address(this), $receiver, tokenId);
        }
    }

    /// @dev Confirm the receipt of a 721 transfer.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @dev Wrap and serve the name of the underlying token.
    function name() public view virtual override returns (string memory) {
        return string(abi.encodePacked("Royalty Hate: ", underlying.name()));
    }

    /// @dev Wrap and serve the symbol of the underlying token.
    function symbol() public view virtual override returns (string memory) {
        return string(abi.encodePacked("RH", underlying.symbol()));
    }

    /// @dev Serve the existing tokenURI of the underlying token.
    /// @param $tokenId The token id of the token.
    function tokenURI(
        uint256 $tokenId
    ) public view virtual override returns (string memory) {
        return underlying.tokenURI($tokenId);
    }
}
