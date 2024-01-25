// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {RoyaltyHateHelpers} from "./RoyaltyHateHelpers.sol";

import {ERC20} from "solady/src/tokens/ERC20.sol";
import {ERC721} from "solady/src/tokens/ERC721.sol";
import {ERC1155} from "solady/src/tokens/ERC1155.sol";

contract RoyaltyHateTransfers {
    /// @notice Transfer ETH to a receiver from this contract.
    /// @param $receiver The receiver of the ETH.
    /// @param $amount The amount of ETH to transfer.
    function _transferETH(address $receiver, uint256 $amount) internal {
        (bool success, ) = $receiver.call{value: $amount}("");
        require(success, "RoyaltyHate: ETH transfer failed");
    }

    /// @notice Transfer fungible and non-fungible assets to a receiver.
    /// @param $receiver The receiver of the assets.
    /// @param $receiver The receiver of the assets.
    /// @param $hateDetails The details of the hate.
    function _transferFrom(
        address $sender,
        address $receiver,
        RoyaltyHateHelpers.RoyaltyHateDetails memory $hateDetails
    ) internal {
        for (uint256 i; i < $hateDetails.erc20.tokenAddresses.length; i++) {
            if($sender == address(this)) {
                ERC20($hateDetails.erc20.tokenAddresses[i]).transfer(
                    $receiver,
                    $hateDetails.erc20.amounts[i]
                );
            } else {
                ERC20($hateDetails.erc20.tokenAddresses[i]).transferFrom(
                    $sender,
                    $receiver,
                    $hateDetails.erc20.amounts[i]
                );
            }
        }

        for (uint256 i; i < $hateDetails.erc721.ids.length; i++) {
            ERC721($hateDetails.erc721.tokenAddress).safeTransferFrom(
                $sender,
                $receiver,
                $hateDetails.erc721.ids[i]
            );
        }

        for (uint256 i; i < $hateDetails.erc1155.ids.length; i++) {
            ERC1155($hateDetails.erc1155.tokenAddress).safeTransferFrom(
                $sender,
                $receiver,
                $hateDetails.erc1155.ids[i],
                $hateDetails.erc1155.amounts[i],
                ""
            );
        }
    }

    /// @notice Confirm the receipt of an 1155 transfer.
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @notice Confirm the receipt of an 1155 batch transfer.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /// @notice Confirm the receipt of an 721 transfer.
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
