// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BingoToken is ERC20 {
    constructor() ERC20("BINGO", "BG") {}

    function mint() public {
        _mint(msg.sender, 1 * 10 ** 18);
    }
}
