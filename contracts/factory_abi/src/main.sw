library factory_abi;

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
    u128::U128,
    //comment out forc 0.33.1 import
    //auth::*,
    //call_frames::{contract_id, msg_asset_id},,
};

abi Factory {

    // Initialize a factory contract.
    #[storage(read, write)]
    fn initialize(template_ido_id: b256);

    // Register an IDO project and pass in necessary parameters. 
    #[storage(read, write)]
    fn add_ido(base_token: b256, quote_token: b256, id_address: b256, owner: b256);

    // Search an IDO contract address by base and quote token.
    #[storage(read)]
    fn get_ido_by_token(base_token: b256, quote_token: b256) -> Option<b256>;

    // Search an IDO contract address by its admin.
    #[storage(read)]
    fn get_ido_by_admin(owner: b256) -> Option<b256>;

    // Update admin of an IDO project?
    #[storage(read, write)]
    fn update_admin(old_owner: b256, new_owner: b256) -> Option<b256>;

    // Remove an IDO project and its public pool (if exist).
    #[storage(read, write)]
    fn remove_ido(owner: b256, base_token: b256, quote_token: b256, pool: b256);
}
