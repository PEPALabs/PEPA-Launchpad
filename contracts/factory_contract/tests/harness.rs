use fuels::{prelude,prelude::*, tx::ContractId,tx::Bytes32,types::Bits256};

// Load abi from json
abigen!(
    Contract( name="Factory", abi="out/debug/factory_contract-abi.json"),
    Contract( name="Ido", abi="../ido_contract/out/debug/ido_contract-abi.json"),
);

async fn get_contract_instance() -> (Factory, ContractId, Ido, ContractId, WalletUnlocked) {
    // Launch a local network and deploy the contract
    let mut wallets = launch_custom_provider_and_get_wallets(
        WalletsConfig::new(
            Some(1),             /* Single wallet */
            Some(1),             /* Single coin (UTXO) */
            Some(1_000_000_000), /* Amount per coin */
        ),
        None,
        None,
    )
    .await;
    let wallet = wallets.pop().unwrap();

    //build factory
    let factory_id = Contract::deploy(
        "./out/debug/factory_contract.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(Some(
            "./out/debug/factory_contract-storage_slots.json".to_string(),
        )),
    )
    .await
    .unwrap();

    let factory_instance = Factory::new(factory_id.clone(), wallet.clone());
    //build ido
    let ido_id = Contract::deploy(
        "../ido_contract/out/debug/ido_contract.bin",
        &wallet,
        TxParameters::default(),
        StorageConfiguration::with_storage_path(Some(
            "../ido_contract/out/debug/ido_contract-storage_slots.json".to_string(),
        )),
    )
    .await
    .unwrap();

    let ido_instance = Ido::new(ido_id.clone(), wallet.clone());

    (factory_instance, factory_id.into(), ido_instance, ido_id.into(), wallet.clone())
}

async fn initialize_pool() {
    let (factory_instance, factory_id, ido_instance,ido_id, wallet) = get_contract_instance().await;

    // initialize pool

}

#[tokio::test]
async fn can_get_contract_id() {
    let (factory_instance, factory_id, ido_instance,ido_id, wallet) = get_contract_instance().await;

    // Now you have an instance of your contract you can use to test each function
}

#[tokio::test]
async fn can_initialize() -> Result<()>{
    let (factory_instance, factory_id, ido_instance,ido_id, wallet) = get_contract_instance().await;

    // Now you have an instance of your contract you can use to test each function
    let result = factory_instance.methods().initialize(Bits256(*ido_id)).call().await?;
    Ok(())
}

#[tokio::test]
async fn can_not_re_initialize() -> Result<()>{
    let (factory_instance, factory_id, ido_instance,ido_id, wallet) = get_contract_instance().await;

    // Now you have an instance of your contract you can use to test each function
    let result = factory_instance.methods().initialize(Bits256(*ido_id)).call().await?;
    let result1 = factory_instance.methods().initialize(Bits256(*ido_id)).call().await;
    assert!(matches!(result1, Err(prelude::Error::RevertTransactionError { .. })));
    Ok(())
}

// TODO: Add test for not allowing uninitialized IDO to be added?
// #[tokio::test]
// async fn can_not_add_ido_uninitialized() -> Result<()>{
//     let (factory_instance, factory_id, ido_instance,ido_id, wallet) = get_contract_instance().await;

//     let result = factory_instance.methods().initialize(Bits256(*ido_id)).call().await?;
//     // Now you have an instance of your contract you can use to test each function
//     let result1 = factory_instance.methods().add_ido(BASE_ASSET_ID, BASE_ASSET_ID,Bits256(*ido_id), Bits256(*wallet.address().hash())).call().await?;
//     assert!(matches!(result1, Err(prelude::Error::RevertTransactionError { .. })));
//     Ok(())
// }

#[tokio::test]
async fn can_add_ido() -> Result<()>{
    let (factory_instance, factory_id, ido_instance,ido_id, wallet) = get_contract_instance().await;

    let result = factory_instance.methods().initialize(Bits256(*ido_id)).call().await?;
    // Now you have an instance of your contract you can use to test each function
    let result1 = factory_instance.methods().add_ido(Bits256(*BASE_ASSET_ID), Bits256(*BASE_ASSET_ID),Bits256(*ido_id), Bits256(*wallet.address().hash())).call().await?;
    Ok(())
}

#[tokio::test]
async fn can_not_add_duplicate_ido() -> Result<()>{
    let (factory_instance, factory_id, ido_instance,ido_id, wallet) = get_contract_instance().await;

    let result = factory_instance.methods().initialize(Bits256(*ido_id)).call().await?;
    // Now you have an instance of your contract you can use to test each function
    let result1 = factory_instance.methods().add_ido(Bits256(*BASE_ASSET_ID), Bits256(*BASE_ASSET_ID),Bits256(*ido_id), Bits256(*wallet.address().hash())).call().await?;
    let result2 = factory_instance.methods().add_ido(Bits256(*BASE_ASSET_ID), Bits256(*BASE_ASSET_ID),Bits256(*ido_id), Bits256(*wallet.address().hash())).call().await;
    assert!(matches!(result2, Err(prelude::Error::RevertTransactionError { .. })));
    Ok(())
}

