contract;

use std::{
    auth::*,
    address::Address,
    assert::assert,
    block::*,
    context::*,
    contract_id::*,
    constants::ZERO_B256,
    external::bytecode_root,
    hash::*,
    result::*,
    revert::revert,
    storage::*,
    token::*,
    u256::U256,
    call_frames::*,
    //auth::*,
    //call_frames::{contract_id, msg_asset_id},,
};

use ido_abi::*;
use fee_model_abi::*;
use pricing_lib::*;
use vending_machine_abi::*;

// const I_MAX = 1000000000000000000000000000000000000;
const I_MAX = U256::from((0,0,54210108624275221, 12919594847110692864)); // TODO: should be 1e36
const K_MAX = U256::from((0,0,0,1000000000000000000));
const FINNEY = U256::from((0,0,0,1000000000000000000));
const DECIMAL_ONE:U256 = U256::from((0,0,0,1000000000000000000));
// const DECIMAL_ONE2 = 1000000000000000000000000000000000000;
const DECIMAL_ONE2 = U256::from((0,0,54210108624275221, 12919594847110692864)); // TODO: should be 1e36
const ONE = U256::from((0,0,0,1));

pub enum IdoError {
  ListLengthError: (),
  IValueError: (),
  KValueError: (),
  CliffRateError: (),
  TokenCliffRateError: (),
  Freezed: (), 
  ClaimFreezed: (),
  NotOwner: (),
  NotPhaseBid: (),
  SharesNotEnough: (),
  NotPhaseBidOrCalm: (),
  NotPhaseExe: (),
  AlreadySettled: (),
}

storage {
    initialized: bool = false,

    // TODO: is 200 * finney in solidity
    settled_fund:u64 = 200,
    force_stop: bool = false,

    // address list
    owner: b256 = ZERO_B256,
    maintainer: b256 = ZERO_B256,
    base_token: b256 = ZERO_B256,
    quote_token: b256 = ZERO_B256,
    fee_model: b256 = ZERO_B256,
    pool: b256 = ZERO_B256,

    // timeline
    bid_start_time: U256 = U256::new(),
    bid_end_time: U256 = U256::new(),
    calm_end_time: U256 = U256::new(),
    freeze_duration: U256 = U256::new(),
    vesting_duration: U256 = U256::new(),
    claim_freeze_duration: U256 = U256::new(),
    claim_vesting_duration: U256 = U256::new(),
    settled_time: U256 = U256::new(),

    settled: bool = false,
    total_base: U256 = U256::new(),

    // value list
    pool_quote_cap: U256 = U256::new(),
    K: U256 = U256::new(),
    I: U256 = U256::new(),
    lp_cliff_rate: U256 = U256::new(),
    token_cliff_rate: U256 = U256::new(),
    lp_fee_rate: U256 = U256::new(),

    // switches
    is_open_twap: bool = false,
    is_overcap_stop: bool = false,

    // settlement
    quote_reserve: U256 = U256::new(),
    unused_base: U256 = U256::new(),
    unused_quote: U256 = U256::new(),
    total_shares: U256 = U256::new(),
    shares: StorageMap<b256, U256> = StorageMap {},
    claimed_quote: StorageMap<b256, bool> = StorageMap {},
    avg_settled_price: U256 = U256::new(),

    // lp token vesting & claim params
    total_lp_amount: U256 = U256::new(),
    token_claim_duration: U256 = U256::new(),
    token_vesting_duration: U256 = U256::new(), 
    claimed_base_token: StorageMap<b256, U256> = StorageMap {},
    exps: (u64, u64, u64, u64, u64, u64) = (0,0,0,0,0,0,),
}

// helper function 
#[storage(read)]
fn transfer_quote_out(to: Identity, amount: U256) {
    if (amount > U256::min()) {
        let quote_token = ContractId::from(storage.quote_token);

        let amount_transfer = amount.as_u64();
        assert(!amount_transfer.is_err());
        transfer(amount_transfer.unwrap(), quote_token, to);
    }
}

#[storage(read)]
fn transfer_base_out(to: Identity, amount: U256) {
    if (amount > U256::min()) {
        let base_token = ContractId::from(storage.base_token);

        let amount_transfer = amount.as_u64();
        assert(!amount_transfer.is_err());
        transfer(amount_transfer.unwrap(), base_token, to);
    }
}

#[storage(read, write)]
fn mint_shares(to: b256, amount: U256) {
    storage.shares.insert(to, storage.shares.get(to).unwrap_or(U256::min()) + amount);
    storage.total_shares = storage.total_shares + amount;
}

#[storage(read, write)]
fn sync() {
    let quote_token = ContractId::from(storage.quote_token);
    let quote_balance = U256::from((0,0,0,this_balance(quote_token)));
    if (quote_balance != storage.quote_reserve) {
        storage.quote_reserve = quote_balance;
    }
}

#[storage(read, write)]
fn settle_(time_stamp: U256) {
    require(!storage.settled, IdoError::AlreadySettled);
    storage.settled = true;
    storage.settled_time = time_stamp;
}

#[storage(read)]
fn get_claimable_token_(user_address: b256) -> (U256, U256) {
    let curr_timestamp = U256::from((0,0,0,timestamp()));
    require(storage.settled && curr_timestamp > storage.settled_time + storage.token_claim_duration || storage.settled && curr_timestamp == storage.settled_time + storage.token_claim_duration, IdoError::ClaimFreezed);

    // claimable base token 
    let base_total_amount = storage.unused_base * storage.shares.get(user_address).unwrap() / storage.total_shares;
    let time_past = curr_timestamp - (storage.settled_time + storage.token_claim_duration);
    let mut remaining_base_token_ratio = U256::new();
    if (time_past < storage.token_vesting_duration) {
        let remaining_time = storage.token_vesting_duration - time_past;
        remaining_base_token_ratio = (DECIMAL_ONE - storage.token_cliff_rate) * remaining_time / storage.token_vesting_duration;
    }

    // multi floor
    let remaining_base_token = remaining_base_token_ratio * base_total_amount / DECIMAL_ONE;
    let claimed_base_token = storage.claimed_base_token.get(user_address).unwrap_or(U256::min());
    let claimable_base_token = base_total_amount - remaining_base_token - claimed_base_token;

    // TODO: No claimable quote token function
    let claimable_tokens = (claimable_base_token, U256::min());
    claimable_tokens
}

#[storage(read)]
fn get_lp_token_claimable_() -> U256 {
    let curr_timestamp = U256::from((0,0,0,timestamp()));
    require(storage.settled && curr_timestamp > storage.settled_time + storage.freeze_duration || storage.settled && curr_timestamp == storage.settled_time + storage.freeze_duration, IdoError::Freezed);

    let time_past = curr_timestamp - (storage.settled_time + storage.freeze_duration);
    let mut remaining_lp_ratio = U256::new();
    if (time_past < storage.vesting_duration) {
        let remaining_time = storage.vesting_duration - time_past;
        remaining_lp_ratio = (DECIMAL_ONE - storage.lp_cliff_rate) * remaining_time / storage.vesting_duration;
    }

    let remaining_lp_token = remaining_lp_ratio * storage.total_lp_amount / DECIMAL_ONE;
    let pool_contract_id = ContractId::from(storage.pool);
    let claimable_lp_token = U256::from((0,0,0,this_balance(pool_contract_id))) - remaining_lp_token;

    claimable_lp_token
}

#[storage(read)]
fn get_settle_result_() -> (U256, U256, U256, U256, U256) {
    let quote_token = ContractId::from(storage.quote_token);
    let base_token = ContractId::from(storage.base_token);

    let mut pool_quote = U256::from((0,0,0,this_balance(quote_token)));
    if (pool_quote > storage.pool_quote_cap) {
        pool_quote = storage.pool_quote_cap;
    }

    // // TODO: implement pmm pricing?
    let sold_base = sell_quote_token(pool_quote);
    let pool_base = storage.total_base - sold_base;
    let unused_quote = U256::from((0,0,0,this_balance(quote_token))) - pool_quote;
    let unused_base = U256::from((0,0,0,this_balance(base_token))) - pool_base;

    let tmp:U256 = (pool_quote * DECIMAL_ONE + unused_base - ONE) / unused_base;
    let avg_price = if (unused_base == U256::min()) {
        storage.I
    } else {
        // divceil
        tmp
    };

    let base_depth = avg_price * pool_base / DECIMAL_ONE;
    let mut pool_i = U256::min();
    if (pool_quote == U256::min()) {
        pool_i = storage.I;
    } else if (unused_base == pool_base) {
        pool_i = ONE;
    } else if (unused_base < pool_base) {
        let ratio = DECIMAL_ONE - (pool_quote * DECIMAL_ONE / base_depth);
        let tmp = avg_price * ratio * ratio;
        pool_i = (tmp * DECIMAL_ONE + DECIMAL_ONE2 - ONE) / DECIMAL_ONE2;
    } else if (unused_base > pool_base) {
        let ratio = DECIMAL_ONE - (base_depth * DECIMAL_ONE / pool_quote);
        pool_i = ratio * ratio / avg_price;
    }

    let ret = (pool_base, pool_quote, pool_i, unused_base, unused_quote);
    ret
}

fn u256_to_u64(num: U256) -> u64 {
    let res = num.as_u64();
    assert(!res.is_err());
    res.unwrap()
}

fn exp_to_u256(exp: u64) -> U256 {
    let mut res = U256::from((0,0,0,1));
    let mut cur = exp;
    while cur > 0 {
        res = res * U256::from((0,0,0,10));
        cur = cur - 1;
    }

    res
}

impl Ido for Contract {

    // Initialize an IDO contract and provides necessary parameters and options.
    #[storage(read, write)]
    fn initialize(adderss_list: Vec<b256>, timeline: Vec<u64>, value_list: Vec<u64>, exps: Vec<u64>, switches: Vec<bool>) {
        storage.initialized = true;

        // address_list [owner, maintainer, base token, quote token, fee model, pool factory address]
        require(adderss_list.len() == 6, IdoError::ListLengthError);
        storage.owner = adderss_list.get(0).unwrap();
        storage.maintainer = adderss_list.get(1).unwrap();
        storage.base_token = adderss_list.get(2).unwrap();
        storage.quote_token = adderss_list.get(3).unwrap();
        storage.fee_model = adderss_list.get(4).unwrap();
        storage.pool = adderss_list.get(5).unwrap();

        // timeline 
        require(timeline.len() == 7, IdoError::ListLengthError);
        storage.bid_start_time = U256::from((0,0,0,timeline.get(0).unwrap()));
        storage.bid_end_time = storage.bid_start_time + U256::from((0,0,0,timeline.get(1).unwrap()));
        storage.freeze_duration = U256::from((0,0,0,timeline.get(2).unwrap()));
        storage.vesting_duration = U256::from((0,0,0,timeline.get(3).unwrap()));
        storage.claim_freeze_duration = U256::from((0,0,0,timeline.get(4).unwrap()));
        storage.claim_vesting_duration = U256::from((0,0,0,timeline.get(5).unwrap()));
        storage.calm_end_time = U256::from((0,0,0,timeline.get(6).unwrap())) + storage.bid_end_time;

        storage.total_base = U256::from((0,0,0,this_balance(ContractId::from(storage.base_token))));
        // TODO: check timestamp?

        require(value_list.len() == 6, IdoError::ListLengthError);
        storage.pool_quote_cap = U256::from((0,0,0,value_list.get(0).unwrap())) * exp_to_u256(exps.get(0).unwrap());
        storage.K = U256::from((0,0,0,value_list.get(1).unwrap())) * exp_to_u256(exps.get(1).unwrap());
        storage.I = U256::from((0,0,0,value_list.get(2).unwrap())) * exp_to_u256(exps.get(2).unwrap());
        storage.lp_cliff_rate = U256::from((0,0,0,value_list.get(3).unwrap())) * exp_to_u256(exps.get(3).unwrap());
        storage.token_cliff_rate = U256::from((0,0,0,value_list.get(4).unwrap())) * exp_to_u256(exps.get(4).unwrap());
        storage.lp_fee_rate = U256::from((0,0,0,value_list.get(5).unwrap())) * exp_to_u256(exps.get(5).unwrap());

        storage.exps = (exps.get(0).unwrap(), 
                        exps.get(1).unwrap(), 
                        exps.get(2).unwrap(), 
                        exps.get(3).unwrap(), 
                        exps.get(4).unwrap(), 
                        exps.get(5).unwrap(), 
                        );

        // TODO: u64 is smaller than the given range of 1e36?
        require(storage.I > U256::min() && (storage.I < I_MAX || storage.I == I_MAX), IdoError::IValueError);
        require(storage.K < K_MAX || storage.K == K_MAX, IdoError::KValueError);
        require(storage.lp_cliff_rate < K_MAX || storage.lp_cliff_rate == K_MAX, IdoError::CliffRateError);
        require(storage.token_cliff_rate < K_MAX || storage.token_cliff_rate == K_MAX, IdoError::TokenCliffRateError);

        // switches
        require(switches.len() == 2, IdoError::ListLengthError);
        storage.is_overcap_stop = switches.get(0).unwrap();
        storage.is_open_twap = switches.get(1).unwrap();

        // TODO: check balance?
    }


    // Get detailed user status in current IDO?
    // TODO: different from solidity interface?
    #[storage(read)]
    fn get_info() -> Info {
        assert(storage.initialized);

        let adderss_list_: (b256, b256, b256, b256, b256, b256) = (
            storage.owner,
            storage.maintainer,
            storage.base_token,
            storage.quote_token,
            storage.fee_model,
            storage.pool,
        );

        let timeline_: (u64, u64, u64, u64, u64, u64, u64) = (
            u256_to_u64(storage.bid_start_time),
            u256_to_u64(storage.bid_end_time),
            u256_to_u64(storage.freeze_duration),
            u256_to_u64(storage.vesting_duration),
            u256_to_u64(storage.claim_freeze_duration),
            u256_to_u64(storage.claim_vesting_duration),
            u256_to_u64(storage.calm_end_time),
        );

        let value_list_: (u64, u64, u64, u64, u64, u64) = (
            u256_to_u64(storage.pool_quote_cap / exp_to_u256(storage.exps.0)),
            u256_to_u64(storage.K / exp_to_u256(storage.exps.1)),
            u256_to_u64(storage.I / exp_to_u256(storage.exps.2)),
            u256_to_u64(storage.lp_cliff_rate / exp_to_u256(storage.exps.3)),
            u256_to_u64(storage.token_cliff_rate / exp_to_u256(storage.exps.4)),
            u256_to_u64(storage.lp_fee_rate / exp_to_u256(storage.exps.5)),
        );

        let switches_: (bool, bool) = (
            storage.is_overcap_stop,
            storage.is_open_twap,
        );

        let info = Info {
            address_list: adderss_list_,
            timeline: timeline_,
            value_list: value_list_,
            switches: switches_,
        };

        info
    }

    // Return the amount of base and quote token claimable at address provided.
    #[storage(read)]
    fn get_claimable_token(user_address: b256) -> (u64, u64) {
        let claimable_tokens: (U256, U256) = get_claimable_token_(user_address);
        let res = (u256_to_u64(claimable_tokens.0), u256_to_u64(claimable_tokens.1));
        res
    }

    // Claim base token and quote token after IDO settlement.
    #[storage(read, write)]
    fn claim_bid(to: b256){
        // TODO: add claim quote token?
        let timestamp_:u64 = timestamp();
        let curr_timestamp:U256 = U256::from((0,0,0,timestamp_));
        if (storage.settled && curr_timestamp > storage.settled_time + storage.token_claim_duration || 
            storage.settled && curr_timestamp == storage.settled_time + storage.token_claim_duration) {
            // // claim_base_token
            let claimable_base_amount = get_claimable_token_(to).0;
            let origin_claimed_base_token = storage.claimed_base_token.get(to).unwrap_or(U256::min());

            storage.claimed_base_token.insert(to, origin_claimed_base_token + claimable_base_amount);

            let to_addr = Identity::Address(Address::from(to));
            transfer_base_out(to_addr, claimable_base_amount);
        }
    }

    // Claim LP token
    #[storage(read, write)]
    fn claim_lp_token() {
        // let sender = msg_sender().unwrap();
        // let addr:Address = match sender {
        //     Identity::Address(identity) => identity,
        //     _ => revert(0),
        // };
        // require(addr.into() == storage.owner, IdoError::NotOwner);

        let claimable_lp_token:U256 = get_lp_token_claimable_();

        let owner_id = Identity::Address(Address::from(storage.owner));
        let pool_contract_id = ContractId::from(storage.pool);

        let claimable_lp_token_transfer = claimable_lp_token.as_u64();
        assert(!claimable_lp_token_transfer.is_err());
        transfer(claimable_lp_token_transfer.unwrap(), pool_contract_id, owner_id);
    }

    // Return the amount of LP token claimable.
    // TODO: confirm interface, user_address?
    #[storage(read)]
    fn get_lp_token_claimable() -> u64 {
        let claimable_lp_token = u256_to_u64(get_lp_token_claimable_());

        claimable_lp_token
    }

    // Place bid on the current IDO.
    #[storage(read, write)]
    fn bid(to: b256) {

        assert(!storage.force_stop);
        let curr_timestamp = U256::from((0,0,0,timestamp()));
        require((curr_timestamp > storage.bid_start_time || curr_timestamp == storage.bid_start_time) && curr_timestamp < storage.bid_end_time, IdoError::NotPhaseBid);

        let quote_token = ContractId::from(storage.quote_token);
        let quote_input = U256::from((0,0,0,this_balance(quote_token))) - storage.quote_reserve;

        // TODO: Use contract Abi
        // let fee_rate_model = abi(FeeModel, storage.fee_model);
        // let fee_rate = U256::from((0,0,0,fee_rate_model.get_fee_rate(to)));
        let fee_rate = U256::from((0,0,0, get_fee_rate(to)));
        let mt_fee = quote_input * fee_rate / DECIMAL_ONE;

        let to_addr:Identity = Identity::Address(Address::from(storage.maintainer));

        transfer_quote_out(to_addr, mt_fee);
        mint_shares(to, quote_input - mt_fee);
        sync();
    }

    // Remove bid from the current IDO.
    #[storage(read, write)]
    fn cancel(to: b256, amount_: u64) {
        let amount = U256::from((0,0,0,amount_));
        let sender = msg_sender().unwrap();
        let addr:Address = match sender {
            Identity::Address(identity) => identity,
            _ => revert(0),
        };
        require(storage.shares.get(addr.into()).unwrap() > amount || storage.shares.get(addr.into()).unwrap() == amount, IdoError::SharesNotEnough);
        let curr_timestamp = U256::from((0,0,0,timestamp()));
        require((curr_timestamp > storage.bid_start_time || curr_timestamp == storage.bid_start_time) && curr_timestamp < storage.calm_end_time, IdoError::NotPhaseBidOrCalm);

        storage.shares.insert(addr.into(), storage.shares.get(addr.into()).unwrap() - amount);
        storage.total_shares -= amount;
        log(u256_to_u64(storage.total_shares));

        let to_addr:Identity = Identity::Address(Address::from(to));

        transfer_quote_out(to_addr, amount);
        sync();
    }

    // Settle IDO and allocate shares.
    #[storage(read, write)]
    fn settle() -> bool {
        assert(!storage.force_stop);
        let curr_timestamp = U256::from((0,0,0,timestamp()));
        require(curr_timestamp > storage.calm_end_time || curr_timestamp == storage.calm_end_time, IdoError::NotPhaseExe);

        settle_(curr_timestamp);

        let (pool_base, pool_quote, pool_i, unused_base, unused_quote) = get_settle_result_();
        storage.unused_base = unused_base;
        storage.unused_quote = unused_quote;

        let mut pool_base_token: b256 = ZERO_B256;
        let mut pool_quote_token: b256 = ZERO_B256;

        if (storage.unused_base > pool_base) {
            pool_base_token = storage.quote_token;
            pool_quote_token = storage.base_token;
        } else {
            pool_base_token = storage.base_token;
            pool_quote_token = storage.quote_token;
        }

        let pool:Identity = Identity::ContractId(ContractId::from(storage.pool));
        let tmp:U256 = (pool_quote * DECIMAL_ONE + unused_base - ONE) / unused_base;
        let avg_price = if unused_base == U256::min() {
            storage.I
        } else {
            tmp
        };

        storage.avg_settled_price = avg_price;
        let base_token_addr = ContractId::from(storage.base_token);
        let quote_token_addr = ContractId::from(storage.quote_token);
        let pool_instance = abi(VendingMachine, storage.pool);
        pool_instance.initialize(storage.maintainer, storage.base_token, storage.quote_token, storage.lp_fee_rate, ZERO_B256, storage.is_open_twap);
        transfer_base_out(pool, pool_base);
        transfer_quote_out(pool, pool_quote);
        let (total_lp_amount_, d, e) = pool_instance.buy_shares(contract_id());
        storage.total_lp_amount = total_lp_amount_;

        // TODO: transfer settled fund
        // let sender = msg_sender().unwrap();
        // transfer(storage.settled_fund, base_token_addr, sender);
        let tmp_ret = true;
        tmp_ret
    }

    // Get IDO settlement result.
    #[storage(read)]
    fn get_settle_result() -> (u64, u64, u64, u64, u64) {
        let res= get_settle_result_();
        let settle_result = (u256_to_u64(res.0), u256_to_u64(res.1), u256_to_u64(res.2), u256_to_u64(res.3), u256_to_u64(res.4));
        settle_result
    }

    // Get expected average price for the current unsettled IDO.
    #[storage(read)]
    fn get_expected_price(price: u64)->u64 {
        require(!storage.settled, IdoError::AlreadySettled);
        let (pool_base, pool_quote, _, _, _) = get_settle_result_();
        let base_token = ContractId::from(storage.base_token);
        let base_token_balance = U256::from((0,0,0,this_balance(base_token)));

        // TODO: replace tmp
        let tmp = base_token_balance + pool_base;
        let expected_avg_price = (pool_quote * DECIMAL_ONE + tmp - ONE) / (tmp);

        let res = u256_to_u64(expected_avg_price);
        res
    }

    // Get user shares for the current IDO.
    #[storage(read)]
    fn get_shares(usr: b256) -> u64 {
        let share = storage.shares.get(usr).unwrap_or(U256::min());
        u256_to_u64(share)
    }

    #[storage(read)]
    fn get_total_shares() -> u64 {
        u256_to_u64(storage.total_shares)
    }

    #[storage(read)]
    fn balance_of(asset: ContractId) -> u64 {
        let balance = this_balance(asset);
        balance
    }

    #[storage(read)]
    fn get_time() -> u64 {
        let time = timestamp();
        time
    }

    #[storage(read)]
    fn get_avg_settled_price()->u64 {
        u256_to_u64(storage.avg_settled_price / DECIMAL_ONE)
    }

    #[storage(read)]
    fn get_unused_quote()->u64 {
        u256_to_u64(storage.unused_quote)
    }

    #[storage(read)]
    fn get_unused_base()->u64 {
        u256_to_u64(storage.unused_base)
    }
}