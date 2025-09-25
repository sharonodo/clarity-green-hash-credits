# Green Hash Credits (GHC)

**Sustainable Bitcoin Mining Credits - Tokenized Green Mining**

A Clarity smart contract that tokenizes verified "green hash power credits" from eco-friendly Bitcoin miners, enabling transparent trading and redemption of sustainable mining capacity.

## <1 Overview

Green Hash Credits creates a verifiable token economy around sustainable Bitcoin mining by:
- Certifying renewable energy-powered mining operations
- Issuing tradeable tokens representing verified hash power
- Enabling redemption for actual green mining services
- Providing transparent audit trails for all transactions

## � Features

- **SIP-010 Compliant**: Standard fungible token with full interoperability
- **Miner Verification**: Authorized verifiers certify green mining operations
- **Credit Issuance**: Tokens minted for verified sustainable hash power
- **Service Redemption**: Convert tokens back to actual mining capacity
- **Credit Expiry**: Time-limited credits with configurable expiration periods
- **Miner History & Reputation**: Complete tracking of verification and redemption history
- **Dynamic Energy Sources**: Expandable list of approved renewable energy types
- **Governance Controls**: Owner management with pause/unpause functionality
- **Security Hardened**: Comprehensive input validation and burn address protection
- **Audit Trail**: Complete transaction history with event logging

## <� Contract Architecture

### Token Details
- **Name**: Green Hash Credits
- **Symbol**: GHC  
- **Decimals**: 6
- **Max Supply**: 1,000,000 GHC

### Core Functions
- `verify-miner`: Certify mining operations using renewable energy
- `issue-credits`: Mint tokens for verified miners with automatic expiry
- `redeem-credits`: Burn tokens for mining services (with expiry validation)
- `transfer`: Standard token transfers
- Administrative functions for verifier and contract management

### New Advanced Features

#### Credit Expiry System
- **Configurable Expiration**: Credits expire after a set number of blocks (default: 144 blocks ≈ 24 hours)
- **Expiry Validation**: Prevents redemption of expired credits
- **Cleanup Function**: Remove expired credits to optimize storage
- **Owner Controls**: Adjust expiry periods as needed

#### Miner History & Reputation
- **Verification History**: Track all miner verifications and hash power updates
- **Redemption History**: Complete record of credit redemptions by miner and redeemer
- **Transparency**: Full audit trail for accountability and trust
- **Query Functions**: Access historical data for analysis and reporting

#### Dynamic Energy Source Management  
- **Expandable Sources**: Owner can add new approved renewable energy types
- **Source Removal**: Remove energy sources that are no longer accepted
- **Default Sources**: Pre-approved sources include solar, wind, hydro, geothermal, and nuclear

## =� Quick Start

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Node.js 18+ for testing

### Installation
```bash
git clone <repository-url>
cd clarity-green-hash-credits/clarity-hash-cedits
npm install
```

### Testing
```bash
# Run all tests
npm test

# Run with coverage and costs
npm run test:report

# Watch for changes
npm run test:watch
```

### Deployment
```bash
clarinet deploy --testnet
```

## =' Usage

### For Mining Operators
1. Get verified by an authorized verifier
2. Receive GHC tokens based on your green hash power
3. Trade tokens on secondary markets
4. Redeem tokens for mining services

### For Verifiers
1. Get authorized by contract owner
2. Verify mining operations' renewable energy usage
3. Issue appropriate GHC tokens to verified miners
4. Update hash power as operations scale

### For Token Holders
1. Purchase GHC tokens from miners or markets
2. Hold as investment in green mining
3. Redeem for actual sustainable mining capacity (before expiry)
4. Transfer to other participants
5. Monitor credit expiry dates to avoid losing value

### For Contract Owners
1. Add/remove authorized verifiers
2. Manage approved renewable energy sources
3. Configure credit expiry periods based on market needs
4. Clean up expired credits to optimize contract storage
5. Pause contract operations in emergencies

### For Analysts & Auditors
1. Query verification history to track miner performance
2. Analyze redemption patterns and market dynamics
3. Monitor energy source adoption and trends
4. Generate transparency reports from historical data

## =� Contract Interface

### Core Public Functions
```clarity
;; Miner Management
(verify-miner (miner principal) (hash-power uint) (energy-source (string-ascii 100)))
(update-miner-hash-power (miner principal) (new-hash-power uint))

;; Credit Operations  
(issue-credits (miner principal) (credit-amount uint))
(redeem-credits (credit-id uint) (amount uint))
(transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))

;; Administrative Functions
(add-verifier (verifier principal))
(remove-verifier (verifier principal))
(pause-contract)
(unpause-contract)
```

### New Advanced Functions
```clarity
;; Credit Expiry Management
(set-credit-expiry-blocks (new-expiry-blocks uint))
(cleanup-expired-credit (credit-id uint))
(is-credit-expired (credit-id uint))

;; Energy Source Management  
(add-energy-source (energy-source (string-ascii 100)))
(remove-energy-source (energy-source (string-ascii 100)))
(is-energy-source-approved (energy-source (string-ascii 100)))
```

### Read-Only Functions
```clarity
;; Token Information
(get-balance (who principal))
(get-total-supply)
(get-name)
(get-symbol)
(get-decimals)

;; Miner Information
(get-miner-info (miner principal))
(is-verified-miner (miner principal))

;; Credit Information
(get-credit-info (credit-id uint))
(get-next-credit-id)
(get-credit-expiry-blocks)

;; History Queries
(get-verification-history (history-id uint))
(get-redemption-history (history-id uint))
(get-next-history-id)

;; System Status
(is-verifier (account principal))
(is-contract-paused)
```

## =� Security

- **Access Control**: Multi-role permission system with owner, verifiers, and users
- **Input Validation**: Comprehensive validation preventing malicious inputs
- **Burn Address Protection**: Prevents interactions with burn addresses
- **Principal Validation**: Sanitizes all principal inputs to prevent exploits
- **String Validation**: Length and format checks for all string inputs
- **Existence Checks**: Validates data exists before operations (prevents phantom operations)
- **Duplicate Prevention**: Blocks duplicate entries where inappropriate
- **Pause Mechanism**: Emergency stop functionality for all operations
- **Credit Expiry**: Prevents stale credit redemptions with automatic expiration
- **Audit Trail**: Full event logging with history tracking for complete transparency
- **Testing**: Comprehensive test suite covering all functionality and edge cases

### Security Improvements
- ✅ **12 Compiler Warnings Resolved**: All potentially unsafe operations now validated
- ✅ **Burn Address Protection**: Prevents token loss to burn addresses  
- ✅ **Input Sanitization**: All user inputs validated before processing
- ✅ **Access Control Hardening**: Enhanced permission checks with role validation
- ✅ **Data Integrity**: Existence checks prevent operations on non-existent data

## <
 Environmental Impact

Green Hash Credits incentivizes sustainable Bitcoin mining by:
- Creating market value for renewable energy usage
- Providing transparency in green mining operations  
- Enabling capital flows to eco-friendly miners
- Supporting the transition to sustainable Bitcoin mining

## =� License

This project is licensed under the ISC License.

## > Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## =� Support

For questions or support, please open an issue in the repository.