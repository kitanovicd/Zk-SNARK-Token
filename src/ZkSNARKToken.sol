// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Constants} from "./Constants.sol";
import {IVerifier} from "./interfaces/IVerifier.sol";

contract ZkSNARKToken {
    string public name;
    string public symbol;

    IVerifier public verifier;

    mapping(address => uint256) public hashBalances;
    mapping(address => mapping(address => bool)) public hasFullAllowance;

    constructor(
        string memory _name,
        string memory _symbol,
        address _verifier,
        address[] memory _initialHolders
    ) {
        name = _name;
        symbol = _symbol;
        verifier = IVerifier(_verifier);

        for (uint256 i = 0; i < _initialHolders.length; i++) {
            hashBalances[_initialHolders[i]] = Constants
                .INITIAL_SUPPLY_PER_HOLDERS;
        }
    }

    function setApproval(address _spender, bool _value) external {
        hasFullAllowance[msg.sender][_spender] = _value;
    }
}
