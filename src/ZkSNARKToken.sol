// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import {Constants} from "./Constants.sol";
import {Verifier} from "./Verifier.sol";
import {ProofFailed, InsufficientAllowance} from "./Errors.sol";

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

    function transfer(
        address _receiver,
        Verifier.Proof calldata _proof,
        uint256[6] memory _inputParams
    ) external {
        _inputParams[0] = hashBalances[msg.sender];
        _inputParams[1] = hashBalances[_receiver];

        _executeTransfer(msg.sender, _receiver, _proof, _inputParams);
    }

    function transferFrom(
        address _from,
        address _to,
        Verifier.Proof calldata _proof,
        uint256[6] memory _inputParams
    ) external {
        if (!hasFullAllowance[_from][msg.sender]) {
            revert InsufficientAllowance();
        }

        _inputParams[0] = hashBalances[_from];
        _inputParams[1] = hashBalances[_to];

        _executeTransfer(_from, _to, _proof, _inputParams);
    }

    function setApproval(address _spender, bool _value) external {
        hasFullAllowance[msg.sender][_spender] = _value;
    }

    function _executeTransfer(
        address _from,
        address _to,
        Verifier.Proof calldata _proof,
        uint256[6] memory _inputParams
    ) internal {
        bool valid = verifier.verifyTx(_proof, _inputParams);

        if (valid) {
            hashBalances[_from] = _inputParams[3];
            hashBalances[_to] = _inputParams[4];
        } else {
            revert ProofFailed();
        }
    }
}
