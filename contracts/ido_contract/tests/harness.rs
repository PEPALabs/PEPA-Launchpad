use fuels::{prelude::*, tx::ContractId, types::*, types::transaction::TxParameters};
use std::io;
use std::collections::HashMap;
use std::{thread, time};
use rand::Fill;
use chrono::{Utc, TimeZone, Duration};
use tai64::Tai64;


fn addr_to_b256(addr: &Bech32Address) -> Bits256 {
    let a = *addr.hash();
    Bits256(a)
}

#[tokio::test]
async fn test_bid() -> Result<()>{
    abigen!(Contract(name = "IdoContract", abi = "./out/debug/ido_contract-abi.json"));
    let mut rng = rand::thread_rng();

    let asset_base = AssetConfig {
        id: BASE_ASSET_ID,
        num_coins: 1,
        coin_amount: 1000000000000,
    };

    let mut quote_id = AssetId::zeroed();
    quote_id.try_fill(&mut rng);
    let asset_quote = AssetConfig {
        id: quote_id,
        num_coins: 1,
        coin_amount: 1000000,
    };


    let assets = vec![asset_base.clone(), asset_quote.clone()];

    let num_wallets = 10;
    let wallet_config = WalletsConfig::new_multiple_assets(num_wallets, assets);
    let wallets = launch_custom_provider_and_get_wallets(wallet_config, None, None).await;

    let bidder1 = wallets.get(0).unwrap();
    let bidder2 = wallets.get(1).unwrap();
    let deployer = wallets.get(2).unwrap();
    let maintainer = wallets.get(3).unwrap();

    let zero_b256 = "0x0000000000000000000000000000000000000000000000000000000000000000";

    let deployer_addr = addr_to_b256(deployer.address());
    let maintainer_addr = addr_to_b256(maintainer.address());
    let bidder1_addr = addr_to_b256(bidder1.address());
    let bidder2_addr = addr_to_b256(bidder2.address());
    let base_token_b256 = Bits256(*BASE_ASSET_ID);
    let quote_token_b256 = Bits256(*quote_id);
    let fee_model = Bits256::from_hex_str(zero_b256).unwrap();
    let pool = Bits256::from_hex_str(zero_b256).unwrap();

    let addr_list = vec![deployer_addr.clone(), maintainer_addr.clone(), base_token_b256, quote_token_b256, fee_model, pool];

    let start_time = u64::from_be_bytes(Tai64::now().to_bytes());
    println!("{}", start_time);
    let bid_duration:u64 = 15;
    let calm_duration:u64 = 15;
    let freeze_duration: u64 = 15;
    let vesting_duration: u64 = 15;

    let timeline = vec![start_time, bid_duration, freeze_duration, vesting_duration, 15, 15, calm_duration];

    let pool_quote_cap:u64 = 50000;
    let k:u64 = 1;
    let i: u64 = 1;
    let cliff_rate: u64 = 1;
    let is_open_twap = true;

    let value_list = vec![pool_quote_cap, k, i, cliff_rate, cliff_rate, 0];
    let exps = vec![18,18,18,18,18,18];
    let switch = vec![true, is_open_twap];

    let id = Contract::deploy(
        "./out/debug/ido_contract.bin",
        &deployer,
        DeployConfiguration::default(),
    )
    .await
    .unwrap();

    let instance = IdoContract::new(id.clone(), bidder1.clone());
    let base_token = ContractId::new(*BASE_ASSET_ID);
    let quote_token = ContractId::new(*quote_id);

    let my_tx_parameters = TxParameters::default()
            .set_gas_price(0)
            .set_gas_limit(1000000)
            .set_maturity(0);

    let result1 = instance
        .methods()
        .initialize(addr_list, timeline, value_list, exps, switch)
        .tx_params(TxParameters::default())
        .call()
        .await;

    assert!(!result1.is_err());

    let result2 = instance
                  .methods()
                  .get_info()
                  .tx_params(my_tx_parameters)
                  .call()
                  .await.unwrap();

    let result3 = instance
                  .methods()
                  .balance_of(ContractId::new(*quote_id))
                  .tx_params(my_tx_parameters)
                  .call()
                  .await
                  .unwrap();

    println!("{}", result3.value);

    let result4 = bidder1
            .force_transfer_to_contract(&id, 100, quote_id, my_tx_parameters)
            .await;

    let result5 = instance
    .methods()
    .bid(bidder1_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let result6 = instance
    .methods()
    .get_shares(bidder1_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(result6.value == 100);

    let result7 = instance
    .methods()
    .get_total_shares()
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(result7.value == 100);

    let maintainer_balance = maintainer.get_asset_balance(&quote_id).await.unwrap();
    assert!(maintainer_balance == 1000000);

    let result8 = bidder2
        .force_transfer_to_contract(&id, 50, quote_id, my_tx_parameters)
        .await;

    let result9 = instance
    .methods()
    .bid(bidder2_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let result10 = instance
    .methods()
    .get_shares(bidder2_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(result10.value == 50);

    let result11 = instance
    .methods()
    .get_total_shares()
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(result11.value == 150);

    let maintainer_balance = maintainer.get_asset_balance(&quote_id).await.unwrap();
    assert!(maintainer_balance == 1000000);

    let curr_time:u64 = u64::from_be_bytes(Tai64::now().to_bytes());
    if curr_time - start_time < bid_duration {
        thread::sleep(time::Duration::from_secs(bid_duration - (curr_time - start_time)));
    }

    println!("{}", u64::from_be_bytes(Tai64::now().to_bytes()));

    let result12 = instance
    .with_wallet(bidder1.clone())?
    .methods()
    .cancel(bidder1_addr, 20)
    .append_variable_outputs(1)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let result13 = instance
    .methods()
    .get_total_shares()
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(result13.value == 130);

    let result14 = instance
    .methods()
    .get_shares(bidder1_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(result14.value == 80);

    let bidder1_balance = bidder1.get_asset_balance(&quote_id).await.unwrap();
    assert!(bidder1_balance == 1000000-80);

    Ok(())
}

#[tokio::test]
async fn test_settle() -> Result<()> {
    abigen!(Contract(name = "IdoContract", abi = "./out/debug/ido_contract-abi.json"));
    // abigen!(Contract(name = "VendingMachine", abi = "../vending_machine_contract/out/debug/vending_machine_contract-abi.json"));
    let mut rng = rand::thread_rng();

    let asset_base = AssetConfig {
        id: BASE_ASSET_ID,
        num_coins: 1,
        coin_amount: 1000000000000,
    };

    let mut quote_id = AssetId::zeroed();
    quote_id.try_fill(&mut rng);
    let asset_quote = AssetConfig {
        id: quote_id,
        num_coins: 1,
        coin_amount: 1000000,
    };


    let assets = vec![asset_base.clone(), asset_quote.clone()];

    let num_wallets = 10;
    let wallet_config = WalletsConfig::new_multiple_assets(num_wallets, assets);
    let wallets = launch_custom_provider_and_get_wallets(wallet_config, None, None).await;

    let bidder1 = wallets.get(0).unwrap();
    let bidder2 = wallets.get(1).unwrap();
    let deployer = wallets.get(2).unwrap();
    let maintainer = wallets.get(3).unwrap();
    let vending_machine_deployer = wallets.get(4).unwrap();

    let zero_b256 = "0x0000000000000000000000000000000000000000000000000000000000000000";

    let vending_machine_id = Contract::deploy(
        "../vending_machine_contract/out/debug/vending_machine_contract.bin",
        &vending_machine_deployer,
        DeployConfiguration::default(),
    )
    .await
    .unwrap();

    let deployer_addr = addr_to_b256(deployer.address());
    let maintainer_addr = addr_to_b256(maintainer.address());
    let bidder1_addr = addr_to_b256(bidder1.address());
    let bidder2_addr = addr_to_b256(bidder2.address());
    let base_token_b256 = Bits256(*BASE_ASSET_ID);
    let quote_token_b256 = Bits256(*quote_id);
    let fee_model = Bits256::from_hex_str(zero_b256).unwrap();
    let pool = Bits256(*vending_machine_id.hash());

    let addr_list = vec![deployer_addr.clone(), maintainer_addr.clone(), base_token_b256, quote_token_b256, fee_model, pool];

    let start_time = u64::from_be_bytes(Tai64::now().to_bytes());
    println!("{}", start_time);
    let bid_duration:u64 = 15;
    let calm_duration:u64 = 15;
    let freeze_duration: u64 = 15;
    let vesting_duration: u64 = 15;

    let timeline = vec![start_time, bid_duration, freeze_duration, vesting_duration, 15, 15, calm_duration];

    let pool_quote_cap:u64 = 50000;
    let k:u64 = 1;
    let i: u64 = 1;
    let cliff_rate: u64 = 1;
    let is_open_twap = true;
    let lp_fee_rate = 2;

    let value_list = vec![pool_quote_cap, k, i, cliff_rate, cliff_rate, lp_fee_rate];
    let exps = vec![18,18,18,18,18,17];
    let switch = vec![true, is_open_twap];

    let id = Contract::deploy(
        "./out/debug/ido_contract.bin",
        &deployer,
        DeployConfiguration::default(),
    )
    .await
    .unwrap();

    let instance = IdoContract::new(id.clone(), bidder1.clone());
    let base_token = ContractId::new(*BASE_ASSET_ID);
    let quote_token = ContractId::new(*quote_id);

    let my_tx_parameters = TxParameters::default()
            .set_gas_price(0)
            .set_gas_limit(1000000)
            .set_maturity(0);

    let total_base = 10000;
    let result0 = deployer
        .force_transfer_to_contract(&id, total_base, BASE_ASSET_ID, my_tx_parameters)
        .await;

    assert!(!result0.is_err());

    let result1 = instance
        .methods()
        .initialize(addr_list, timeline, value_list, exps, switch)
        .tx_params(TxParameters::default())
        .call()
        .await;

    assert!(!result1.is_err());

    let result2 = instance
                  .methods()
                  .get_info()
                  .tx_params(my_tx_parameters)
                  .call()
                  .await.unwrap();

    let transfer_quote = bidder1
        .force_transfer_to_contract(&id, 1000, quote_id, my_tx_parameters)
        .await;
      
    let result4 = instance
    .methods()
    .bid(bidder1_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let curr_time:u64 = u64::from_be_bytes(Tai64::now().to_bytes());
    if curr_time - start_time < bid_duration * 2 {
        thread::sleep(time::Duration::from_secs(bid_duration * 2 - (curr_time - start_time)));
    }

    println!("{}", u64::from_be_bytes(Tai64::now().to_bytes()));

    let result5 = instance
    .methods()
    .bid(bidder1_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await;

    assert!(result5.is_err());

    let result6 = instance
    .methods()
    .settle()
    .set_contract_ids(&[vending_machine_id.clone()])
    .append_variable_outputs(2)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(result6.value);

    let avg_settled_price = instance
    .methods()
    .get_avg_settled_price()
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(avg_settled_price.value == 1);

    let unused_quote = instance
    .methods()
    .get_unused_quote()
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let unused_base = instance
    .methods()
    .get_unused_base()
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(unused_quote.value == 0);
    assert!(unused_base.value == 1000);

    let quote_balance = instance
    .methods()
    .balance_of(ContractId::new(*quote_id))
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let base_balance = instance
    .methods()
    .balance_of(ContractId::new(*BASE_ASSET_ID))
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(quote_balance.value == 0);
    assert!(base_balance.value == 1000);

    Ok(())
}

#[tokio::test]
async fn test_claim_bid() -> Result<()> {
    abigen!(Contract(name = "IdoContract", abi = "./out/debug/ido_contract-abi.json"));
    // abigen!(Contract(name = "VendingMachine", abi = "../vending_machine_contract/out/debug/vending_machine_contract-abi.json"));
    let mut rng = rand::thread_rng();

    let asset_base = AssetConfig {
        id: BASE_ASSET_ID,
        num_coins: 1,
        coin_amount: 1000000000000,
    };

    let mut quote_id = AssetId::zeroed();
    quote_id.try_fill(&mut rng);
    let asset_quote = AssetConfig {
        id: quote_id,
        num_coins: 1,
        coin_amount: 1000000,
    };


    let assets = vec![asset_base.clone(), asset_quote.clone()];

    let num_wallets = 10;
    let wallet_config = WalletsConfig::new_multiple_assets(num_wallets, assets);
    let wallets = launch_custom_provider_and_get_wallets(wallet_config, None, None).await;

    let bidder1 = wallets.get(0).unwrap();
    let bidder2 = wallets.get(1).unwrap();
    let deployer = wallets.get(2).unwrap();
    let maintainer = wallets.get(3).unwrap();
    let vending_machine_deployer = wallets.get(4).unwrap();

    let zero_b256 = "0x0000000000000000000000000000000000000000000000000000000000000000";

    let vending_machine_id = Contract::deploy(
        "../vending_machine_contract/out/debug/vending_machine_contract.bin",
        &vending_machine_deployer,
        DeployConfiguration::default(),
    )
    .await
    .unwrap();

    let deployer_addr = addr_to_b256(deployer.address());
    let maintainer_addr = addr_to_b256(maintainer.address());
    let bidder1_addr = addr_to_b256(bidder1.address());
    let bidder2_addr = addr_to_b256(bidder2.address());
    let base_token_b256 = Bits256(*BASE_ASSET_ID);
    let quote_token_b256 = Bits256(*quote_id);
    let fee_model = Bits256::from_hex_str(zero_b256).unwrap();
    let pool = Bits256(*vending_machine_id.hash());

    let addr_list = vec![deployer_addr.clone(), maintainer_addr.clone(), base_token_b256, quote_token_b256, fee_model, pool];

    let start_time = u64::from_be_bytes(Tai64::now().to_bytes());
    println!("{}", start_time);
    let bid_duration:u64 = 15;
    let calm_duration:u64 = 15;
    let freeze_duration: u64 = 15;
    let vesting_duration: u64 = 15;

    let timeline = vec![start_time, bid_duration, freeze_duration, vesting_duration, 15, 15, calm_duration];

    let pool_quote_cap:u64 = 50000;
    let k:u64 = 1;
    let i: u64 = 1;
    let cliff_rate: u64 = 1;
    let is_open_twap = true;
    let lp_fee_rate = 2;

    let value_list = vec![pool_quote_cap, k, i, cliff_rate, cliff_rate, lp_fee_rate];
    let exps = vec![18,18,18,18,18,17];
    let switch = vec![true, is_open_twap];

    let id = Contract::deploy(
        "./out/debug/ido_contract.bin",
        &deployer,
        DeployConfiguration::default(),
    )
    .await
    .unwrap();

    let instance = IdoContract::new(id.clone(), bidder1.clone());
    let base_token = ContractId::new(*BASE_ASSET_ID);
    let quote_token = ContractId::new(*quote_id);

    let my_tx_parameters = TxParameters::default()
            .set_gas_price(0)
            .set_gas_limit(1000000)
            .set_maturity(0);

    let total_base = 100000;
    let transfer_base = deployer
        .force_transfer_to_contract(&id, total_base, BASE_ASSET_ID, my_tx_parameters)
        .await;

    assert!(!transfer_base.is_err());

    let result1 = instance
        .methods()
        .initialize(addr_list, timeline, value_list, exps, switch)
        .tx_params(TxParameters::default())
        .call()
        .await;

    assert!(!result1.is_err());

    let result2 = instance
                  .methods()
                  .get_info()
                  .tx_params(my_tx_parameters)
                  .call()
                  .await.unwrap();

    let transfer_quote1 = deployer
        .force_transfer_to_contract(&id, 10000, quote_id, my_tx_parameters)
        .await;

    assert!(!transfer_quote1.is_err());
      
    let bid1 = instance
    .methods()
    .bid(bidder1_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let transfer_quote2 = deployer
        .force_transfer_to_contract(&id, 20000, quote_id, my_tx_parameters)
        .await;

    assert!(!transfer_quote2.is_err());
      
    let bid2 = instance
    .methods()
    .bid(bidder2_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let curr_time:u64 = u64::from_be_bytes(Tai64::now().to_bytes());
    if curr_time - start_time < bid_duration * 2 {
        thread::sleep(time::Duration::from_secs(bid_duration * 2 - (curr_time - start_time)));
    }

    println!("{}", u64::from_be_bytes(Tai64::now().to_bytes()));

    let settle = instance
    .methods()
    .settle()
    .set_contract_ids(&[vending_machine_id.clone()])
    .append_variable_outputs(2)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(settle.value);

    let base_balance = instance
    .methods()
    .balance_of(ContractId::new(*BASE_ASSET_ID))
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(base_balance.value == 30000);

    let quote_balance = instance
    .methods()
    .balance_of(ContractId::new(*quote_id))
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(quote_balance.value == 0);

    let claim1 = instance
    .methods()
    .claim_bid(bidder1_addr)
    .append_variable_outputs(1)
    .tx_params(my_tx_parameters)
    .call()
    .await;

    assert!(!claim1.is_err());

    let balance1 = bidder1
                   .get_asset_balance(&BASE_ASSET_ID)
                   .await
                   .unwrap();
    assert!(balance1 == 1000000010000);

    let claim2 = instance
    .methods()
    .claim_bid(bidder2_addr)
    .append_variable_outputs(1)
    .tx_params(my_tx_parameters)
    .call()
    .await;

    assert!(!claim2.is_err());

    let balance2 = bidder2
                   .get_asset_balance(&BASE_ASSET_ID)
                   .await
                   .unwrap();
    assert!(balance2 == 1000000020000);

    Ok(())
}

#[tokio::test]
async fn test_claim_lp() -> Result<()> {
    abigen!(Contract(name = "IdoContract", abi = "./out/debug/ido_contract-abi.json"));
    // abigen!(Contract(name = "VendingMachine", abi = "../vending_machine_contract/out/debug/vending_machine_contract-abi.json"));
    let mut rng = rand::thread_rng();

    let asset_base = AssetConfig {
        id: BASE_ASSET_ID,
        num_coins: 1,
        coin_amount: 1000000000000,
    };

    let mut quote_id = AssetId::zeroed();
    quote_id.try_fill(&mut rng);
    let asset_quote = AssetConfig {
        id: quote_id,
        num_coins: 1,
        coin_amount: 1000000,
    };


    let assets = vec![asset_base.clone(), asset_quote.clone()];

    let num_wallets = 10;
    let wallet_config = WalletsConfig::new_multiple_assets(num_wallets, assets);
    let wallets = launch_custom_provider_and_get_wallets(wallet_config, None, None).await;

    let bidder1 = wallets.get(0).unwrap();
    let bidder2 = wallets.get(1).unwrap();
    let deployer = wallets.get(2).unwrap();
    let maintainer = wallets.get(3).unwrap();
    let vending_machine_deployer = wallets.get(4).unwrap();

    let zero_b256 = "0x0000000000000000000000000000000000000000000000000000000000000000";

    let vending_machine_id = Contract::deploy(
        "../vending_machine_contract/out/debug/vending_machine_contract.bin",
        &vending_machine_deployer,
        DeployConfiguration::default(),
    )
    .await
    .unwrap();

    let deployer_addr = addr_to_b256(deployer.address());
    let maintainer_addr = addr_to_b256(maintainer.address());
    let bidder1_addr = addr_to_b256(bidder1.address());
    let bidder2_addr = addr_to_b256(bidder2.address());
    let base_token_b256 = Bits256(*BASE_ASSET_ID);
    let quote_token_b256 = Bits256(*quote_id);
    let fee_model = Bits256::from_hex_str(zero_b256).unwrap();
    let pool = Bits256(*vending_machine_id.hash());

    let addr_list = vec![deployer_addr.clone(), maintainer_addr.clone(), base_token_b256, quote_token_b256, fee_model, pool];

    let start_time = u64::from_be_bytes(Tai64::now().to_bytes());
    println!("{}", start_time);
    let bid_duration:u64 = 15;
    let calm_duration:u64 = 15;
    let freeze_duration: u64 = 15;
    let vesting_duration: u64 = 15;

    let timeline = vec![start_time, bid_duration, freeze_duration, vesting_duration, 15, 15, calm_duration];

    let pool_quote_cap:u64 = 50000;
    let k:u64 = 1;
    let i: u64 = 1;
    let cliff_rate: u64 = 1;
    let is_open_twap = true;
    let lp_fee_rate = 2;

    let value_list = vec![pool_quote_cap, k, i, cliff_rate, cliff_rate, lp_fee_rate];
    let exps = vec![18,18,18,18,18,17];
    let switch = vec![true, is_open_twap];

    let id = Contract::deploy(
        "./out/debug/ido_contract.bin",
        &deployer,
        DeployConfiguration::default(),
    )
    .await
    .unwrap();

    let instance = IdoContract::new(id.clone(), bidder1.clone());
    let base_token = ContractId::new(*BASE_ASSET_ID);
    let quote_token = ContractId::new(*quote_id);

    let my_tx_parameters = TxParameters::default()
            .set_gas_price(0)
            .set_gas_limit(1000000)
            .set_maturity(0);

    let total_base = 100000;
    let transfer_base = deployer
        .force_transfer_to_contract(&id, total_base, BASE_ASSET_ID, my_tx_parameters)
        .await;

    assert!(!transfer_base.is_err());

    let result1 = instance
        .methods()
        .initialize(addr_list, timeline, value_list, exps, switch)
        .tx_params(TxParameters::default())
        .call()
        .await;

    assert!(!result1.is_err());

    let result2 = instance
                  .methods()
                  .get_info()
                  .tx_params(my_tx_parameters)
                  .call()
                  .await.unwrap();

    // let x = instance
    // .methods()
    // .claim_lp_token(100)
    // .set_contract_ids(&[vending_machine_id.clone()])
    // .append_variable_outputs(1)
    // .tx_params(my_tx_parameters)
    // .call()
    // .await
    // .unwrap();

    let transfer_quote1 = deployer
        .force_transfer_to_contract(&id, 10000, quote_id, my_tx_parameters)
        .await;

    assert!(!transfer_quote1.is_err());
      
    let bid1 = instance
    .methods()
    .bid(bidder1_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let transfer_quote2 = deployer
        .force_transfer_to_contract(&id, 20000, quote_id, my_tx_parameters)
        .await;

    assert!(!transfer_quote2.is_err());
      
    let bid2 = instance
    .methods()
    .bid(bidder2_addr)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let curr_time:u64 = u64::from_be_bytes(Tai64::now().to_bytes());
    if curr_time - start_time < bid_duration * 2 {
        thread::sleep(time::Duration::from_secs(bid_duration * 2 - (curr_time - start_time)));
    }

    println!("{}", u64::from_be_bytes(Tai64::now().to_bytes()));

    let settle = instance
    .methods()
    .settle()
    .set_contract_ids(&[vending_machine_id.clone()])
    .append_variable_outputs(2)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(settle.value);

    let base_balance = instance
    .methods()
    .balance_of(ContractId::new(*BASE_ASSET_ID))
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(base_balance.value == 30000);

    let quote_balance = instance
    .methods()
    .balance_of(ContractId::new(*quote_id))
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    assert!(quote_balance.value == 0);

    let a = instance
    .methods()
    .balance_of(ContractId::new(*vending_machine_id.hash()))
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    println!("{}", a.value);

    let curr_time:u64 = u64::from_be_bytes(Tai64::now().to_bytes());
    if curr_time - start_time < bid_duration * 3 {
        thread::sleep(time::Duration::from_secs(bid_duration * 3 - (curr_time - start_time)));
    }

    let claim = instance
    .methods()
    .claim_lp_token()
    .set_contract_ids(&[vending_machine_id.clone()])
    .append_variable_outputs(1)
    .tx_params(my_tx_parameters)
    .call()
    .await
    .unwrap();

    let balance2 = deployer
                   .get_asset_balance(&AssetId::new(*vending_machine_id.hash()))
                   .await
                   .unwrap();

    assert!(balance2 == 70000);

    Ok(())
}