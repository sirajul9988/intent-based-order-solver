// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract IntentSettlement is EIP712 {
    using ECDSA for bytes32;

    bytes32 public constant INTENT_TYPEHASH = keccak256(
        "SwapIntent(address user,address tokenIn,address tokenOut,uint256 amountIn,uint256 minAmountOut,uint256 nonce,uint256 deadline)"
    );

    mapping(address => uint256) public nonces;

    constructor() EIP712("IntentProtocol", "1") {}

    function settleIntent(
        address user,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        uint256 nonce,
        uint256 deadline,
        bytes calldata signature,
        bytes calldata solverData
    ) external {
        require(block.timestamp <= deadline, "Intent expired");
        require(nonces[user] == nonce, "Invalid nonce");

        bytes32 structHash = keccak256(abi.encode(
            INTENT_TYPEHASH, user, tokenIn, tokenOut, amountIn, minAmountOut, nonce, deadline
        ));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = hash.recover(signature);
        require(signer == user, "Invalid signature");

        nonces[user]++;

        // 1. Pull user tokens
        IERC20(tokenIn).transferFrom(user, address(this), amountIn);
        
        // 2. Execute solver's specialized trade logic
        IERC20(tokenIn).approve(msg.sender, amountIn);
        (bool success, ) = msg.sender.call(solverData);
        require(success, "Solver execution failed");

        // 3. Verify minAmountOut was achieved and send to user
        uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));
        require(balanceOut >= minAmountOut, "Slippage too high");
        IERC20(tokenOut).transfer(user, balanceOut);
    }
}
