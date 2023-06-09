// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Constants} from "./Constants.sol";
import {Verifier} from "./Verifier.sol";

error ProofFailed();

contract ZkSNARKToken {
    string public name;
    string public symbol;

    Verifier public verifier;

    mapping(address => uint256) public hashBalances;
    mapping(address => mapping(address => bool)) public hasFullAllowance;

    constructor(
        Verifier _verifier,
        string memory _name,
        string memory _symbol,
        address[] memory _initialHolders
    ) {
        name = _name;
        symbol = _symbol;
        verifier = _verifier;

        for (uint256 i = 0; i < _initialHolders.length; i++) {
            hashBalances[_initialHolders[i]] = Constants
                .INITIAL_SUPPLY_PER_HOLDERS;
        }
    }

    function trasfer(
        address receiver,
        Verifier.Proof memory proof,
        uint256[6] memory inputParams
    ) external {
        inputParams[0] = hashBalances[msg.sender];
        inputParams[1] = hashBalances[receiver];

        bool valid = verifier.verifyTx(proof, inputParams);

        if (valid) {
            hashBalances[msg.sender] = inputParams[3];
            hashBalances[receiver] = inputParams[4];
        } else {
            revert ProofFailed();
        }
    }

    function setApproval(address _spender, bool _value) external {
        hasFullAllowance[msg.sender][_spender] = _value;
    }
}
