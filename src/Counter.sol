// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Constants} from "./Constants.sol";

contract ZkSNARKToken {
    string public name;
    string public symbol;

    mapping(address => uint256) public hashBalances;

    constructor(
        string memory _name,
        string memory _symbol,
        address[] memory _initialHolders
    ) {
        name = _name;
        symbol = _symbol;

        for (uint256 i = 0; i < _initialHolders.length; i++) {
            hashBalances[_initialHolders[i]] = Constants
                .INITIAL_SUPPLY_PER_HOLDERS;
        }
    }
}
