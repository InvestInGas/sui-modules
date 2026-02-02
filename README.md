# Sui Gas Oracle Module

Move module for storing gas price data on Sui blockchain.

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

### Switch to Testnet
```bash
sui client switch --env testnet
```

### 5. Get Testnet SUI
**Option A: Discord Faucet**
1. Join [Sui Discord](https://discord.gg/sui)
2. Go to `#testnet-faucet`
3. Type: `!faucet <YOUR_ADDRESS>`

**Option B: CLI Faucet**
```bash
sui client faucet
```

### 6. Verify Balance
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
| `update_gas_price` | Update single chain price |
| `batch_update_gas_prices` | Update all chains at once |
| `get_current_price` | Read current price |
| `get_buy_signal` | Check if good time to buy |
| `add_chain` | Add support for new chains dynamically |
