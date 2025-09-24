# Green Hash Credits (GHC)

**Sustainable Bitcoin Mining Credits - Tokenized Green Mining**

A Clarity smart contract that tokenizes verified "green hash power credits" from eco-friendly Bitcoin miners, enabling transparent trading and redemption of sustainable mining capacity.

## <1 Overview

Green Hash Credits creates a verifiable token economy around sustainable Bitcoin mining by:
- Certifying renewable energy-powered mining operations
- Issuing tradeable tokens representing verified hash power
- Enabling redemption for actual green mining services
- Providing transparent audit trails for all transactions

## ¡ Features

- **SIP-010 Compliant**: Standard fungible token with full interoperability
- **Miner Verification**: Authorized verifiers certify green mining operations
- **Credit Issuance**: Tokens minted for verified sustainable hash power
- **Service Redemption**: Convert tokens back to actual mining capacity
- **Governance Controls**: Owner management with pause/unpause functionality
- **Audit Trail**: Complete transaction history with event logging

## <× Contract Architecture

### Token Details
- **Name**: Green Hash Credits
- **Symbol**: GHC  
- **Decimals**: 6
- **Max Supply**: 1,000,000 GHC

### Core Functions
- `verify-miner`: Certify mining operations using renewable energy
- `issue-credits`: Mint tokens for verified miners
- `redeem-credits`: Burn tokens for mining services
- `transfer`: Standard token transfers
- Administrative functions for verifier and contract management

## =€ Quick Start

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
3. Redeem for actual sustainable mining capacity
4. Transfer to other participants

## =Ê Contract Interface

### Public Functions
```clarity
(verify-miner (miner principal) (hash-power uint) (energy-source (string-ascii 100)))
(issue-credits (miner principal) (credit-amount uint))
(redeem-credits (credit-id uint) (amount uint))
(transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
```

### Read-Only Functions
```clarity
(get-balance (who principal))
(get-miner-info (miner principal))
(is-verified-miner (miner principal))
(get-credit-info (credit-id uint))
```

## =á Security

- **Access Control**: Multi-role permission system
- **Validation**: Comprehensive input validation and balance checks
- **Pause Mechanism**: Emergency stop functionality
- **Audit Trail**: Full event logging for transparency
- **Testing**: 22 comprehensive test cases covering all functionality

## < Environmental Impact

Green Hash Credits incentivizes sustainable Bitcoin mining by:
- Creating market value for renewable energy usage
- Providing transparency in green mining operations  
- Enabling capital flows to eco-friendly miners
- Supporting the transition to sustainable Bitcoin mining

## =Ä License

This project is licensed under the ISC License.

## > Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## =Þ Support

For questions or support, please open an issue in the repository.