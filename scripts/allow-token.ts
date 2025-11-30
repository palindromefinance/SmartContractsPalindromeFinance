import * as dotenv from "dotenv";
dotenv.config();

import { createPublicClient, createWalletClient, http, encodeFunctionData } from "viem";
import { bscTestnet } from "viem/chains";
import { privateKeyToAccount } from "viem/accounts";
import { readFileSync } from "fs";

function loadArtifact(path: string) {
    return JSON.parse(readFileSync(path, "utf8"));
}
const EscrowArtifact = loadArtifact("./artifacts/contracts/PalindromeCryptoEscrow.sol/PalindromeCryptoEscrow.json");

const BSCTESTNET_RPC_URL = process.env.BSCTESTNET_RPC_URL?.trim();
const BSCTESTNET_PRIVATE_KEY = process.env.OWNER_KEY?.trim();

if (!BSCTESTNET_RPC_URL || !BSCTESTNET_PRIVATE_KEY) {
    throw new Error("Set BSCTESTNET_RPC_URL and OWNER_KEY in environment");
}

function validateHexKey(key: string | undefined, label: string): `0x${string}` {
    if (!key) throw new Error(`Missing ${label}`);
    const stripped = key.replace(/^['"]|['"]$/g, '');
    if (!/^0x[0-9a-fA-F]{64}$/.test(stripped)) {
        throw new Error(`Invalid format for ${label}`);
    }
    return stripped as `0x${string}`;
}

const privateKey = validateHexKey(BSCTESTNET_PRIVATE_KEY, "OWNER_KEY");
const publicClient = createPublicClient({ chain: bscTestnet, transport: http(BSCTESTNET_RPC_URL) });
const deployerAccount = privateKeyToAccount(privateKey);
const deployerClient = createWalletClient({ chain: bscTestnet, transport: http(BSCTESTNET_RPC_URL), account: deployerAccount });

async function main() {
    const ESCROW_ADDRESS = "0xe48219fb5dbed847ec4dde67c7c6f5e9937b69a1" as `0x${string}`; // Replace with your deployed escrow
    const NEW_TOKEN_ADDRESS = "0x337610d27c682E347C9cD60BD4b3b107C9d34dDd" as `0x${string}`; // BSC testnet USDC or your token

    const setTokenCalldata = encodeFunctionData({
        abi: EscrowArtifact.abi,
        functionName: "setAllowedToken",
        args: [NEW_TOKEN_ADDRESS, true]
    });

    console.log("Calling setAllowedToken on:", ESCROW_ADDRESS);
    console.log("Token:", NEW_TOKEN_ADDRESS);

    const txHash = await deployerClient.sendTransaction({ to: ESCROW_ADDRESS, data: setTokenCalldata });
    const receipt = await publicClient.waitForTransactionReceipt({ hash: txHash });

    console.log("✅ Token allowed! Tx:", txHash, "Block:", receipt.blockNumber);
}

main().catch(console.error);
