library pricing_lib;

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
    math::*,
    //comment out forc 0.33.1 import
    //auth::*,
    //call_frames::{contract_id, msg_asset_id},,
};

pub fn sell_base_token(pay_base_amount: U256) -> U256 {
    pay_base_amount
}

pub fn sell_quote_token(pay_quote_amount: U256) -> U256 {
    pay_quote_amount
}