# Sui Gas Oracle Module

The **Sui Gas Oracle Module** is a high-performance price feed provider deployed on the Sui blockchain. It stores real-time gas price data for multiple EVM chains (in wei) and provides advanced features like buy signals and 24-hour price tracking.

## Module Structure (`sources/`)

### `gas_oracle.move`
The core smart contract logic for the oracle.
- **Data Precision**: Stores gas prices in `u128` (wei) to ensure full precision across all chains.
- **Multi-Chain Support**: Tracks data for Ethereum, Base, Arbitrum, Polygon (MATIC), and Optimism.
- **Price Tracking**: Maintains 24-hour high and low prices for each chain.
- **Buy Signals**: Implements `get_buy_signal` which detects if current gas prices are significantly lower (>10%) than the 24h average.
- **Authorization**: Uses an `OracleAdminCap` to restrict price updates to authorized bots.
- **Staleness Protection**: Includes checks to verify that price data has been updated within a 5-minute threshold.

## Scripts (`src/`)

### `deploy.sh`
A comprehensive bash script to simplify the deployment of the Move module.
- **System Checks**: Verifies Sui CLI installation and current network configuration.
- **Automated Build**: Triggers `sui move build` before deployment.
- **Deployment**: Publishes the package to Sui Testnet with appropriate gas budgets.
- **Configuration Guide**: Provides instructions on extracting `ORACLE_PACKAGE_ID`, `ORACLE_OBJECT_ID`, and `ADMIN_CAP_ID` from the JSON response.

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

You will need these to configure your Bot `.env` and Relayer `.env` files.

## Module Functions

| Function | Description |
|----------|-------------|
| `update_gas_price` | Update single chain price (wei, u128) |
| `batch_update_gas_prices` | Update all chains at once (wei, u128) |
| `get_current_price` | Read current price in wei |
| `get_gas_token` | Get gas token symbol (ETH, MATIC, etc.) |
| `get_price_data` | Get full price data including high/low |
| `get_buy_signal` | Check if good time to buy (>10% cheaper than avg) |
| `add_chain` | Add new chain with gas token |

## Supported Chains & Gas Tokens

| Chain | Gas Token | Chain ID |
|-------|-----------|----------|
| **ethereum** | ETH | 11155111 (Sepolia) |
| **base** | ETH | 84532 (Sepolia) |
| **arbitrum** | ETH | 421614 (Sepolia) |
| **polygon** | MATIC | 80002 (Amoy) |
| **optimism** | ETH | 11155420 (Sepolia) |

