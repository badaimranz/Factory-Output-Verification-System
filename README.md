# 🏭 Factory Output Verification System

A blockchain-based smart contract solution for verifying product batch authenticity and reducing counterfeits. Built with Clarity on the Stacks blockchain.

## 📋 Overview

The Factory Output Verification System enables manufacturers to register product batches on-chain, providing a transparent and immutable record of production. Authorized verifiers can validate batches, and consumers can scan products to verify authenticity.

## ✨ Features

- 🔐 **Manufacturer Registration**: Only authorized manufacturers can register batches
- 📦 **Batch Management**: Register product batches with detailed metadata
- ✅ **Verification System**: Authorized verifiers approve or reject batches
- 📊 **Scan Tracking**: Track how many times a batch has been scanned
- 🚨 **Recall Management**: Manufacturers and contract owner can recall batches
- 📜 **Audit Trail**: Complete history of all batch actions
- ⏰ **Expiry Tracking**: Automatic validation based on expiry dates

## 🚀 Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Basic understanding of Clarity smart contracts

### Installation

```bash
# Clone the repository
git clone https://github.com/badaimranz/Factory-Output-Verification-System.git
cd Factory-Output-Verification-System

# Check contract syntax
clarinet check

# Run tests
npm install
npm test
```

## 📖 Contract Functions

### 🔧 Admin Functions

#### `register-manufacturer`
Register a new manufacturer to allow batch registration.
```clarity
(contract-call? .Factory-Output-Verification-System register-manufacturer 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### `register-verifier`
Authorize a verifier to approve/reject batches.
```clarity
(contract-call? .Factory-Output-Verification-System register-verifier 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### `revoke-manufacturer` / `revoke-verifier`
Remove authorization from manufacturers or verifiers.

### 🏭 Manufacturer Functions

#### `register-batch`
Register a new product batch with production details.
```clarity
(contract-call? .Factory-Output-Verification-System register-batch 
  "Widget-Pro-2025" 
  u1000 
  u1000 
  u2000 
  "QmX8G3vF9nK2pL7mH4jR1qS6tU5wV0xY8zA3bC9dE2fG4h")
```

**Parameters:**
- `product-name`: Product identifier (max 100 characters)
- `quantity`: Number of units in batch
- `production-date`: Production block height
- `expiry-date`: Expiry block height
- `metadata-hash`: IPFS hash or other metadata reference

#### `recall-batch`
Recall a batch with a specified reason.
```clarity
(contract-call? .Factory-Output-Verification-System recall-batch u1 "Quality control issue detected")
```

### ✅ Verifier Functions

#### `verify-batch`
Verify or reject a pending batch.
```clarity
(contract-call? .Factory-Output-Verification-System verify-batch u1 true)
```

### 🔍 Public Functions

#### `scan-batch`
Scan a batch to verify authenticity (available to anyone).
```clarity
(contract-call? .Factory-Output-Verification-System scan-batch u1)
```

**Returns:**
- `valid`: Whether batch is valid and not expired
- `status`: Current batch status
- `manufacturer`: Batch manufacturer address
- `product-name`: Product name
- `scan-number`: Total number of scans

### 📊 Read-Only Functions

#### `get-batch-info`
Retrieve complete batch information.
```clarity
(contract-call? .Factory-Output-Verification-System get-batch-info u1)
```

#### `get-batch-history`
Get history entry for a specific batch and sequence.
```clarity
(contract-call? .Factory-Output-Verification-System get-batch-history u1 u0)
```

#### `get-scan-count`
Get total number of times a batch has been scanned.
```clarity
(contract-call? .Factory-Output-Verification-System get-scan-count u1)
```

#### `is-manufacturer` / `is-authorized-verifier`
Check if an address is authorized.
```clarity
(contract-call? .Factory-Output-Verification-System is-manufacturer 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

#### `is-batch-valid`
Check if batch is valid (not expired and status is verified/pending).
```clarity
(contract-call? .Factory-Output-Verification-System is-batch-valid u1)
```

#### `get-manufacturer-batch-count`
Get total number of batches registered by a manufacturer.

#### `get-manufacturer-batch`
Retrieve a specific batch ID by manufacturer and index.

## 📐 Batch Status Codes

- `0` - **PENDING**: Awaiting verification
- `1` - **VERIFIED**: Approved by authorized verifier
- `2` - **REJECTED**: Failed verification
- `3` - **RECALLED**: Recalled by manufacturer or contract owner

## 🛡️ Security Features

- ✅ Only contract owner can register/revoke manufacturers and verifiers
- ✅ Only authorized manufacturers can register batches
- ✅ Only authorized verifiers can verify batches
- ✅ Only manufacturer or contract owner can recall batches
- ✅ Automatic expiry validation
- ✅ Immutable audit trail

## 🔄 Typical Workflow

1. **Contract Owner** registers a manufacturer
2. **Contract Owner** registers authorized verifiers
3. **Manufacturer** registers a product batch
4. **Verifier** reviews and approves/rejects the batch
5. **Consumer** scans the batch QR code to verify authenticity
6. **System** tracks all scans and validates batch status

## ⚠️ Error Codes

- `u100` - Unauthorized access
- `u101` - Batch already exists
- `u102` - Batch not found
- `u103` - Invalid quantity (must be > 0)
- `u104` - Batch already verified
- `u105` - Not a registered manufacturer
- `u106` - Invalid status
- `u107` - Batch expired
- `u108` - Not an authorized verifier

## 🧪 Testing

```bash
# Install dependencies
npm install

# Run tests
npm test

# Check contract syntax
clarinet check
```

## 📄 License

This project is open source and available under the MIT License.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📞 Support

For questions or support, please open an issue on GitHub.

---

Built with ❤️ using Clarity and Stacks
