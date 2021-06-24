// configs for default Flow emulator, Cadence contracts, transactions, and scripts
// For Unit Testing Purposes Only

import path from "path"

const getFlowConfigs = () => {
  // emulatore configs
  const basePath = path.resolve(__dirname, "../cadence")
  const defaultPort = 8082
  const storageTestPort = 8081
  const stressTestPort = 8083
  // Minter account is the default emulator account
  const Minter = '0xf8d6e0586b0a20c7'
  // contract name
  const contractName = "KlktnNFT"
  const nonFungibleTokenContractName = "NonFungibleToken"
  // transaction files
  const setupAccountTransactionFileName = 'setup_account'
  const createTokenTemplateTransactionFileName = 'create_token_template'
  const mintKlktnNFTTransactionFileName = 'mint_klktn_token'
  const transferTokenTransactionFileName = 'transfer_klktn_token'
  const updateMetadataTransactionFileName = 'update_template_metadata'
  const transactions = {
    setupAccount: setupAccountTransactionFileName,
    createTokenTemplate: createTokenTemplateTransactionFileName,
    mintKlktnNFT: mintKlktnNFTTransactionFileName,
    transferToken: transferTokenTransactionFileName,
    updateMetadata: updateMetadataTransactionFileName,
  }
  // script files
  const checkAccountStorageScriptFileName = 'check_account_storage'
  const checkCollectionLengthScriptFileName = 'read_collection_length'
  const checkCollectionIdsScriptFileName = 'read_collection_ids'
  const printNFTPropertiesScriptFileName = 'print_nft_properties'
  const checkTokenExpireScriptFileName = 'check_token_expiration'
  const checkStorageScriptFileName = 'check_account_storage'
  const scripts = {
    checkAccountStorage: checkAccountStorageScriptFileName,
    checkCollectionLength: checkCollectionLengthScriptFileName,
    printNFTProperties: printNFTPropertiesScriptFileName,
    checkTokenExpire: checkTokenExpireScriptFileName,
    listCollectionIds: checkCollectionIdsScriptFileName,
    checkAccountStorage: checkStorageScriptFileName,
  }
  // Minter address map
  // note: addressMap format must be: {contractName: contractDeployedAddress}
  const minterAddressMap = {
    KlktnNFT: Minter,
    NonFungibleToken: Minter,
  }
  // number of tokens to mint for stress testing
  // Note: this needs to be lower than the mint limit per typeID
  const stressTokenNumber = 100
  return {
    basePath,
    Minter,
    contractName,
    nonFungibleTokenContractName,
    transactions,
    scripts,
    minterAddressMap,
    defaultPort,
    storageTestPort,
    stressTestPort,
    stressTokenNumber,
  }
}

module.exports = { getFlowConfigs }