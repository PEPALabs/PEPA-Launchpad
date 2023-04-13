library fee_model_abi;

use std::{
    address::*,
    assert::assert,
    block::*,
    contract_id::ContractId,
    constants::*,
    external::bytecode_root,
    hash::*,
    result::*,
    revert::revert,
    storage::*,
    token::*,
    u128::U128,
    //comment out forc 0.33.1 import
    //auth::*,
    //call_frames::{contract_id, msg_asset_id},,
};

// abi FeeModel {
//     fn get_fee_rate(to: b256) -> u64;
// }

// impl FeeModel for Contract {
//     fn get_fee_rate(to: b256)->u64 {
//         0
//     }
// }

pub fn get_fee_rate(to: b256)->u64 {
    0
}