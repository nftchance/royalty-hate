// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import { MulticallerWithSender } from "multicaller/src/MulticallerWithSender.sol";
import { Ownable } from "solady/src/auth/Ownable.sol";

contract RoyaltyHateRouter is MulticallerWithSender, Ownable {
    constructor() MulticallerWithSender() { } 

    /// @notice The name of the contract.
    function name() external pure returns (string memory) { 
        return "RoyaltyHate";
    }

    /// @notice The symbol of the contract.
    function symbol() external pure returns (string memory) { 
        return "RHATE";
    }

    /// @notice Execute a call to the contract as the owner.
    function execute(
        address $to, 
        uint256 $value, 
        bytes memory $data
    ) external onlyOwner { 
        (bool success, ) = $to.call{value: $value}($data);
        require(success, "RoyaltyHate: execute failed");
    }
}