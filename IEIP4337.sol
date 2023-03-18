// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct UserOperation {
    address sender;
    uint256 nonce;
    uint256 gasLimit;
    bytes32 initDataHash;
    bytes32 initCodeHash;
    bytes initCode;
    bytes32 callDataHash;
    bytes callData;
}

interface IEIP4337 {
    function processUserOperations(UserOperation[] calldata userOperations) external;
}
