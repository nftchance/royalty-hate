// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";

import {ERC1155} from "solady/src/tokens/ERC1155.sol";

contract RoyaltyHateERC1155 is ERC1155, ReentrancyGuard {
    /// @notice The underlying token.
    ERC1155 public immutable underlying;

    /// @dev Initialize the contract with the underlying asset.
    constructor(address $underlying) ERC1155() {
        underlying = ERC1155($underlying);
    }

    /// @dev Wrap the tokens.
    /// @param $receiver The receiver of the token.
    /// @param $tokenIds The token ids of the tokens to wrap.
    /// @param $amounts The amounts of each token to wrap.
    function make(
        address $receiver,
        uint256[] memory $tokenIds,
        uint256[] memory $amounts
    ) external virtual nonReentrant {
        /// @dev Make sure the token ids and amounts are the same length.
        require(
            $tokenIds.length == $amounts.length,
            "RoyaltyHateERC1155: tokenIds.length != amounts.length"
        );

        for (uint256 i; i < $tokenIds.length; i++) {
            uint256 tokenId = $tokenIds[i];
            uint256 amount = $amounts[i];

            /// @dev Transfer the tokens being wrapped to this contract.
            underlying.safeTransferFrom(
                msg.sender,
                address(this),
                tokenId,
                amount,
                ""
            );

            /// @dev Mint the tokens to the receiver.
            _mint($receiver, tokenId, amount, "");
        }
    }

    /// @dev Unwrap the tokens.
    /// @param $receiver The receiver of the token.
    /// @param $tokenIds The token ids of the tokens to unwrap.
    /// @param $amounts The amounts of each token to unwrap.
    function take(
        address $receiver,
        uint256[] memory $tokenIds,
        uint256[] memory $amounts
    ) external virtual nonReentrant {
        /// @dev Make sure the token ids and amounts are the same length.
        require(
            $tokenIds.length == $amounts.length,
            "RoyaltyHateERC1155: tokenIds.length != amounts.length"
        );

        for (uint256 i; i < $tokenIds.length; i++) {
            uint256 tokenId = $tokenIds[i];
            uint256 amount = $amounts[i];

            /// @dev Burn the tokens being unwrapped.
            _burn(msg.sender, tokenId, amount);

            /// @dev Transfer the tokens being unwrapped to the receiver.
            underlying.safeTransferFrom(
                address(this),
                $receiver,
                tokenId,
                amount,
                ""
            );
        }
    }

    /// @dev Handle the receipt of a single ERC1155 tokens.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev Handle the receipt of multiple ERC1155 tokens.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @dev Wrap and serve the URI of the underlying token.
    /// @param $tokenId The token id of the token.
    function uri(
        uint256 $tokenId
    ) public view virtual override returns (string memory) {
        return underlying.uri($tokenId);
    }
}
