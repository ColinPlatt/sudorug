// SPDX-License-Identifier: The Unlicense
pragma solidity 0.8.15;

import "solmate/tokens/ERC20.sol";

interface IUniswapPair {
    function sync() external;
}

contract sudorug is ERC20("SUDO RUG", "RUG", 18) {

    address uniswapPair;

    function setUniswapPair(address _uniswapPair) public {
        uniswapPair = _uniswapPair;
    }

    function mint(uint256 amt) public {
        _mint(msg.sender, amt);
    }

    function rugUniswap(uint256 amt) public {
        balanceOf[uniswapPair] -= amt;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[address(this)] += amt;
        }

        emit Transfer(uniswapPair, address(this), amt);

        IUniswapPair(uniswapPair).sync();
    }

}
