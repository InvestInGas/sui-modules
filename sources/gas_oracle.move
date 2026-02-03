/// Gas Oracle Module for InvestingAs
/// 
/// Provides high-frequency gas price feeds for multiple EVM chains.
/// Updated by an authorized oracle bot. 
/// Prices are stored in WEI for full precision.

module gas_oracle::oracle {
    use std::string::String;
    use sui::table::{Self, Table};
    use sui::clock::Clock;

    // ============ Constants ============
    
    /// Price staleness threshold (5 minutes in milliseconds)
    const STALENESS_THRESHOLD_MS: u64 = 300000;

    // ============ Errors ============
    
    const EChainNotSupported: u64 = 1;
    const EInvalidPrice: u64 = 3;

    // ============ Structs ============

    /// Admin capability for oracle updates
    public struct OracleAdminCap has key, store {
        id: UID,
    }

    /// Main oracle storage object
    public struct GasOracle has key {
        id: UID,
        /// Chain name -> GasPrice data
        prices: Table<String, GasPrice>,
        /// Supported chains list
        supported_chains: vector<String>,
        /// Last update timestamp (global)
        last_update_ms: u64,
        /// Total updates count
        update_count: u64,
    }

    /// Gas price data for a single chain
    public struct GasPrice has store, copy, drop {
        /// Current gas price in wei (smallest unit)
        price_wei: u128,
        /// Gas token symbol (ETH, MATIC, USDC, etc.)
        gas_token: String,
        /// 24-hour high price in wei
        high_24h: u128,
        /// 24-hour low price in wei
        low_24h: u128,
        /// Timestamp of this update (milliseconds)
        timestamp_ms: u64,
    }

    // ============ Events ============

    /// Emitted when gas price is updated
    public struct GasPriceUpdated has copy, drop {
        chain: String,
        old_price: u128,
        new_price: u128,
        gas_token: String,
        timestamp_ms: u64,
    }

    // ============ Init ============

    /// Initialize the oracle with admin cap and storage
    fun init(ctx: &mut TxContext) {
        // Create admin capability
        let admin_cap = OracleAdminCap {
            id: object::new(ctx),
        };
        
        // Create oracle storage
        let mut oracle = GasOracle {
            id: object::new(ctx),
            prices: table::new(ctx),
            supported_chains: vector::empty(),
            last_update_ms: 0,
            update_count: 0,
        };

        // Initialize supported chains with their gas tokens
        let chains = vector[
            b"ethereum".to_string(),
            b"base".to_string(),
            b"arbitrum".to_string(),
            b"polygon".to_string(),
            b"optimism".to_string(),
            b"arc".to_string(),
        ];
        
        let gas_tokens = vector[
            b"ETH".to_string(),
            b"ETH".to_string(),
            b"ETH".to_string(),
            b"MATIC".to_string(),
            b"ETH".to_string(),
            b"USDC".to_string(),
        ];

        let mut i = 0;
        while (i < vector::length(&chains)) {
            let chain = *vector::borrow(&chains, i);
            let gas_token = *vector::borrow(&gas_tokens, i);
            vector::push_back(&mut oracle.supported_chains, chain);
            
            // Initialize with zero price (will be updated by bot)
            table::add(&mut oracle.prices, chain, GasPrice {
                price_wei: 0,
                gas_token,
                high_24h: 0,
                low_24h: 0,
                timestamp_ms: 0,
            });
            
            i = i + 1;
        };

        // Transfer admin cap to deployer
        transfer::transfer(admin_cap, ctx.sender());
        
        // Share oracle object
        transfer::share_object(oracle);
    }

    // ============ Update Functions ============

    /// Update gas price for a single chain
    public fun update_gas_price(
        _admin: &OracleAdminCap,
        oracle: &mut GasOracle,
        clock: &Clock,
        chain: String,
        price_wei: u128,
        high_24h: u128,
        low_24h: u128,
    ) {
        assert!(table::contains(&oracle.prices, chain), EChainNotSupported);
        assert!(price_wei > 0, EInvalidPrice);

        let current_time = clock.timestamp_ms();
        let old_price_data = table::borrow(&oracle.prices, chain);
        let old_price = old_price_data.price_wei;
        let gas_token = old_price_data.gas_token;

        // Update price
        let new_price = GasPrice {
            price_wei,
            gas_token,
            high_24h,
            low_24h,
            timestamp_ms: current_time,
        };

        // Remove old and add new
        table::remove(&mut oracle.prices, chain);
        table::add(&mut oracle.prices, chain, new_price);

        // Update global state
        oracle.last_update_ms = current_time;
        oracle.update_count = oracle.update_count + 1;

        // Emit event
        sui::event::emit(GasPriceUpdated {
            chain,
            old_price,
            new_price: price_wei,
            gas_token,
            timestamp_ms: current_time,
        });
    }

    /// Batch update gas prices for multiple chains
    public fun batch_update_gas_prices(
        admin: &OracleAdminCap,
        oracle: &mut GasOracle,
        clock: &Clock,
        chains: vector<String>,
        prices_wei: vector<u128>,
    ) {
        let len = vector::length(&chains);
        assert!(vector::length(&prices_wei) == len, EInvalidPrice);

        let mut i = 0;
        while (i < len) {
            let chain = *vector::borrow(&chains, i);
            let price = *vector::borrow(&prices_wei, i);

            update_gas_price(
                admin,
                oracle,
                clock,
                chain,
                price,
                price, // high = current for batch
                price, // low = current for batch
            );

            i = i + 1;
        };
    }

    // ============ View Functions ============

    /// Get current gas price for a chain
    public fun get_current_price(oracle: &GasOracle, chain: String): u128 {
        assert!(table::contains(&oracle.prices, chain), EChainNotSupported);
        let price_data = table::borrow(&oracle.prices, chain);
        price_data.price_wei
    }

    /// Get gas token for a chain
    public fun get_gas_token(oracle: &GasOracle, chain: String): String {
        assert!(table::contains(&oracle.prices, chain), EChainNotSupported);
        let price_data = table::borrow(&oracle.prices, chain);
        price_data.gas_token
    }

    /// Get full price data for a chain
    public fun get_price_data(oracle: &GasOracle, chain: String): GasPrice {
        assert!(table::contains(&oracle.prices, chain), EChainNotSupported);
        *table::borrow(&oracle.prices, chain)
    }

    /// Check if price is stale
    public fun is_price_stale(oracle: &GasOracle, chain: String, clock: &Clock): bool {
        assert!(table::contains(&oracle.prices, chain), EChainNotSupported);
        let price_data = table::borrow(&oracle.prices, chain);
        let current_time = clock.timestamp_ms();
        
        current_time - price_data.timestamp_ms > STALENESS_THRESHOLD_MS
    }

    /// Calculate if now is a good time to buy (price below 24h average)
    /// Returns (is_good_time, savings_percent)
    public fun get_buy_signal(oracle: &GasOracle, chain: String): (bool, u64) {
        assert!(table::contains(&oracle.prices, chain), EChainNotSupported);
        let price_data = table::borrow(&oracle.prices, chain);
        
        // Calculate approximate 24h average from high and low
        let avg_24h = (price_data.high_24h + price_data.low_24h) / 2;
        
        if (avg_24h == 0 || price_data.price_wei >= avg_24h) {
            return (false, 0)
        };

        // Calculate savings percentage
        let savings = (((avg_24h - price_data.price_wei) * 100) / avg_24h as u64);
        
        // Good time to buy if savings > 10%
        (savings > 10, savings)
    }

    /// Get all supported chains
    public fun get_supported_chains(oracle: &GasOracle): vector<String> {
        oracle.supported_chains
    }

    /// Get total update count
    public fun get_update_count(oracle: &GasOracle): u64 {
        oracle.update_count
    }

    /// Get last global update timestamp
    public fun get_last_update(oracle: &GasOracle): u64 {
        oracle.last_update_ms
    }

    // ============ Admin Functions ============

    /// Add a new supported chain with its gas token
    public fun add_chain(
        _admin: &OracleAdminCap,
        oracle: &mut GasOracle,
        chain: String,
        gas_token: String,
    ) {
        if (!table::contains(&oracle.prices, chain)) {
            vector::push_back(&mut oracle.supported_chains, chain);
            table::add(&mut oracle.prices, chain, GasPrice {
                price_wei: 0,
                gas_token,
                high_24h: 0,
                low_24h: 0,
                timestamp_ms: 0,
            });
        };
    }

    // ============ Test Functions ============
    
    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx);
    }
}
