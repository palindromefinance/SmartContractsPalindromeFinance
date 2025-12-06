# Crypto Pay & Escrow by Palindrome Finance

**Palindrome Finance** is a **secure crypto payment platform with built-in escrow**, engineered for **trustless, protected digital transactions**.

Our **smart contract escrow system** ensures funds are released only when conditions are met — eliminating chargebacks and counterparty + fraud.

[www.palindromefinance.com](https://www.palindromefinance.com)

---

## ✨ Features

| Feature | Description |
|--------|-------------|
| **ERC20 Token Support** | Any allowed ERC20 token (configurable by owner) |
| **1% Protocol Fee** | Automatically deducted on successful delivery (configurable) |
| **EIP-712 Off-Chain Signatures** | Gasless actions: `confirmDelivery`, `requestCancel`, `startDispute` |
| **Mutual Cancellation** | Both parties must agree to cancel (no fee) |
| **Timeout Auto-Cancel** | Buyer can cancel after maturity + grace period if no dispute |
| **Dispute Resolution** | Arbiter decides outcome with evidence-based timeouts |
| **Reentrancy Protection** | Full `nonReentrant` guards on all state-changing functions |
| **Signature Replay Protection** | Per-escrow, per-role nonces + canonical sig hashing |
| **Aggregated Withdrawals** | Users withdraw all earned funds in one call |
| **Owner-Managed Fees & Tokens** | Multisig-ready fee withdrawal and token allowlisting |
| **OpenZeppelin Security** | Audited libraries: `ReentrancyGuard`, `ECDSA`, `SafeERC20`, `Ownable2Step` |

---

## Smart Contract Overview

### Core Roles
- **Buyer**: Deposits funds, confirms delivery or starts dispute
- **Seller**: Receives funds upon successful delivery
- **Arbiter**: Resolves disputes (defaults to contract owner if not specified)

### Escrow States
```solidity
enum State { AWAITING_PAYMENT, AWAITING_DELIVERY, DISPUTED, COMPLETE, REFUNDED, CANCELED }
```

### Key Timeouts
| Timeout | Duration | Purpose |
|-------|----------|--------|
| `maturityTime` | 1–3650 days | Auto-release trigger |
| `GRACE_PERIOD` | 6 hours | Buffer after maturity |
| `DISPUTE_SHORT_TIMEOUT` | 7 days | Requires both parties to submit evidence |
| `DISPUTE_LONG_TIMEOUT` | 30 days | Allows arbiter decision with minimal evidence |

---

## Key Functions

### Escrow Creation
```solidity
createEscrow(...) → uint256 escrowId
createEscrowAndDeposit(...) → uint256 escrowId
```

### Buyer Actions
- `deposit(escrowId)`
- `confirmDelivery(escrowId)`
- `requestCancel(escrowId)`
- `cancelByTimeout(escrowId)`
- `startDispute(escrowId)`

### Seller Actions
- `requestCancel(escrowId)`
- `startDispute(escrowId)`

### Arbiter Actions
- `submitArbiterDecision(escrowId, resolution, ipfsHash)`

### Gasless (Signed) Actions
- `confirmDeliverySigned(...)`
- `requestCancelSigned(...)`
- `startDisputeSigned(...)`

### Withdrawals
- `withdraw(escrowId)` – per-escrow
- `withdrawAll(token)` – all earnings
- `withdrawFees(token)` – owner only

---

## Security Highlights

- **EIP-712 Domain Separation** + per-role nonces
- **Signature Malleability Protection** (low-S enforcement)
- **Per-escrow signature usage tracking**
- **Fee-on-transfer token rejection**
- **Minimum $10 equivalent deposit** (prevents spam)
- **Aggregated balance tracking** prevents double-spend
- **ReentrancyGuard** on all external state changes
- **Ownable2Step** for secure ownership transfer

---

## Installation & Setup

```bash
# 1. Clone and install
git clone https://github.com/yourusername/PalindromeCryptoEscrow.git
cd PalindromeCryptoEscrow
npm install

# 2. Compile
npx hardhat compile

# 3. Run tests
npx hardhat test
```

---

## Testing

```bash
npx hardhat test
```

## License

MIT

---
