// SPDX-License-Identifier: https://github.com/lendroidproject/protocol.2.0/blob/master/LICENSE.md
pragma solidity 0.7.5;
// pragma abicoder v2;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IAuction.sol";
import "./IRandomMinter.sol";
import "./IAuctionCurve.sol";
import "./Structs.sol";

// solhint-disable-next-line
abstract contract BaseAuctions is IAuction, Ownable {

    using Address for address;
    using SafeERC20 for IERC20;

    // calulations
    DefiKey[] public defiKeys;// solhint-disable-line var-name-mixedcase;
    IAuctionCurve public auctionCurve;
    IERC20 public purchaseToken;
    IRandomMinter public keyMinter;
    // dao
    address public daoTreasury;
    // events
    event PurchaseMade(address indexed account, uint256 indexed epoch, uint256 purchaseAmount);

    function setDaoTreasury(address daoTreasuryAddress) external override onlyOwner {
        require(daoTreasuryAddress != address(0),
            "{setDaoTreasury} : invalid daoTreasuryAddress");
        daoTreasury = daoTreasuryAddress;
    }

    function setKeyMinter(address keyMinterAddress) external override onlyOwner {
        require(keyMinterAddress != address(0),
            "{setKeyMinter} : invalid keyMinterAddress");
        keyMinter = IRandomMinter(keyMinterAddress);
    }

    function transferKeyMinterOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "{transferKeyMinterOwnership} : invalid newOwner");
        // transfer ownership of Auction Token Distribution contract to newOwner
        keyMinter.transferOwnership(newOwner);
    }

    function setAuctionCurve(address auctionCurveAddress) external override onlyOwner {
        require(auctionCurveAddress.isContract(), "{setAuctionCurve} : invalid auctionCurveAddress");
        auctionCurve = IAuctionCurve(auctionCurveAddress);
    }

    /**
    * @notice Safety function to handle accidental / excess token transfer to the contract
    */
    function escapeHatchERC20(address tokenAddress) external override onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    function totalDefiKeys() external view override returns (uint256) {
        return defiKeys.length;
    }

    function currentPrice() public view override returns (uint256) {
        if ((defiKeys.length > 0) && (defiKeys[defiKeys.length - 1].epoch == auctionCurve.currentEpoch())) {
            return 0;
        } else {
            return auctionCurve.y(defiKeys);
        }
    }

}
