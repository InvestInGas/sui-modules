#!/bin/bash
# Sui Oracle Deployment Helper Script

set -e

echo "Sui Oracle Module Deployment Helper"
echo "================================"

# Check if Sui CLI is installed
if ! command -v sui &> /dev/null; then
    echo "Sui CLI not found. Refer README.md first"
    exit 1
fi

echo "Sui CLI found: $(sui --version)"

# Check current network
echo ""
echo "Current Network Configuration:"
sui client envs
echo ""

# Get active address
ADDRESS=$(sui client active-address)
echo "Active Address: $ADDRESS"

# Check balance
echo ""
echo "Balance:"
sui client gas

# Build the module
echo ""
echo "Building Move module..."
cd "$(dirname "$0")"
sui move build

echo ""
echo "Build successful!"
echo ""

# Confirm deployment
read -p "Deploy to testnet? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

# Deploy
echo ""
echo "Deploying to Sui testnet..."
OUTPUT=$(sui client publish --gas-budget 100000000 --json 2>&1)

# Parse output
echo ""
echo "Deployment Output:"
echo "$OUTPUT" | head -100

# Extract IDs (user needs to do this manually from output)
echo ""
echo "================================"
echo "IMPORTANT: Save these IDs from the output above:"
echo ""
echo "Look for 'objectChanges' in the JSON output:"
echo "  - 'packageId' → Your Package ID"
echo "  - Object with type '...::oracle::GasOracle' → Oracle Object ID"
echo "  - Object with type '...::oracle::OracleAdminCap' → Admin Cap ID"
echo "================================"
echo "Deployment complete!"
