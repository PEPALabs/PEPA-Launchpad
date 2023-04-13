library ido_abi;

use std::{
    address::*,
    assert::assert,
    block::*,
    context::*,
    contract_id::ContractId,
    // contract_id::AssetId,
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

pub struct Info {
    address_list: (b256, b256, b256, b256, b256, b256),
    timeline: (u64, u64, u64, u64, u64, u64, u64),
    value_list: (u64, u64, u64, u64, u64, u64),
    switches: (bool, bool),
}

abi Ido {

    // Initialize an IDO contract and provides necessary parameters and options.
    #[storage(read, write)]
    fn initialize(adderss_list: Vec<b256>, timeline: Vec<u64>, value_list: Vec<u64>, exps: Vec<u64>, switches: Vec<bool>);


    // Get detailed user status in current IDO?
    #[storage(read)]
    fn get_info() -> Info;

    // Claim base token and quote token after IDO settlement.
    #[storage(read, write)]
    fn claim_bid(to: b256);

    // Return the amount of base and quote token claimable at address provided.
    #[storage(read)]
    fn get_claimable_token(user_address: b256) -> (u64, u64);

    // Claim LP token?
    #[storage(read, write)]
    fn claim_lp_token();

    // Return the amount of LP token claimable.
    #[storage(read)]
    fn get_lp_token_claimable() -> u64;

    // Place bid on the current IDO.
    #[storage(read, write)]
    fn bid(to: b256);

    // Remove bid from the current IDO.
    #[storage(read, write)]
    fn cancel(to: b256, amount: u64);

    // Settle IDO and allocate shares.
    #[storage(read, write)]
    fn settle() -> bool;

    // Get IDO settlement result.
    #[storage(read)]
    fn get_settle_result() -> (u64, u64, u64, u64, u64);

    // Get expected average price for the current unsettled IDO.
    #[storage(read)]
    fn get_expected_price(price: u64)->u64;

    // Get user shares for the current IDO.
    #[storage(read)]
    fn get_shares(usr: b256) -> u64;

    #[storage(read)]
    fn get_total_shares() -> u64;

    #[storage(read)]
    fn balance_of(asset: ContractId) -> u64;

    #[storage(read)]
    fn get_time() -> u64;

    #[storage(read)]
    fn get_avg_settled_price()->u64;

    #[storage(read)]
    fn get_unused_quote()->u64;

    #[storage(read)]
    fn get_unused_base()->u64;
}
