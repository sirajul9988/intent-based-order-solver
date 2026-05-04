const { ethers } = require("ethers");

async function signSwapIntent(signer, settlementAddress, intent) {
    const domain = {
        name: "IntentProtocol",
        version: "1",
        chainId: (await signer.provider.getNetwork()).chainId,
        verifyingContract: settlementAddress
    };

    const types = {
        SwapIntent: [
            { name: "user", type: "address" },
            { name: "tokenIn", type: "address" },
            { name: "tokenOut", type: "address" },
            { name: "amountIn", type: "uint256" },
            { name: "minAmountOut", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint256" }
        ]
    };

    return await signer.signTypedData(domain, types, intent);
}

module.exports = { signSwapIntent };
