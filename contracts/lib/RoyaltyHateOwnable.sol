// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {Ownable} from "solady/src/auth/Ownable.sol";

contract RoyaltyHateOwnable is Ownable {
    /// @notice The open state of the contract.
    bool public open;

    constructor() Ownable() {
        /// @dev Set the ownership of the protocol.
        _initializeOwner(msg.sender);

        /// @dev Set the protocol as open.
        open = true;
    }

    /// @notice Modifier to check if the contract is open.
    modifier isOpen() {
        require(open, "RoyaltyHate: not open");
        _;
    }

    /// @notice Set the open state of the contract.
    /// @param $open The open state of the contract
    function setOpen(bool $open) external onlyOwner {
        open = $open;
    }
}
