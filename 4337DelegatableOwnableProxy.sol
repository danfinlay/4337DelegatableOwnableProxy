pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "./Delegatable.sol";
import "./IEIP4337.sol"; // Import EIP-4337 interface

contract Ownable {
    address public owner;

    constructor() {
        owner = _msgSender();
    }

    modifier onlyOwner() {
        require(_msgSender() == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract OwnableProxy is Delegatable, ERC1967Proxy, Context, IEIP4337 {
    constructor(address _logic, bytes memory _data) ERC1967Proxy(_logic, _data) {}

    function _msgSender() internal view override returns (address sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        Ownable(payable(_implementation())).transferOwnership(newOwner);
    }

    // EIP-4337 functions

    function processUserOperations(UserOperation[] calldata userOperations) external override {
        for (uint256 i = 0; i < userOperations.length; i++) {
            address validator = Delegatable(_implementation()).getUserOperationValidator(userOperations[i]);
            uint256 validationData = Delegatable(_implementation()).validateUserOp(userOperations[i], keccak256(abi.encode(userOperations[i])), 0);
            require(validationData != 0, "Invalid user operation");

            (bool success, bytes memory returndata) = validator.delegatecall(abi.encodePacked(userOperations[i].initCode, userOperations[i].callData));
            require(success, "UserOperation execution failed");
        }
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        return Delegatable(_implementation()).validateUserOp(userOp, userOpHash, missingAccountFunds);
    }
}
