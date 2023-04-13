contract;

use std::{
    address::*,
    assert::assert,
    block::*,
    context::*,
    contract_id::*,
    constants::*,
    external::bytecode_root,
    hash::*,
    result::*,
    revert::revert,
    storage::*,
    token::*,
    u128::U128,
    bytes::*,
    logging::*,
    //comment out forc 0.33.1 import
    //auth::*,
    //call_frames::{contract_id, msg_asset_id},,
};

use factory_abi::*;

pub enum FactoryError {
  PlaceholderError: (),
}

storage {
    initialized: bool = false,
    template_root: b256 = ZERO_B256,

    // TODO: check value type, maybe vec?
    tokens_map: StorageMap<(b256, b256), b256> = StorageMap {},
    admin_map: StorageMap<b256, b256> = StorageMap {},
}

impl Factory for Contract {
    // Initialize a factory contract.
    #[storage(read, write)]
    fn initialize(template_ido_id: b256){
        let a:u64 = 5;
        
        storage.initialized = true;
        let contract_id: ContractId = ContractId::from(template_ido_id);
        log(contract_id);
        let root = bytecode_root(contract_id);

        log(root);
        storage.template_root = root;
    }

    // Register an IDO project and pass in necessary parameters. 
    #[storage(read, write)]
    fn add_ido(base_token: b256, quote_token: b256, id_address: b256, owner: b256) {
        assert(storage.initialized);
        // let root = bytecode_root(ContractId::from(id_address));
        // require(root == storage.template_root, FactoryError::PlaceholderError);

        // not exist already?
        let token_ido = storage.tokens_map.get((base_token, quote_token));
        let admin_ido = storage.admin_map.get(owner);

        assert(token_ido.is_none() || token_ido.unwrap() == b256::min());
        assert(admin_ido.is_none() || admin_ido.unwrap() == b256::min());

        storage.tokens_map.insert((base_token, quote_token), id_address);
        storage.admin_map.insert(owner, id_address);
    }

    // Search an IDO contract address by base and quote token.
    #[storage(read)]
    fn get_ido_by_token(base_token: b256, quote_token: b256) -> Option<b256> {
        assert(storage.initialized);

        let ido = storage.tokens_map.get((base_token, quote_token));
        if ido.is_none() || ido.unwrap() == b256::min() {
            Option::None
        } else {
            ido
        }
        ido
    }

    // Search an IDO contract address by its admin.
    #[storage(read)]
    fn get_ido_by_admin(owner: b256) -> Option<b256> {
        assert(storage.initialized);

        let ido = storage.admin_map.get(owner);
        if ido.is_none() || ido.unwrap() == b256::min() {
            Option::None
        } else {
            ido
        }
        ido
    }

    // Update admin of an IDO project
    #[storage(read, write)]
    fn update_admin(old_owner: b256, new_owner: b256) -> Option<b256>{
        assert(storage.initialized);
        let ido = storage.admin_map.get(old_owner);

        let ido_new = storage.admin_map.get(new_owner);
        assert(ido_new.is_none() || ido_new.unwrap() == b256::min());

        if !ido.is_none() && ido.unwrap() != b256::min() {
            storage.admin_map.insert(new_owner, ido.unwrap());
            storage.admin_map.insert(old_owner, b256::min());
            ido
        } else {
            Option::None
        }
    }

    // Remove an IDO project and its public pool (if exist).
    #[storage(read, write)]
    fn remove_ido(owner: b256, base_token: b256, quote_token: b256, pool: b256) {
        assert(storage.initialized);
        let ido_token = storage.tokens_map.get((base_token, quote_token));
        let ido_admin = storage.admin_map.get(owner);

        assert((ido_admin.is_none() && ido_token.is_none()) || (!ido_admin.is_none() && !ido_token.is_none() && ido_token.unwrap() == ido_admin.unwrap()));

        if !ido_admin.is_none() && !ido_token.is_none() && ido_admin.unwrap() != b256::min() {
            storage.tokens_map.insert((base_token, quote_token), b256::min());
            storage.admin_map.insert(owner, b256::min());
        }
    }
}

#[test(should_revert)]
fn test_should_initilize(){
    let caller = abi(Factory, CONTRACT_ID);
    let mut initial_bytes = Bytes::with_capacity(32);
    let admin = b256::try_from(initial_bytes).unwrap();
    caller.get_ido_by_admin(admin);
}

#[test]
fn test_add_get_ido(){
    let base_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000002A;
    let quote_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000003A;
    let admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000004A;
    let ido: b256 = 0x3e76b74cf0229c8244853f1afc2f81b0aaddc0c2df88a6b5450dd344f8c271b8;
    
    let caller = abi(Factory, CONTRACT_ID);
    caller.initilize(ido);
    caller.add_ido(base_token, quote_token, ido, admin);
    let ido_get1 = caller.get_ido_by_token(base_token, quote_token).unwrap();
    let ido_get2 = caller.get_ido_by_admin(admin).unwrap();

    
    assert(ido_get1 == ido);
    assert(ido_get2 == ido);
}

#[test]
fn test_update_admin_empty(){
    let old_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000004A;
    let new_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000005A;
    let ido_temp: b256 = 0x000000000000000000000000000000000000000000000000000000000000006A;
    
    let caller = abi(Factory, CONTRACT_ID);
    caller.initilize(ido_temp);
    let ido = caller.update_admin(old_admin, new_admin);

    assert(ido.is_none());
}

#[test]
fn test_update_admin(){
    let old_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000004A;
    let new_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000005A;
    let ido_temp: b256 = 0x000000000000000000000000000000000000000000000000000000000000006A;
    let base_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000002A;
    let quote_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000003A;
    let ido: b256 = 0x000000000000000000000000000000000000000000000000000000000000007A;
    
    let caller = abi(Factory, CONTRACT_ID);
    caller.initilize(ido_temp);
    caller.add_ido(base_token, quote_token, ido, old_admin);
    let ido_ret = caller.update_admin(old_admin, new_admin);
    let ido_get1 = caller.get_ido_by_admin(old_admin);
    let ido_get2 = caller.get_ido_by_admin(new_admin);

    assert(!ido_ret.is_none() && ido_ret.unwrap() == ido);
    assert(ido_get1.is_none() || ido_get1.unwrap() == b256::min());
    assert(!ido_get2.is_none() && ido_get2.unwrap() == ido);
}

#[test(should_revert)]
fn test_update_admin_owner_occupied(){
    let old_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000004A;
    let new_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000005A;
    let ido_temp: b256 = 0x000000000000000000000000000000000000000000000000000000000000006A;
    let base_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000002A;
    let quote_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000003A;
    let base_token2: b256 = 0x000000000000000000000000000000000000000000000000000000000000002B;
    let quote_token2: b256 = 0x000000000000000000000000000000000000000000000000000000000000003B;

    let ido: b256 = 0x000000000000000000000000000000000000000000000000000000000000007A;
    let ido2: b256 = 0x000000000000000000000000000000000000000000000000000000000000008A;
    
    let caller = abi(Factory, CONTRACT_ID);
    caller.initilize(ido_temp);
    caller.add_ido(base_token, quote_token, ido, old_admin);
    caller.add_ido(base_token2, quote_token2, ido2, new_admin);
    let ido_ret = caller.update_admin(old_admin, new_admin);
}

#[test]
fn test_remove_ido_not_exist(){
    let ido_temp: b256 = 0x000000000000000000000000000000000000000000000000000000000000006A;
    let caller = abi(Factory, CONTRACT_ID);
    let base_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000002A;
    let quote_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000003A;
    let admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000004A;
    let ido: b256 = 0x000000000000000000000000000000000000000000000000000000000000007A;

    caller.initilize(ido_temp);
    caller.remove_ido(admin, base_token, quote_token, ido);
    let ido_get1 = caller.get_ido_by_token(base_token, quote_token);
    let ido_get2 = caller.get_ido_by_admin(admin);
    assert(ido_get1.is_none() && ido_get2.is_none());
}

#[test(should_revert)]
fn test_remove_ido_not_match(){
    let old_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000004A;
    let new_admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000005A;
    let ido_temp: b256 = 0x000000000000000000000000000000000000000000000000000000000000006A;
    let base_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000002A;
    let quote_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000003A;
    let ido: b256 = 0x000000000000000000000000000000000000000000000000000000000000007A;
    
    let caller = abi(Factory, CONTRACT_ID);
    caller.initilize(ido_temp);
    caller.add_ido(base_token, quote_token, ido, old_admin);
    let ido_ret = caller.update_admin(old_admin, new_admin);

    caller.remove_ido(old_admin, base_token, quote_token, ido);
}

#[test]
fn test_remove_ido(){
    let ido_temp: b256 = 0x000000000000000000000000000000000000000000000000000000000000006A;
    let caller = abi(Factory, CONTRACT_ID);
    let base_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000002A;
    let quote_token: b256 = 0x000000000000000000000000000000000000000000000000000000000000003A;
    let admin: b256 = 0x000000000000000000000000000000000000000000000000000000000000004A;
    let ido: b256 = 0x000000000000000000000000000000000000000000000000000000000000007A;

    caller.initilize(ido_temp);
    caller.add_ido(base_token, quote_token, ido, admin);
    caller.remove_ido(admin, base_token, quote_token, ido);

    log(CONTRACT_ID);
    
    let ido_get1 = caller.get_ido_by_admin(admin);
    let ido_get2 = caller.get_ido_by_token(base_token, quote_token);

    assert(ido_get1.is_none() || ido_get1.unwrap() == b256::min());
    assert(ido_get2.is_none() || ido_get2.unwrap() == b256::min());
}