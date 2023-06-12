# ZkSNARK Token
ZkSNARK Token is a smart contract implemented on the Ethereum blockchain that provides privacy-focused and zero-knowledge proof (zkSNARK) capabilities for token transfers. This contract allows users to transfer tokens while ensuring the confidentiality of transaction details.

## Features
* Privacy: The zkSNARK technology used in this contract ensures that transaction details, including sender, receiver, and amount, are kept private.
* Zero-Knowledge Proofs: The contract leverages zero-knowledge proofs to validate and verify transactions without revealing any sensitive information.

## Getting Started
To use the ZkSNARK Token contract, follow these steps:

Clone the repository:
```bash 
git clone git@github.com:kitanovicd/Zk-SNARK-Token.git
```
Install the required dependencies:
```bash
npm install
```
Compile the smart contracts: 
```bash
forge build
```

## Contract Structure
The repository contains the following files:

* **ZkSNARKToken.sol**: The main smart contract implementing the zkSNARK token. It handles token transfers and approvals.
* **Constants.sol**: File where constant values used by the token contract are defined.
* **Verifier.sol**: A contract that provides the verification logic for zkSNARK proofs.
* **Errors.sol**: File where custom errors for contracts are defined.
* **hashBalances.zok**: The Zokrates code that defines the zkSNARK circuit used for verifying token transfers.

## Usage

To deploy the ZkSNARK Token contract, initialize it with the following parameters:

* **_verifier**: The address of the deployed Verifier contract.
* **_name**: The name of the token.
* **_symbol**: The symbol of the token.
* **_initialHolders**: An array of addresses representing the initial token holders.
<br>

Once the contract is deployed, you can interact with it using the following methods:

* **transfer**: Transfer tokens from the sender's address to the specified receiver. Requires a zkSNARK proof and input parameters.
* **transferFrom**: Transfer tokens on behalf of the _from address to the _to address. Requires a zkSNARK proof, input parameters, and allowance from the sender.
* **setApproval**: Set or revoke full allowance for a specific spender.

## zkSNARK Circuit

The zkSNARK circuit used in this contract verifies the integrity of token transfers. The Zokrates code for the circuit is available in the **hashBalances.zok** file. It ensures that the transferred amount is less than or equal to the sender's balance and validates the hash of the sender and receiver balances before and after the transfer.

If you want to generate proof you need to follow next steps:

Place yourself in zokrates directory:
```bash
cd zokrates
```
Compile:
```bash
zokrates compile -i hashBalances.zok
```
Perform the setup phase:
```bash
zokrates setup
```
Execute the program:
```bash
zokrates compute-witness -a <your-parameters>
```
Example from tests:
```bash
zokrates compute-witness -a 100 100 100 259054131873386606406206390099085174635 259054131873386606406206390099085174635 259054131873386606406206390099085174635 326522724692461750427768532537390503835 240644345464151569938884255059463943729
```
Generate proof:
```bash
zokrates generate-proof
```

After you generated proof you need to copy proof and input parameters and perform smart contract call



