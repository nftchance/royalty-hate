// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {RoyaltyHateHelpers} from "../lib/RoyaltyHateHelpers.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {RoyaltyHateTransfers} from "../lib/RoyaltyHateTransfers.sol";
import {ERC721} from "solady/src/tokens/ERC721.sol";

contract RoyaltyHateBasket is RoyaltyHateTransfers, ERC721 {
    using Strings for uint256;

    /// @notice The next token id to mint.
    uint256 internal tokenId;

    /// @dev The baskets of assets held relative to each token id.
    mapping(uint256 => RoyaltyHateHelpers.RoyaltyHateDetails)
        public tokenIdToHateDetails;

    constructor() ERC721() {}

    /// @dev Wrap the tokens and make a basket.
    /// @param $hateDetails The details of the hate.
    function make(
        address $receiver,
        RoyaltyHateHelpers.RoyaltyHateDetails memory $hateDetails
    ) external payable {
        /// @dev Make sure that the value is correct.
        require(
            msg.value == $hateDetails.value,
            "RoyaltyHateBasket: msg.value != hateDetails.value"
        );

        /// @dev Transfer all of the assets to this contract
        /// @notice (ERC20 & ERC721 & ERC1155).
        _transferFrom(msg.sender, address(this), $hateDetails);

        /// @dev Record the details of the hate.
        tokenIdToHateDetails[tokenId] = $hateDetails;

        /// @dev Mint the token ownership of the basket.
        _safeMint($receiver, tokenId++);
    }

    /// @dev Unwrap the tokens and take the assets.
    /// @param $receiver The receiver of the token.
    /// @param $tokenId The token id of the basket token to unwrap.
    function take(address $receiver, uint256 $tokenId) external {
        /// @dev Burn the token being unwrapped.
        _burn(msg.sender, $tokenId);

        /// @dev Retrieve the details of the hate.
        RoyaltyHateHelpers.RoyaltyHateDetails
            memory hateDetails = tokenIdToHateDetails[$tokenId];

        /// @dev Delete the storage reference of the hate details.
        delete tokenIdToHateDetails[$tokenId];

        /// @dev Transfer all of the assets to the receiver
        uint256 value = hateDetails.value;
        if (value > 0) _transferETH($receiver, value);

        /// @notice (ERC20 & ERC721 & ERC1155).
        _transferFrom(address(this), $receiver, hateDetails);
    }

    /// @dev Wrap and serve the name of the underlying token.
    function name() public view virtual override returns (string memory) {
        return "Royalty Hate: Basket";
    }

    /// @dev Wrap and serve the symbol of the underlying token.
    function symbol() public view virtual override returns (string memory) {
        return "RHATEB";
    }

    /// @dev Serve the existing tokenURI of the underlying token.
    /// @param $tokenId The token id of the token.
    function tokenURI(
        uint256 $tokenId
    ) public view virtual override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Royalty Hate: Basket #',
                                Strings.toString($tokenId),
                                '","description":"A basket of tokens (ETH & ERC20 & ERC1155 & ERC721) bypassing royalty enforcement.","image":"data:image/svg+xml;base64,',
                                Base64.encode(
                                    bytes(
                                        string(
                                            abi.encodePacked(
                                                "<svg xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 350 350'><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width='100%' height='100%' fill='black' />",
                                                string(
                                                    abi.encodePacked(
                                                        "<text x='50%' y='50%' dominant-baseline='middle' text-anchor='middle'>Basket #",
                                                        Strings.toString(
                                                            $tokenId
                                                        ),
                                                        "</text>"
                                                    )
                                                ),
                                                "</svg>"
                                            )
                                        )
                                    )
                                ),
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}
