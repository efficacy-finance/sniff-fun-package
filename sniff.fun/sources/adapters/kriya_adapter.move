module sniff_dot_fun::kriya_adapter {
    use sui::coin::{Self, Coin};
    use sui::balance::{Self, Balance};
    use sui::sui::{SUI};
    use kriya::spot_dex::{Self, Pool, KriyaLPToken};
    use sniff_dot_fun::freezer;
    use sniff_dot_fun::safu_receipt::{Self, SafuReceipt};

    // constants
    const AdapterId: u64 = 0;

    // error codes
    const EInvalidAdapter: u64 = 0;

    public fun process<T>(
        receipt: &mut SafuReceipt<T>, 
        pool: &mut Pool<SUI, T>,
        ctx: &mut TxContext
    ) {
        assert!(safu_receipt::target<T>(receipt) == AdapterId, EInvalidAdapter);
        
        let (sui_balance, meme_balance) = safu_receipt::extract_assets(receipt);
        let (
            base_coin,
            meme_coin,
            base_val,
            meme_val
        ) = to_coins(sui_balance, meme_balance, ctx);

        let lp_token = spot_dex::add_liquidity<SUI, T>(
            pool,
            meme_coin, // token_y
            base_coin, // token_x
            meme_val, // token_y_amount
            base_val, // token_x_amount
            meme_val, // amount_y_min_deposit
            base_val, // amount_x_min_deposit
            ctx
        );
        freezer::freeze_object<KriyaLPToken<SUI, T>>(lp_token, ctx);
    }

    fun to_coins<A, B>(
        balance_a: Balance<A>, 
        balance_b: Balance<B>, 
        ctx: &mut TxContext
    ): (Coin<A>, Coin<B>, u64, u64) {
        let val_a = balance::value<A>(&balance_a);
        let val_b = balance::value<B>(&balance_b);
        let coin_a = coin::from_balance<A>(balance_a, ctx);
        let coin_b = coin::from_balance<B>(balance_b, ctx);

        (coin_a, coin_b, val_a, val_b)
    }
}