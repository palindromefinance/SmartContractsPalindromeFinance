pragma solidity 0.8.29;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title PalindromeEscrowWallet - Minimal 2-of-3 multisig wallet for escrow funds
/// @notice Holds funds for a single escrow, requires 2-of-3 signatures from buyer/seller/arbiter to move funds.
/// @dev Non-upgradeable, participant-controlled. Supports single or split transfers.
contract PalindromeEscrowWallet {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;

    address public immutable buyer;
    address public immutable seller;
    address public immutable arbiter;
    uint8 public immutable threshold; // 2 for 2-of-3

    uint256 public nonce;

    event Executed(uint256 indexed nonce, address indexed token, address to, uint256 amount);
    event SplitExecuted(uint256 indexed nonce, address indexed token, address to, uint256 netAmount, address feeTo, uint256 feeAmount);

    constructor(address _buyer, address _seller, address _arbiter, uint8 _threshold) {
        require(_buyer != address(0) && _seller != address(0) && _arbiter != address(0), "Zero address");
        require(_threshold == 2, "Threshold must be 2"); // Fixed to 2-of-3 for simplicity
        buyer = _buyer;
        seller = _seller;
        arbiter = _arbiter;
        threshold = _threshold;
    }

    /// @notice Check if address is one of the owners
    function isOwner(address account) public view returns (bool) {
        return account == buyer || account == seller || account == arbiter;
    }

    /// @notice Execute a single ERC20 transfer with sufficient signatures
    /// @param token ERC20 token to transfer
    /// @param to Recipient address
    /// @param amount Amount to transfer
    /// @param signatures Array of signatures (65 bytes each, in order: buyer, seller, arbiter; use empty bytes for non-signers)
    function executeERC20(address token, address to, uint256 amount, bytes[3] calldata signatures) external {
        require(to != address(0), "Recipient zero");
        require(amount > 0, "Amount zero");

        bytes32 txHash = keccak256(abi.encodePacked(address(this), token, to, amount, nonce, block.chainid));

        uint8 sigCount = _countValidSignatures(txHash, signatures);
        require(sigCount >= threshold, "Insufficient signatures");
      
        IERC20(token).safeTransfer(to, amount);
        nonce++;
        emit Executed(nonce - 1, token, to, amount);
    }

    /// @notice Execute a split ERC20 transfer (net + fee) with sufficient signatures
    /// @param token ERC20 token to transfer
    /// @param to Net recipient address
    /// @param netAmount Net amount to recipient
    /// @param feeTo Fee recipient address
    /// @param feeAmount Fee amount
    /// @param signatures Array of signatures (65 bytes each, in order: buyer, seller, arbiter; use empty bytes for non-signers)
    function executeERC20Split(
        address token,
        address to,
        uint256 netAmount,
        address feeTo,
        uint256 feeAmount,
        bytes[3] calldata signatures
    ) external {
        require(to != address(0), "Recipient zero");
        require(feeTo != address(0), "FeeTo zero");

        require(netAmount > 0 || feeAmount > 0, "Nothing to transfer");
        uint256 totalAmount = netAmount + feeAmount; // Will revert on overflow
        require(totalAmount > netAmount && totalAmount > feeAmount, "Overflow");

        bytes32 txHash = keccak256(abi.encodePacked(address(this), token, to, netAmount, feeTo, feeAmount, nonce, block.chainid));

        uint8 sigCount = _countValidSignatures(txHash, signatures);
        require(sigCount >= threshold, "Insufficient signatures");

        nonce++;
        if (netAmount > 0) {
            IERC20(token).safeTransfer(to, netAmount);
        }
        if (feeAmount > 0) {
            IERC20(token).safeTransfer(feeTo, feeAmount);
        }
        emit SplitExecuted(nonce - 1, token, to, netAmount, feeTo, feeAmount);
    }

    /// @dev Internal helper to count and validate signatures
    function _countValidSignatures(bytes32 txHash, bytes[3] calldata signatures) internal view returns (uint8 count) {
        address[3] memory owners = [buyer, seller, arbiter];
        bool[3] memory signed;
        address[3] memory usedAddresses; // Track addresses to prevent reuse
        
        for (uint8 i = 0; i < 3; i++) {
            bytes calldata sig = signatures[i];
            if (sig.length != 65) continue;

            (bytes32 r, bytes32 s, uint8 v) = _splitSignature(sig);
            
            // CRITICAL: Validate s is in lower half to prevent malleability
            require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
                    "Invalid signature s value");
            
            address recovered = txHash.toEthSignedMessageHash().recover(v, r, s);

            // Check this address hasn't been used yet
            for (uint8 k = 0; k < i; k++) {
                require(recovered != usedAddresses[k], "Duplicate signer");
            }
            usedAddresses[i] = recovered;

            for (uint8 j = 0; j < 3; j++) {
                if (recovered == owners[j] && !signed[j]) {
                    signed[j] = true;
                    count++;
                    break;
                }
            }
        }
    }

    /// @dev Split signature into r, s, v
    function _splitSignature(bytes calldata sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := calldataload(sig.offset)
            s := calldataload(add(sig.offset, 32))
            v := byte(0, calldataload(add(sig.offset, 64)))
        }
    }

    function getOwners() external view returns (address[] memory) {
        address[] memory owners = new address[](3);
        owners[0] = buyer;
        owners[1] = seller;
        owners[2] = arbiter;
        return owners;
    }

}