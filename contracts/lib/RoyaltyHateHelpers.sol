// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

library RoyaltyHateHelpers {
    /// @notice The address of the router.
    address internal constant ROUTER = 0x00000000002Fd5Aeb385D324B580FCa7c83823A0;
    
    enum RoyaltyHateState {
        made, 
        cancelled, 
        taking, 
        taken
    }

    struct ERC20Details {
        address[] tokenAddresses;
        uint256[] amounts;
    }

    struct ERC721Details {
        address tokenAddress;
        address[] to;
        uint256[] ids;
    }

    struct ERC1155Details {
        address tokenAddress;
        uint256[] ids;
        uint256[] amounts;
    }

    struct RoyaltyHateDetails { 
        ERC20Details erc20;
        ERC721Details erc721;
        ERC1155Details erc1155;
        uint256 value;
    }

    struct RoyaltyHateRecoveryDetails { 
        address maker;
        address taker;
    }

    struct MakerRoyaltyHateDetails { 
        address taker;
        uint32 expiration;
        uint32 nonce;
        RoyaltyHateState state;
        RoyaltyHateDetails makerDetails;
        RoyaltyHateDetails takerDetails;
        RoyaltyHateRecoveryDetails recoveryDetails;
    }

    event MakeRoyaltyHate(
        address indexed maker,
        MakerRoyaltyHateDetails details
    );

    event TakingRoyaltyHate(
        address indexed maker,
        address indexed taker,
        MakerRoyaltyHateDetails details
    );

    event TakeRoyaltyHate(
        address indexed maker,
        address indexed taker,
        RoyaltyHateDetails details
    );

    /// @notice Recover the sender from the multicaller, otherwise use the sender.
    /// @dev Yoinked from https://github.com/Vectorized/multicaller/blob/main/src/LibMulticaller.sol#L63-L80
    function sender() internal view returns (address result) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, caller())
            let withSender := ROUTER
            if eq(caller(), withSender) {
                if iszero(staticcall(gas(), withSender, codesize(), 0x00, 0x00, 0x20)) {
                    revert(codesize(), codesize()) // For better gas estimation.
                }
            }
            result := mload(0x00)
        }
    }
}
