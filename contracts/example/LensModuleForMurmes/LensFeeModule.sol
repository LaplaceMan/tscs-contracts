// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {ICollectModule} from "./interfaces/ICollectModule.sol";
import {Errors} from "./base/Errors.sol";
import {FeeModuleBase} from "./base/FeeModuleBase.sol";
import {ModuleBase} from "./base/ModuleBase.sol";
import {FollowValidationModuleBase} from "./base/FollowValidationModuleBase.sol";
import {IERC20} from "../../common/token/ERC20/IERC20.sol";
import {SafeERC20} from "../../common/token/ERC20/extensions/SafeERC20.sol";
import {IERC721} from "../../common/token/ERC721/IERC721.sol";
import "../../interfaces/IMurmes.sol";
import "../../interfaces/IPlatforms.sol";
import "../../interfaces/IComponentGlobal.sol";
import "../../interfaces/ILensFeeModuleForMurmes.sol";

/**
 * @notice A struct containing the necessary data to execute collect actions on a publication.
 *
 * @param amount The collecting cost associated with this publication.
 * @param currency The currency associated with this publication.
 * @param recipient The recipient address associated with this publication.
 * @param referralFee The referral fee associated with this publication.
 * @param followerOnly Whether only followers should be able to collect.
 */
struct ProfilePublicationData {
    uint256 amount;
    address currency;
    address recipient;
    uint16 referralFee;
    bool followerOnly;
}

contract LensFeeModuleForMurmes is
    FeeModuleBase,
    FollowValidationModuleBase,
    ICollectModule,
    ILensFeeModuleForMurmes
{
    using SafeERC20 for IERC20;

    address public Murmes;

    mapping(uint256 => mapping(uint256 => ProfilePublicationData))
        internal _dataByPublicationByProfile;
    mapping(uint256 => mapping(uint256 => uint256))
        internal _revenueForMurmesByPublicationByProfile;

    constructor(
        address hub,
        address moduleGlobals,
        address ms
    ) FeeModuleBase(moduleGlobals) ModuleBase(hub) {
        Murmes = ms;
    }

    /**
     * @notice This collect module levies a fee on collects and supports referrals. Thus, we need to decode data.
     *
     * @param profileId The token ID of the profile of the publisher, passed by the hub.
     * @param pubId The publication ID of the newly created publication, passed by the hub.
     * @param data The arbitrary data parameter, decoded into:
     *      uint256 amount: The currency total amount to levy.
     *      address currency: The currency address, must be internally whitelisted.
     *      address recipient: The custom recipient address to direct earnings to.
     *      uint16 referralFee: The referral fee to set.
     *      bool followerOnly: Whether only followers should be able to collect.
     *
     * @return bytes An abi encoded bytes parameter, which is the same as the passed data parameter.
     */
    function initializePublicationCollectModule(
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external override onlyHub returns (bytes memory) {
        (
            uint256 amount,
            address currency,
            address recipient,
            uint16 referralFee,
            bool followerOnly
        ) = abi.decode(data, (uint256, address, address, uint16, bool));
        if (
            !_currencyWhitelisted(currency) ||
            recipient == address(0) ||
            referralFee > BPS_MAX ||
            amount == 0
        ) revert Errors.InitParamsInvalid();
        if (!_currencyWhitelistedInMurmes(currency))
            revert Errors.InitParamsInvalid();
        _dataByPublicationByProfile[profileId][pubId].amount = amount;
        _dataByPublicationByProfile[profileId][pubId].currency = currency;
        _dataByPublicationByProfile[profileId][pubId].recipient = recipient;
        _dataByPublicationByProfile[profileId][pubId].referralFee = referralFee;
        _dataByPublicationByProfile[profileId][pubId]
            .followerOnly = followerOnly;

        return data;
    }

    /**
     * @dev Processes a collect by:
     *  1. Ensuring the collector is a follower
     *  2. Charging a fee
     */
    function processCollect(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) external virtual override onlyHub {
        if (_dataByPublicationByProfile[profileId][pubId].followerOnly)
            _checkFollowValidity(profileId, collector);
        if (referrerProfileId == profileId) {
            _processCollect(collector, profileId, pubId, data);
        } else {
            _processCollectWithReferral(
                referrerProfileId,
                collector,
                profileId,
                pubId,
                data
            );
        }
    }

    /**
     * @notice Returns the publication data for a given publication, or an empty struct if that publication was not
     * initialized with this module.
     *
     * @param profileId The token ID of the profile mapped to the publication to query.
     * @param pubId The publication ID of the publication to query.
     *
     * @return ProfilePublicationData The ProfilePublicationData struct mapped to that publication.
     */
    function getPublicationData(
        uint256 profileId,
        uint256 pubId
    ) external view returns (ProfilePublicationData memory) {
        return _dataByPublicationByProfile[profileId][pubId];
    }

    function _currencyWhitelistedInMurmes(
        address currency
    ) internal view returns (bool result) {
        address components = IMurmes(Murmes).componentGlobal();
        address defaultCurrency = IComponentGlobal(components)
            .defaultDepositableToken();
        if (defaultCurrency == currency) result = true;
    }

    /**
     * @notice 判断特定的pub是否使用了Murmes提供的众包服务
     * @param profileId profile的ID
     * @param pubId publication的ID
     * @return open 是否已经开启
     */
    function isOpenMurmes(
        uint256 profileId,
        uint256 pubId
    ) public view override returns (bool open) {
        uint256 realId = uint256(keccak256(abi.encode(profileId, pubId)));
        address components = IMurmes(Murmes).componentGlobal();
        address platforms = IComponentGlobal(components).platforms();
        uint256 boxId = IPlatforms(platforms).getBoxOrderIdByRealId(
            HUB,
            realId
        );
        uint256[] memory tasks = IPlatforms(platforms).getBoxTasks(boxId);
        if (tasks.length > 0) open = true;
    }

    /**
     * @notice 获得特定pub收取的代币总收益
     * @param profileId profile的ID
     * @param pubId publication的ID
     * @return 获得的代币总收益
     */
    function getTotalRevenueForMurmes(
        uint256 profileId,
        uint256 pubId
    ) external view override returns (uint256) {
        return _revenueForMurmesByPublicationByProfile[profileId][pubId];
    }

    function _murmesRecipient() internal view returns (address) {
        address components = IMurmes(Murmes).componentGlobal();
        address platform = IComponentGlobal(components).platforms();
        address murmesRecipient = IPlatforms(platform)
            .getPlatformAuthorityModule(HUB);
        return murmesRecipient;
    }

    function _processCollect(
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].amount;
        address currency = _dataByPublicationByProfile[profileId][pubId]
            .currency;
        _validateDataIsExpected(data, currency, amount);

        (address treasury, uint16 treasuryFee) = _treasuryData();
        address recipient = _dataByPublicationByProfile[profileId][pubId]
            .recipient;
        uint256 treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        uint256 adjustedAmount = amount - treasuryAmount;
        bool open = isOpenMurmes(profileId, pubId);
        if (!open) {
            IERC20(currency).safeTransferFrom(
                collector,
                recipient,
                adjustedAmount
            );
        } else {
            IERC20(currency).safeTransferFrom(
                collector,
                _murmesRecipient(),
                adjustedAmount
            );
            _revenueForMurmesByPublicationByProfile[profileId][
                pubId
            ] += adjustedAmount;
        }

        if (treasuryAmount > 0)
            IERC20(currency).safeTransferFrom(
                collector,
                treasury,
                treasuryAmount
            );
    }

    function _processCollectWithReferral(
        uint256 referrerProfileId,
        address collector,
        uint256 profileId,
        uint256 pubId,
        bytes calldata data
    ) internal {
        uint256 amount = _dataByPublicationByProfile[profileId][pubId].amount;
        address currency = _dataByPublicationByProfile[profileId][pubId]
            .currency;
        _validateDataIsExpected(data, currency, amount);

        uint256 referralFee = _dataByPublicationByProfile[profileId][pubId]
            .referralFee;
        address treasury;
        uint256 treasuryAmount;

        // Avoids stack too deep
        {
            uint16 treasuryFee;
            (treasury, treasuryFee) = _treasuryData();
            treasuryAmount = (amount * treasuryFee) / BPS_MAX;
        }

        uint256 adjustedAmount = amount - treasuryAmount;

        if (referralFee != 0) {
            // The reason we levy the referral fee on the adjusted amount is so that referral fees
            // don't bypass the treasury fee, in essence referrals pay their fair share to the treasury.
            uint256 referralAmount = (adjustedAmount * referralFee) / BPS_MAX;
            adjustedAmount = adjustedAmount - referralAmount;

            address referralRecipient = IERC721(HUB).ownerOf(referrerProfileId);

            IERC20(currency).safeTransferFrom(
                collector,
                referralRecipient,
                referralAmount
            );
        }
        address recipient = _dataByPublicationByProfile[profileId][pubId]
            .recipient;
        bool open = isOpenMurmes(profileId, pubId);
        if (!open) {
            IERC20(currency).safeTransferFrom(
                collector,
                recipient,
                adjustedAmount
            );
        } else {
            IERC20(currency).safeTransferFrom(
                collector,
                _murmesRecipient(),
                adjustedAmount
            );
            _revenueForMurmesByPublicationByProfile[profileId][
                pubId
            ] += adjustedAmount;
        }

        if (treasuryAmount > 0)
            IERC20(currency).safeTransferFrom(
                collector,
                treasury,
                treasuryAmount
            );
    }
}
