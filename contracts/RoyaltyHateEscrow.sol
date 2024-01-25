// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.20;

import {RoyaltyHateHelpers} from "./lib/RoyaltyHateHelpers.sol";

import {RoyaltyHateTransfers} from "./lib/RoyaltyHateTransfers.sol";
import {RoyaltyHateOwnable} from "./lib/RoyaltyHateOwnable.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";

contract RoyaltyHateEscrow is
    RoyaltyHateTransfers,
    RoyaltyHateOwnable,
    ReentrancyGuard
{
    /// @notice The nonce the makers.
    mapping(address => uint32) public addressToNonce;

    /// @notice Order details that have been made.
    mapping(address => mapping(uint32 => RoyaltyHateHelpers.MakerRoyaltyHateDetails))
        public addressToNonceToHateDetails;

    constructor() RoyaltyHateOwnable() {}

    /// @notice Allows the maker to make an order.
    /// @param $hateDetails The details of the hate.
    function make(
        RoyaltyHateHelpers.MakerRoyaltyHateDetails memory $hateDetails
    ) external payable isOpen nonReentrant {
        /// @dev Make sure that the expiration is in the future.
        require(
            $hateDetails.expiration > block.timestamp,
            "RoyaltyHate: hateDetails.expiration <= block.timestamp"
        );

        /// @dev Make sure that the nonce is correct.
        uint32 nonce = addressToNonce[msg.sender]++;
        require(
            $hateDetails.nonce == nonce,
            "RoyaltyHate: hateDetails.nonce != nonce"
        );

        /// @dev Make sure the order is ready to be made.
        $hateDetails.state = RoyaltyHateHelpers.RoyaltyHateState.made;

        /// @dev Make sure an invalid recovery state is not provided.
        $hateDetails.recoveryDetails = RoyaltyHateHelpers
            .RoyaltyHateRecoveryDetails({maker: address(0), taker: address(0)});

        /// @dev Make sure that the value is correct.
        require(
            $hateDetails.makerDetails.value == msg.value,
            "RoyaltyHate: msg.value != makerHateDetails.value"
        );

        /// @dev Transfer all of the assets to this contract
        /// @notice (ERC20 & ERC721 & ERC1155).
        _transferFrom(msg.sender, address(this), $hateDetails.makerDetails);

        /// @dev Record the details of the hate.
        addressToNonceToHateDetails[msg.sender][nonce] = $hateDetails;

        /// @dev Announce the event for the indexer.
        emit RoyaltyHateHelpers.MakeRoyaltyHate(msg.sender, $hateDetails);
    }

    /// @notice Allows the maker to cancel an order that is being made.
    /// @param $nonce The nonce of the maker.
    function cancel(uint32 $nonce) external {
        RoyaltyHateHelpers.MakerRoyaltyHateDetails
            storage hateDetails = addressToNonceToHateDetails[msg.sender][
                $nonce
            ];

        /// @dev Make sure that the hate is not expired.
        require(
            hateDetails.expiration > block.timestamp,
            "RoyaltyHate: hateDetails.expiration <= block.timestamp"
        );

        /// @dev Make sure that the order is still active.
        require(
            hateDetails.state == RoyaltyHateHelpers.RoyaltyHateState.made,
            "RoyaltyHate: hateDetails.state != made"
        );

        /// @dev Mark the order as cancelled.
        hateDetails.state = RoyaltyHateHelpers.RoyaltyHateState.cancelled;

        /// @dev Transfer the assets back to the maker.
        uint256 value = hateDetails.makerDetails.value;
        if (value > 0) _transferETH(msg.sender, value);

        _transferFrom(address(this), msg.sender, hateDetails.makerDetails);
    }

    /// @notice Allows the taker to take an order that is being made.
    /// @param $maker The address of the maker.
    /// @param $nonce The nonce of the maker.
    function taking(
        address $maker,
        uint32 $nonce
    ) external payable isOpen nonReentrant {
        RoyaltyHateHelpers.MakerRoyaltyHateDetails
            storage hateDetails = addressToNonceToHateDetails[$maker][$nonce];

        /// @dev Make sure the taker is valid.
        require(
            hateDetails.taker == msg.sender || hateDetails.taker == address(0),
            "RoyaltyHate: hateDetails.taker != msg.sender && hateDetails.taker != address(0)"
        );

        /// @dev Make sure that the hate is not expired.
        require(
            hateDetails.expiration > block.timestamp,
            "RoyaltyHate: hateDetails.expiration <= block.timestamp"
        );

        /// @dev Make sure that the order is still active.
        require(
            hateDetails.state == RoyaltyHateHelpers.RoyaltyHateState.made,
            "RoyaltyHate: hateDetails.state != made"
        );

        /// @dev Make sure that the value is correct.
        require(
            hateDetails.takerDetails.value == msg.value,
            "RoyaltyHate: msg.value != makerHateDetails.value"
        );

        /// @dev Record the details of the hate.
        hateDetails.taker = msg.sender;
        hateDetails.state = RoyaltyHateHelpers.RoyaltyHateState.taking;

        /// @dev Transfer all of the assets to this contract.
        /// @notice (ERC20 & ERC721 & ERC1155).
        _transferFrom(msg.sender, address(this), hateDetails.takerDetails);

        /// @dev Announce the event for the indexer.
        emit RoyaltyHateHelpers.TakingRoyaltyHate(
            $maker,
            msg.sender,
            hateDetails
        );
    }

    /// @notice Fulfills an order that is being taken and transfers assets where they belong.
    /// @param $maker The address of the maker.
    /// @param $nonce The nonce of the maker.
    function take(address $maker, uint32 $nonce) external isOpen nonReentrant {
        RoyaltyHateHelpers.MakerRoyaltyHateDetails
            storage hateDetails = addressToNonceToHateDetails[$maker][$nonce];

        /// @dev Make sure that the order is still active.
        require(
            hateDetails.state == RoyaltyHateHelpers.RoyaltyHateState.taking,
            "RoyaltyHate: hateDetails.state != taking"
        );

        /// @dev Make sure that the hate is not expired.
        require(
            hateDetails.expiration > block.timestamp,
            "RoyaltyHate: hateDetails.expiration <= block.timestamp"
        );

        /// @dev Mark the order as taken.
        hateDetails.state = RoyaltyHateHelpers.RoyaltyHateState.taken;

        uint256 value = hateDetails.takerDetails.value;

        /// @dev Transfer the traded assets to the maker.
        if (value > 0) _transferETH($maker, value);
        _transferFrom(address(this), $maker, hateDetails.takerDetails);

        value = hateDetails.makerDetails.value;

        /// @dev Transfer the traded assets to the taker.
        if (value > 0) _transferETH(hateDetails.taker, value);
        _transferFrom(
            address(this),
            hateDetails.taker,
            hateDetails.makerDetails
        );

        /// @dev Announce the event for the indexer.
        emit RoyaltyHateHelpers.TakeRoyaltyHate(
            $maker,
            hateDetails.taker,
            hateDetails
        );
    }

    /// @notice Allows the recovery of assets when a party that did not fulfill their end of
    ///         the trade by breaking the transferability of the assets.
    /// @param $maker The address of the maker.
    /// @param $nonce The nonce of the maker.
    function recover(address $maker, uint32 $nonce) external nonReentrant {
        RoyaltyHateHelpers.MakerRoyaltyHateDetails
            storage hateDetails = addressToNonceToHateDetails[$maker][$nonce];

        /// @dev Make sure that the order got stuck in the taking phase.
        require(
            hateDetails.state == RoyaltyHateHelpers.RoyaltyHateState.taking,
            "RoyaltyHate: hateDetails.state != taking"
        );

        /// @dev Make sure that the hate is expired.
        require(
            hateDetails.expiration <= block.timestamp,
            "RoyaltyHate: hateDetails.expiration >= block.timestamp"
        );

        RoyaltyHateHelpers.RoyaltyHateRecoveryDetails
            storage hateRecoveryDetails = addressToNonceToHateDetails[$maker][
                $nonce
            ].recoveryDetails;

        /// @dev Allow a maker to recover their assets.
        if (msg.sender == $maker) {
            /// @dev Make sure the maker hasn't already recovered.
            require(
                hateRecoveryDetails.maker == address(0),
                "RoyaltyHate: hateRecoveryDetails.maker != address(0)"
            );

            hateRecoveryDetails.maker = msg.sender;

            /// @dev Transfer the assets back to the maker.
            uint256 value = hateDetails.makerDetails.value;
            if (value > 0) _transferETH($maker, value);

            _transferFrom(address(this), $maker, hateDetails.makerDetails);

            /// @dev Announce the event for the indexer.
            emit RoyaltyHateHelpers.RecoverRoyaltyHate(msg.sender, hateDetails);
        }

        /// @dev Allow a taker to recover their assets.
        if (msg.sender == hateDetails.taker) {
            /// @dev Make sure the taker hasn't already recovered.
            require(
                hateRecoveryDetails.taker == address(0),
                "RoyaltyHate: hateRecoveryDetails.taker != address(0)"
            );

            hateRecoveryDetails.taker = msg.sender;

            /// @dev Transfer the assets back to the taker.
            uint256 value = hateDetails.makerDetails.value;
            if (value > 0) _transferETH(hateDetails.taker, value);

            _transferFrom(
                address(this),
                hateDetails.taker,
                hateDetails.takerDetails
            );

            /// @dev Announce the event for the indexer.
            emit RoyaltyHateHelpers.RecoverRoyaltyHate(msg.sender, hateDetails);
        }
    }

    /// @notice Enables the ability to simply read the nested mapping of details.
    /// @param $maker The address of the maker.
    /// @param $nonce The nonce of the maker.
    function details(
        address $maker,
        uint32 $nonce
    )
        external
        view
        returns (RoyaltyHateHelpers.MakerRoyaltyHateDetails memory)
    {
        return addressToNonceToHateDetails[$maker][$nonce];
    }
}
