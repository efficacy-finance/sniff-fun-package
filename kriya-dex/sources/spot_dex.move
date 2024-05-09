module kriya::spot_dex {
    use sui::object::{Self, UID, ID};
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::balance::{Self, Supply, Balance};
    use sui::transfer;
    use sui::math;
    use sui::table::{Self, Table};
    use sui::tx_context::{Self, TxContext};
    use sui::event;
    use kriya::safe_math;
    use kriya::utils;

    /// For when supplied Coin is zero.
    const EZeroAmount: u64 = 0;
    /// Allowed values are: [0-10000).
    const EWrongFee: u64 = 1;
    const EReservesEmpty: u64 = 2;
    const EInsufficientBalance: u64 = 3;
    const ELiquidityInsufficientBAmount: u64 = 4;
    const ELiquidityInsufficientAAmount: u64 = 5;
    const ELiquidityOverLimitADesired: u64 = 6;
    const ELiquidityInsufficientMinted: u64 = 7;
    const ESwapOutLessthanExpected: u64 = 8;
    const EUnauthorized: u64 = 9;
    const ECallerNotAdmin: u64 = 10;
    const ESwapDisabled: u64 = 11;
    const EAddLiquidityDisabled: u64 = 12;
    const EAlreadyWhitelisted: u64 = 13;
    /// When not enough liquidity minted.
    const ENotEnoughInitialLiquidity: u64 = 14;
    const ERemoveAdminNotAllowed: u64 = 15;
    const EIncorrectPoolConstantPostSwap: u64 = 16;
    const EFeeInvalid: u64 = 17;
    const EAmountZero: u64 = 18;
    const EReserveZero: u64 = 19;
    const EInvalidLPToken: u64 = 20;

    /// The integer scaling setting for fees calculation.
    const FEE_SCALING: u128 = 1000000;
    
    /// Minimal liquidity.
    const MINIMAL_LIQUIDITY: u64 = 1000;

    /// The Pool token_x that will be used to mark the pool share
    /// of a liquidity provider. The first type parameter stands
    /// for the witness type of a pool. The seconds is for the
    /// coin held in the pool.
    struct LSP<phantom X, phantom Y> has drop {}
    struct KriyaLPToken<phantom X, phantom Y> has key, store {
        id: UID,
        pool_id: ID,
        lsp: Coin<LSP<X, Y>>
    }

    struct ProtocolConfigs has key {
        id: UID,
        protocol_fee_percent_uc: u64,
        lp_fee_percent_uc: u64,
        protocol_fee_percent_stable: u64,
        lp_fee_percent_stable: u64,
        is_swap_enabled: bool,
        is_deposit_enabled: bool,
        is_withdraw_enabled: bool,
        admin: address,
        whitelisted_addresses: Table<address, bool>
    }

    /// Kriya AMM Pool object.
    struct Pool<phantom X, phantom Y> has key {
        id: UID,
        /// Balance of Coin<Y> in the pool.
        token_y: Balance<Y>,
        /// Balance of Coin<X> in the pool.
        token_x: Balance<X>,
        /// LP total supply share.
        lsp_supply: Supply<LSP<X, Y>>,
        /// Minimum required liquidity, non-withdrawable
        lsp_locked: Balance<LSP<X, Y>>,
        /// LP fee percent. Range[1-10000] (30 -> 0.3% fee)
        lp_fee_percent: u64,
        /// Protocol fee percent. Range[1-10000] (30 -> 0.3% fee)
        protocol_fee_percent: u64,
        /// Protocol fee pool to hold collected Coin<X> as fee.
        protocol_fee_x: Balance<X>,
        /// Protocol fee pool to hold collected Coin<Y> as fee.
        protocol_fee_y: Balance<Y>,
        /// If the pool uses the table_curve_formula
        is_stable: bool,
        /// 10^ Decimals of Coin<X>
        scaleX: u64,
        /// 10^ Decimals of Coin<Y>
        scaleY: u64,
        /// if trading is active for this pool
        is_swap_enabled: bool,
        /// if adding liquidity is enabled
        is_deposit_enabled: bool,
        /// if removing liquidity is enabled
        is_withdraw_enabled: bool
    }

    /* Events */

    struct PoolCreatedEvent has drop, copy {
        pool_id: ID,
        creator: address,
        lp_fee_percent: u64,
        protocol_fee_percent: u64,
        is_stable: bool,
        scaleX: u64,
        scaleY: u64
    }

    struct PoolUpdatedEvent has drop, copy {
        pool_id: ID,
        lp_fee_percent: u64,
        protocol_fee_percent: u64,
        is_stable: bool,
        scaleX: u64,
        scaleY: u64
    }

    struct LiquidityAddedEvent has drop, copy {
        pool_id: ID,
        liquidity_provider: address,
        amount_x: u64,
        amount_y: u64,
        lsp_minted: u64
    }

    struct LiquidityRemovedEvent has drop, copy {
        pool_id: ID,
        liquidity_provider: address,
        amount_x: u64,
        amount_y: u64,
        lsp_burned: u64
    }

    struct SwapEvent<phantom T> has drop, copy {
        pool_id: ID,
        user: address,
        reserve_x: u64,
        reserve_y: u64,
        amount_in: u64,
        amount_out: u64
    }

    struct ConfigUpdatedEvent has drop, copy {
        protocol_fee_percent_uc: u64,
        lp_fee_percent_uc: u64,
        protocol_fee_percent_stable: u64,
        lp_fee_percent_stable: u64,
        is_swap_enabled: bool,
        is_deposit_enabled: bool,
        is_withdraw_enabled: bool,
        admin: address
    }

    struct WhitelistUpdatedEvent has drop, copy {
        addr: address,
        is_whitelisted: bool
    }

    /* Entry Functions */

    /// Entry function for create new `Pool` for Coin<X> & Coin<Y>. Each Pool holds a `Coin<X>`
    /// and a `Coin<Y>`. Swaps are available in both directions.
    ///
    /// TODO: this should be create_pool and internal function should have the trailing '_'
    public entry fun create_pool_<X, Y>(
        protocol_configs: &ProtocolConfigs,
        is_stable: bool,
        coin_metadata_x: &CoinMetadata<X>,
        coin_metadata_y: &CoinMetadata<Y>,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Create new `Pool` for Coin<X> & Coin<Y>. Each Pool holds a `Coin<X>`
    /// and a `Coin<Y>`. Swaps are available in both directions.
    /// todo: check if witness object needs to be passed to make it admin only.
    public fun create_pool<X, Y>(
        protocol_configs: &ProtocolConfigs,
        is_stable: bool,
        coin_metadata_x: &CoinMetadata<X>,
        coin_metadata_y: &CoinMetadata<Y>,
        ctx: &mut TxContext
    ): Pool<X, Y> {
        abort 0
    }

    /// Entrypoint for the `swap_token_y` method. Sends swapped token_x
    /// to sender.
    public entry fun swap_token_y_<X, Y>(
        pool: &mut Pool<X, Y>, token_y: Coin<Y>, amount_y: u64, min_recieve_x: u64, ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Swap `Coin<Y>` for the `Coin<X>`.
    /// Returns Coin<X>.
    public fun swap_token_y<X, Y>(
        pool: &mut Pool<X, Y>, token_y: Coin<Y>, amount: u64, min_recieve_x: u64, ctx: &mut TxContext
    ): Coin<X> {
        abort 0
    }

    /// Entry point for the `swap_token_x` method. Sends swapped token_y
    /// to the sender.
    public entry fun swap_token_x_<X, Y>(
        pool: &mut Pool<X, Y>, token_x: Coin<X>, amount: u64, min_recieve_y: u64, ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Swap `Coin<X>` for the `Coin<Y>`.
    /// Returns the swapped `Coin<Y>`.
    public fun swap_token_x<X, Y>(
        pool: &mut Pool<X, Y>, token_x: Coin<X>, amount: u64, min_recieve_y: u64, ctx: &mut TxContext
    ): Coin<Y> {
        abort 0
    }

    /// Entrypoint for the `add_liquidity` method. Sends `Coin<LSP>` to
    /// the transaction sender.
    public entry fun add_liquidity_<X, Y>(
        pool: &mut Pool<X, Y>, 
        token_y: Coin<Y>,
        token_x: Coin<X>, 
        token_y_amount: u64,
        token_x_amount: u64,
        amount_y_min_deposit: u64,
        amount_x_min_deposit: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Add liquidity to the `Pool`. Sender needs to provide both
    /// `Coin<Y>` and `Coin<X>`, and in exchange he gets `Coin<LSP>` -
    /// liquidity provider tokens.
    public fun add_liquidity<X, Y>(
        pool: &mut Pool<X, Y>, 
        token_y: Coin<Y>, 
        token_x: Coin<X>, 
        token_y_amount: u64,
        token_x_amount: u64,
        amount_y_min_deposit: u64,
        amount_x_min_deposit: u64,
        ctx: &mut TxContext
    ): KriyaLPToken<X, Y> {
        abort 0
    }

    /// Entrypoint for the `remove_liquidity` method. Transfers
    /// withdrawn assets to the sender.
    public entry fun remove_liquidity_<X, Y>(
        pool: &mut Pool<X, Y>,
        lp_token: KriyaLPToken<X, Y>,
        amount: u64,
        ctx: &mut TxContext
    ) {
        abort 0
    }

    /// Remove liquidity from the `Pool` by burning `Coin<LSP>`.
    /// Returns `Coin<X>` and `Coin<Y>`.
    public fun remove_liquidity<X, Y>(
        pool: &mut Pool<X, Y>,
        lp_token: KriyaLPToken<X, Y>,
        amount: u64,
        ctx: &mut TxContext
    ): (Coin<Y>, Coin<X>) {
        abort 0
    }

    /* Public geters */

    /// Get TokenX/Y balance & treasury cap. A Getter function to get frequently get values:
    /// - amount of token_y
    /// - amount of token_x
    /// - total supply of LSP
    public fun get_reserves<X, Y>(pool: &Pool<X, Y>): (u64, u64, u64) {
        (
            balance::value(&pool.token_y),
            balance::value(&pool.token_x),
            balance::supply_value(&pool.lsp_supply)
        )
    }

    public fun lp_token_split<X, Y>(self: &mut KriyaLPToken<X, Y>, split_amount: u64, ctx: &mut TxContext): KriyaLPToken<X, Y> {
        KriyaLPToken {
            id: object::new(ctx),
            pool_id: self.pool_id,
            lsp: coin::split(&mut self.lsp, split_amount, ctx)
        }
    }

    public fun lp_token_join<X, Y>(self: &mut KriyaLPToken<X, Y>, lp_token: KriyaLPToken<X, Y>) {
        assert!(self.pool_id == lp_token.pool_id, EInvalidLPToken);
        let KriyaLPToken {id, pool_id: _, lsp} = lp_token;
        object::delete(id);
        coin::join(&mut self.lsp, lsp);
    }

    public fun lp_token_value<X, Y>(self: &KriyaLPToken<X, Y>): u64 {
        coin::value(&self.lsp)
    }

    public fun lp_destroy_zero<X, Y>(self: KriyaLPToken<X, Y>) {
        let KriyaLPToken {id, pool_id: _, lsp} = self;
        coin::destroy_zero(lsp);
        object::delete(id);
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(ctx)
    }

    #[test_only]
    public fun mint_lp_token<X, Y>(lsp: Coin<LSP<X, Y>>, pool: &Pool<X, Y>, ctx: &mut TxContext): KriyaLPToken<X, Y> {
        KriyaLPToken<X, Y> {
            id: object::new(ctx),
            pool_id: *object::uid_as_inner(&pool.id),
            lsp: lsp
        }
    }
}