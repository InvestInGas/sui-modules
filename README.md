# Sui Gas Oracle Module

Move module for storing gas price data on Sui blockchain.

> **Data Format:** Prices are stored in **wei** (u128) for full precision. Each chain has its own gas token (ETH, MATIC, USDC).

## Structure
```
sui-modules/
├── Move.toml           # Package manifest
├── deploy.sh           # Deployment helper
└── sources/
    └── gas_oracle.move # Oracle module
```

## Setup & Installation
                               
### Install Sui

First install Rust on your system.
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
                                   
Load Rust into your shell
```bash
source $HOME/.cargo/env
```

Verify Rust installation
```bash
rustc --version
cargo --version
rustup --version
```

Install `suiup`
```bash
curl -sSfL \
  https://raw.githubusercontent.com/Mystenlabs/suiup/main/install.sh \
  | sh
```

Then, Install Sui
```bash
suiup install sui@testnet
```

### Create Wallet
```bash
sui client new-address ed25519
```

### Manage Addresses
List all addresses:
```bash
sui client addresses
```

Check active address:
```bash
sui client active-address
```

Switch active address:
```bash
sui client switch --address <ADDRESS>
```

### Transfer SUI
To transfer SUI to another address:
```bash
sui client pay-sui --recipients <RECIPIENT_ADDRESS> --amounts <AMOUNT_IN_MIST>
```
*Note: 1 SUI = 1,000,000,000 MIST*

### Consolidate Funds
To merge all SUI coin objects into a single object (clean up wallet):
```bash
sui client pay-all-sui --recipient <YOUR_ADDRESS>
```

### Switch to Testnet
```bash
sui client switch --env testnet
```

### Get Testnet SUI
**Option A: Discord Faucet**
1. Join [Sui Discord](https://discord.gg/sui)
2. Go to `#testnet-faucet`
3. Type: `!faucet <YOUR_ADDRESS>`

**Option B: CLI Faucet**
```bash
sui client faucet
```

### Verify Balance
Check if you received the tokens:
```bash
sui client gas
```

You should see an object with a balance (e.g., `1000000000` MIST).

## Build & Deploy

### Build Module
```bash
# Navigate to this directory
cd sui-modules

# Build
sui move build
```

### Deploy
```bash
# Use the helper script
./deploy.sh

# OR manually:
sui client publish --gas-budget 100000000
```

## After Deployment

Save these IDs from the deployment output (JSON):
- `ORACLE_PACKAGE_ID`: The ID of the published package
- `ORACLE_OBJECT_ID`: The ID of the `GasOracle` object
- `ADMIN_CAP_ID`: The ID of the `OracleAdminCap` object

You will need these to configure your Bot `.env` file.

## Module Functions

| Function | Description |
|----------|-------------|
| `update_gas_price` | Update single chain price (wei, u128) |
| `batch_update_gas_prices` | Update all chains at once (wei, u128) |
| `get_current_price` | Read current price in wei |
| `get_gas_token` | Get gas token symbol (ETH, MATIC, USDC) |
| `get_price_data` | Get full price data including high/low |
| `get_buy_signal` | Check if good time to buy |
| `add_chain` | Add new chain with gas token |

## Supported Chains & Gas Tokens

| Chain | Gas Token |
|-------|----------|
| ethereum | ETH |
| base | ETH |
| arbitrum | ETH |
| polygon | MATIC |
| optimism | ETH |
| arc | USDC |
