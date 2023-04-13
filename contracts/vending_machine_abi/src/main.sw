library vending_machine_abi;

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

abi VendingMachine {

    #[storage(read, write)]
    fn initialize(maintainer_: b256, base_token_: b256, quote_token_: b256, lp_fee_rate_: U256, fee_rate_model_: b256, is_open_twap: bool);

    #[storage(read, write)]
    fn buy_shares(to: ContractId) -> (U256, U256, U256);

    #[storage(read)]
    fn balance_of(asset: ContractId) -> u64;

    #[storage(read)]
    fn foo() -> (ContractId, ContractId);
}
