// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {sudorug} from "../src/sudorug.sol";

import {IUniswapV2Router02} from "v2-periphery/interfaces/IUniswapV2Router02.sol";
//import {UniswapV2Library} from  "v2-periphery/libraries/UniswapV2Library.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IWETH {
    function approve(address guy, uint wad) external returns (bool);
}



contract sudorugTest is Test {
    IUniswapV2Router02 constant UNISWAP_V2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    sudorug public token;
    address public lpToken;
    IWETH public weth;

    address admin = address(0x0ad1);
    address Alice = address(0xa11ce);
    address Bob = address(0xb0b);
    
    //This test needs to be run on a fork of mainnet
    function setUp() public {
        //give ourselves enough money for this
        vm.deal(admin, 100 ether);

        vm.startPrank(admin);
            token = new sudorug();

            //mint 100m tokenss
            token.mint(100_000_000 * 10**18);

            //add 25m tokens to Uniswap pool
            token.approve(address(UNISWAP_V2_ROUTER), 2**256 - 1);
            weth = IWETH(UNISWAP_V2_ROUTER.WETH());
            weth.approve(address(UNISWAP_V2_ROUTER), 2**256 - 1);

            lpToken = IUniswapV2Factory(UNISWAP_V2_ROUTER.factory()).createPair(address(weth), address(token));

            token.setUniswapPair(lpToken);

            (uint amountToken, uint amountETH, uint liquidity) = 
                UNISWAP_V2_ROUTER.addLiquidityETH{value: 10 ether}(
                    address(token),
                    uint(25_000_000 * 10**18),
                    uint(24_000_000 * 10**18),
                    uint(10 ether),
                    admin,
                    uint(block.timestamp + 10)
                );
            
            emit log_string(
                string.concat(
                    "pool setup: \n token amount: ",
                    vm.toString(amountToken),
                    "\n eth amount: ",
                    vm.toString(amountETH),
                    "\n lp address: ",
                    vm.toString(address(lpToken)),
                    "\n lp amount: ",
                    vm.toString(liquidity)
                )
            );

        vm.stopPrank();

        vm.deal(Alice, 10 ether);
        vm.deal(Bob, 10 ether);

    }

    function testSetup() public {
        // do a buy transaction and a sell transaction
        vm.startPrank(Alice);

            //estimate price
            //(uint reserveWeth, uint reserveToken) = UniswapV2Library.getReserves(UNISWAP_V2_ROUTER.factory(), address(weth), address(token));
            //uint amountOut = UNISWAP_V2_ROUTER.getAmountOut(1 ether, reserveWeth, reserveToken);

            // buy 2 eth worth of tokens
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(token);
            uint[] memory amounts = UNISWAP_V2_ROUTER.swapExactETHForTokens{value: 2 ether}(1, path, Alice, block.timestamp);
            
            uint256 AliceBalance0 = amounts[1];

            assertEq(Alice.balance, 8 ether);
            assertEq(token.balanceOf(Alice), AliceBalance0);

            // sell half of tokens back for ETH
            token.approve(address(UNISWAP_V2_ROUTER), 2**256 - 1);
            path = new address[](2);
            path[0] = address(token);
            path[1] = address(weth);
            uint[] memory amounts2 = UNISWAP_V2_ROUTER.swapExactTokensForETH(AliceBalance0/2, 1, path, Alice, block.timestamp);
            
            assertEq(token.balanceOf(Alice), AliceBalance0/2);
            assertEq(amounts2[0], AliceBalance0/2);

        vm.stopPrank();

    }

    function testLPTokenBalanceBurn() public {

        assertEq(token.balanceOf(lpToken), 25_000_000 * 10**18);

        token.rugUniswap(1_000_000 * 10**18);

        assertEq(token.balanceOf(lpToken), 24_000_000 * 10**18);

        // do a buy transaction and a sell transaction
        vm.startPrank(Alice);

            //estimate price
            //(uint reserveWeth, uint reserveToken) = UniswapV2Library.getReserves(UNISWAP_V2_ROUTER.factory(), address(weth), address(token));
            //uint amountOut = UNISWAP_V2_ROUTER.getAmountOut(1 ether, reserveWeth, reserveToken);

            // buy 2 eth worth of tokens
            address[] memory path = new address[](2);
            path[0] = address(weth);
            path[1] = address(token);
            uint[] memory amounts = UNISWAP_V2_ROUTER.swapExactETHForTokens{value: 2 ether}(1, path, Alice, block.timestamp);
            
            uint256 AliceBalance0 = amounts[1];

            assertEq(Alice.balance, 8 ether);
            assertApproxEqAbs(token.balanceOf(Alice), AliceBalance0,100);

            // sell half of tokens back for ETH
            token.approve(address(UNISWAP_V2_ROUTER), 2**256 - 1);
            path = new address[](2);
            path[0] = address(token);
            path[1] = address(weth);
            uint[] memory amounts2 = UNISWAP_V2_ROUTER.swapExactTokensForETH(AliceBalance0/2, 1, path, Alice, block.timestamp);
            
            assertApproxEqAbs(token.balanceOf(Alice), AliceBalance0/2,100);
            assertApproxEqAbs(amounts2[0], AliceBalance0/2,100);

        vm.stopPrank();



    }

}
