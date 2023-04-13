contract;

use std::{
    address::*,
    assert::assert,
    block::*,
    context::*,
    contract_id::ContractId,
    constants::*,
    external::bytecode_root,
    hash::*,
    result::*,
    revert::revert,
    storage::*,
    token::*,
    u256::U256,
    //comment out forc 0.33.1 import
    //auth::*,
    //call_frames::{contract_id, msg_asset_id},,
};

use vending_machine_abi::*;

const DECIMAL_ONE = U256::from((0,0,0,1000000000000000000));

pub enum VendingMachineError {
  SameBaseQuoteAddr: (),
  AddressErroraaa: (),
}

storage {
    initialized: bool = false,

    is_open_twap: bool = false,

    maintainer: b256 = ZERO_B256,

    base_token: b256 = ZERO_B256,
    quote_token: b256 = ZERO_B256,

    base_reserve: U256 = U256::min(),
    quote_reserve: U256 = U256::min(),

    timestamp_last: U256 = U256::min(),
    base_price_cumulative_last: U256 = U256::min(),

    decimals: u8 = 0,
    total_supply: U256 = U256::min(),
    shares: StorageMap<b256, U256> = StorageMap {},
    allowed: StorageMap<(b256, b256), U256> = StorageMap {},

    nounce: StorageMap<b256, U256> = StorageMap {},
    lp_fee_rate: U256 = U256::min(),
    fee_rate_model: b256 = ZERO_B256,
    K: U256 = U256::min(),
    I: U256 = U256::min(),
}

#[storage(read, write)]
fn mint_(user: b256, value: U256) {
    assert(value > U256::from((0,0,0,1000)));
    let share = storage.shares.get(user).unwrap_or(U256::min());
    storage.shares.insert(user, share + value);
    storage.total_supply = storage.total_supply + value;
}

impl VendingMachine for Contract {
    #[storage(read, write)]
    fn initialize(maintainer_: b256, base_token_: b256, quote_token_: b256, lp_fee_rate_: U256, fee_rate_model_: b256, is_open_twap_: bool) {
        storage.initialized = true;

        require(base_token_ != quote_token_, VendingMachineError::SameBaseQuoteAddr);
        storage.base_token = base_token_;
        storage.quote_token = quote_token_;

        storage.lp_fee_rate = lp_fee_rate_;
        storage.fee_rate_model = fee_rate_model_;

        storage.maintainer = maintainer_;
        storage.is_open_twap = is_open_twap_;
        if (is_open_twap_) {
            storage.timestamp_last = U256::from((0,0,0,timestamp() % 0x100000000));
        }
    }

    #[storage(read, write)]
    fn buy_shares(to: ContractId) -> (U256, U256, U256) {
        let base_token_addr = ContractId::from(storage.base_token);
        let quote_token_addr = ContractId::from(storage.quote_token);

        let base_balance = U256::from((0,0,0,this_balance(base_token_addr)));
        let quote_balance = U256::from((0,0,0,this_balance(quote_token_addr)));

        let base_reserve = storage.base_reserve;
        let quote_reserve = storage.quote_reserve;
        
        let base_input = base_balance - base_reserve;
        let quote_input = quote_balance - quote_reserve;
        assert(base_input > U256::min());
        let mut share = U256::min();

        if (storage.total_supply == U256::min()) {
            assert(base_balance > U256::from((0,0,0,1000)) || base_balance == U256::from((0,0,0,1000)));
            share = base_balance;
        } else if (base_reserve > U256::min() && quote_reserve == U256::min()) {
            share = base_input * storage.total_supply / base_reserve;
        } else if (base_reserve > U256::min() && quote_reserve > U256::min()) {
            let base_input_ratio = base_input * DECIMAL_ONE / base_reserve;
            let quote_input_ratio = quote_input * DECIMAL_ONE / quote_reserve;
            let mint_ratio = if quote_input_ratio < base_input_ratio {
                quote_input_ratio
            } else {
                base_input_ratio
            };

            share = storage.total_supply * mint_ratio / DECIMAL_ONE;
        }

        mint_(to.into(), share);
        storage.base_reserve = base_reserve;
        storage.quote_reserve = quote_reserve;
        (share, base_input, quote_input)
    }

    #[storage(read)]
    fn balance_of(asset: ContractId) -> u64 {
        let balance = this_balance(asset);
        balance
    }

    #[storage(read)]
    fn foo() -> (ContractId, ContractId){
        (ContractId::from(storage.base_token), ContractId::from(storage.quote_token))
    }
}
