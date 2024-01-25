// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

library RoyaltyHateHelpers {
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
        MakerRoyaltyHateDetails details
    );

    event RecoverRoyaltyHate(
        address indexed taker,
        MakerRoyaltyHateDetails details
    );
}
