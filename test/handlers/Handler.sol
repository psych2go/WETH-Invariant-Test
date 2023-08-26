// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {WETH9} from "../../src/WETH9.sol";
import {Test, console} from "forge-std/Test.sol";
import {AddressSet, LibAddressSet} from "../helpers/LibAddressSet.sol";

contract ForcePush {
    constructor(address dst) payable {
        selfdestruct(payable(dst));
    }
}

contract Handler is Test {
    WETH9 public weth;

    uint256 public constant ETH_SUPPLY = 120_500_000 ether;
    uint256 public ghost_depositSum;
    uint256 public ghost_withdrawSum;
    uint256 public ghost_zeroWithdrawals;
    uint256 public ghost_forcePushSum;
    mapping(bytes32 => uint256) public calls;

    using LibAddressSet for AddressSet;

    AddressSet internal _actors;

    address internal currentActor;

    constructor(WETH9 _weth) {
        weth = _weth;
        vm.deal(address(this), ETH_SUPPLY);
    }

    fallback() external payable {}
    receive() external payable {}

    modifier createActor() {
        currentActor = msg.sender;
        _actors.add(msg.sender);
        _;
    }

    modifier useActor(uint256 actorIndexSeed) {
        currentActor = _actors.rand(actorIndexSeed);
        _;
    }

    modifier countCall(bytes32 key) {
        calls[key]++;
        _;
    }

    function deposit(uint256 amount) public createActor countCall("deposit") {
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);
        vm.prank(currentActor);
        weth.deposit{value: amount}();
        ghost_depositSum += amount;
    }

    function withdraw(uint256 actorSeed, uint256 amount) public useActor(actorSeed) countCall("withdraw") {
        amount = bound(amount, 0, weth.balanceOf(currentActor));
        if (amount == 0) ghost_zeroWithdrawals++;
        vm.startPrank(currentActor);
        weth.withdraw(amount);
        _pay(address(this), amount);
        vm.stopPrank();
        ghost_withdrawSum += amount;
    }

    function sendFallback(uint256 amount) public createActor countCall("sendFallback") {
        amount = bound(amount, 0, address(this).balance);
        _pay(currentActor, amount);
        vm.prank(currentActor);
        (bool success,) = address(weth).call{value: amount}("");
        require(success, "sendFallback failed");
        ghost_depositSum += amount;
    }

    function approve(uint256 actorSeed, uint256 spenderSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("approve")
    {
        address spender = _actors.rand(spenderSeed);
        vm.prank(currentActor);
        weth.approve(spender, amount);
    }

    function transfer(uint256 actorSeed, uint256 toSeed, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transfer")
    {
        address to = _actors.rand(toSeed);
        amount = bound(amount, 0, weth.balanceOf(currentActor));
        vm.prank(currentActor);
        weth.transfer(to, amount);
    }

    function transferFrom(uint256 actorSeed, uint256 fromSeed, uint256 toSeed, bool _approve, uint256 amount)
        public
        useActor(actorSeed)
        countCall("transferFrom")
    {
        address from = _actors.rand(fromSeed);
        address to = _actors.rand(toSeed);
        amount = bound(amount, 0, weth.balanceOf(from));
        if (_approve) {
            vm.prank(from);
            weth.approve(currentActor, amount);
        } else {
            amount = bound(amount, 0, weth.allowance(currentActor, from));
        }
        vm.prank(currentActor);
        weth.transferFrom(from, to, amount);
    }

    function forcePush(uint256 amount) public countCall("forcePush") {
        amount = bound(amount, 0, address(this).balance);
        new ForcePush{value:amount} (address(weth));
        ghost_forcePushSum += amount;
    }

    function forEachActor(function(address) external func) public {
        return _actors.forEach(func);
    }

    function reduceActors(uint256 acc, function(uint256,address) external returns (uint256) func)
        public
        returns (uint256)
    {
        return _actors.reduce(acc, func);
    }

    function actors() external view returns (address[] memory) {
        return _actors.addrs;
    }

    function callSummary() external view {
        console.log("Call summary:");
        console.log("-------------");
        console.log("deposit", calls["deposit"]);
        console.log("withdraw", calls["withdraw"]);
        console.log("sendFallBack", calls["sendFallback"]);
        console.log("approve", calls["approve"]);
        console.log("transfer", calls["transfer"]);
        console.log("transferFrom", calls["transferFrom"]);
        console.log("forcePush", calls["forcePush"]);
        console.log("-------------");
        console.log("Zero withdrawals:", ghost_zeroWithdrawals);
    }

    function _pay(address to, uint256 amount) internal {
        (bool s,) = to.call{value: amount}("");
        require(s, "pay() failed");
    }
}
