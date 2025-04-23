// SPDX-License-Identifier: MIT
// Damn Vulnerable DeFi v4 (https://damnvulnerabledefi.xyz)
pragma solidity =0.8.25;

import {Test, console, console2} from "forge-std/Test.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {WETH} from "solmate/tokens/WETH.sol";
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";

contract UniswapV2 is Test {
    address deployer = makeAddr("deployer");
    address player = makeAddr("player");
    address recovery = makeAddr("recovery");

    uint256 constant UNISWAP_INITIAL_TOKEN_RESERVE = 100e18;
    uint256 constant UNISWAP_INITIAL_WETH_RESERVE = 100e18;
    uint256 constant PLAYER_INITIAL_TOKEN_BALANCE = 100e18;
    uint256 constant PLAYER_INITIAL_ETH_BALANCE = 100e18;

    WETH weth;
    DamnValuableToken token;
    IUniswapV2Factory uniswapV2Factory;
    IUniswapV2Router02 uniswapV2Router;
    IUniswapV2Pair uniswapV2Exchange;

    modifier checkSolvedByPlayer() {
        vm.startPrank(player, player);
        _;
        vm.stopPrank();
    }

    /**
     * SETS UP CHALLENGE - DO NOT TOUCH
     */
    function setUp() public {
        startHoax(deployer);
        vm.deal(player, PLAYER_INITIAL_ETH_BALANCE);

        // Deploy tokens to be traded
        token = new DamnValuableToken();
        weth = new WETH();

        // Deploy Uniswap V2 Factory and Router
        uniswapV2Factory = IUniswapV2Factory(
            deployCode(string.concat(vm.projectRoot(), "/builds/uniswap/UniswapV2Factory.json"), abi.encode(address(recovery)))
        );

        uniswapV2Router = IUniswapV2Router02(
            deployCode(
                string.concat(vm.projectRoot(), "/builds/uniswap/UniswapV2Router02.json"),
                abi.encode(address(uniswapV2Factory), address(weth))
            )
        );

        // Create Uniswap pair against WETH and add liquidity
        token.approve(address(uniswapV2Router), UNISWAP_INITIAL_TOKEN_RESERVE);
        uniswapV2Router.addLiquidityETH{value: UNISWAP_INITIAL_WETH_RESERVE}({
            token: address(token),
            amountTokenDesired: UNISWAP_INITIAL_TOKEN_RESERVE,
            amountTokenMin: 0,
            amountETHMin: 0,
            to: deployer,
            deadline: block.timestamp * 2
        });
        uniswapV2Exchange = IUniswapV2Pair(uniswapV2Factory.getPair(address(token), address(weth)));

        // Setup initial token balances of pool and player accounts
        token.transfer(player, PLAYER_INITIAL_TOKEN_BALANCE);

        vm.stopPrank();
    }

    /**
     * VALIDATES INITIAL CONDITIONS - DO NOT TOUCH
     */
    function test_assertInitialState() public view {
        assertEq(player.balance, PLAYER_INITIAL_ETH_BALANCE);
        assertEq(token.balanceOf(player), PLAYER_INITIAL_TOKEN_BALANCE);
        assertGt(uniswapV2Exchange.balanceOf(deployer), 0);
    }

    /**
     * CODE YOUR SOLUTION HERE
     */
    function test_puppetV2() public checkSolvedByPlayer {
        (uint reserve0, uint reserve1,) = uniswapV2Exchange.getReserves();
        console.log(reserve0);
        console.log(reserve1);

        token.transfer(address(uniswapV2Exchange), 50e18);

        uniswapV2Exchange.swap(
            20e18,
            0,
            player,
            ""
        );

        (uint reserve0_1, uint reserve1_1,) = uniswapV2Exchange.getReserves();
        console.log(reserve0_1);
        console.log(reserve1_1);

        uniswapV2Exchange.skim(player);

        (uint reserve0_2, uint reserve1_2,) = uniswapV2Exchange.getReserves();
        console.log(reserve0_2);
        console.log(reserve1_2);
    }
}
