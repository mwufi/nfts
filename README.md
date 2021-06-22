# KLKTN NFTs

## Roles

* Minter: Controlled by KLKTN, can create NFT templates and mint NFTs.

* Mintee: Controlled by KLKTN, holds the NFTs that are minted on a custodial way. Later allows users to withdraw their NFTs to their wallets.

* Bowser: Represents some customer account.


## Contracts

* NonFungibleToken.cdc: We created this for local emulator testing purposes, which is the NonFungibleToken standard on Flow testnet and mainnet

* KlktnNFT.cdc: This contract implements the NonFungibleToken contract interface

## Transactions

* setup_account.cdc: This transaction configures an account to hold KlktnNFT. At first only used for our custodial account, as we implement withdraws, users can use it as well.

* create_token_template.cdc: This transaction uses the NFTMinter resource to create an NFT template of typeID, it must be run with the account that has the minter resource stored at path /storage/NFTMinter.

* mint_klktn_token.cdc: This transaction uses the NFTMinter resource to mint a new NFT, it must be run with the account that has the minter resource stored at path /storage/NFTMinter.

* transfer_klktn_token.cdc: This transaction transfers a KlktnNFT from one account to another.

### Note: the transaction below was used on emulator and testnet for re-deployment of contracts only
*  destroy_minter.cdc: This transaction is used to remove the minter from Minter storage when we remove the contract.

## Scripts

* check_account_storage.cdc: This script checks account storage used and storage capacity for an account.

* check_collection_exist.cdc: This script returns an array of all the NFT IDs in an account's Collection.

* check_template_exist.cdc: This script checks if a template of typeID exists.

* check_token_expiration.cdc: This script checks if a token is expired.
  
* peek_token_limit.cdc: This script checks the enforced mint limit for token of a typeID.

* print_nft_properties.cdc: This script returns the reference to KlktnNFT of a particular id

* read_collection_ids.cdc: This script returns an array of all the NFT IDs in an account's Collection.

* read_collection_length.cdc: This script returns the number of NFT tokens in an account's Collection.


## Tests

Please use node v14

Due to some issue with dependencies we've committed `node_modules`, for now don't run `npm install` or it might break packages ([described in more detail here](https://github.com/onflow/flow-js-testing/issues/38))

**Run** `npm test` to run the 3 tests we setup below for testing the Cadence contracts, transactions, and scripts, you may also find the test files in the ./test folder

* deploy test:
This test will perform the following tests below
  * Account Creation 
    * start a Flow emulator and register for a "Mintee" account and a "Bowser" account
  * Contract Deployment
    * Deploy NonFungibleToken contract
    * Deploy KlktnNFT contract
  * Transactions & scripts
    * setup Klktn Collection for Minter(default 0xf8d6e0586b0a20c7) and Mintee account
    * create token templates for the NFT resource
    * mint tokens and check serial numbers for minted tokens
    * expire token when token reaches to the enforced mint limit per typeID
  * External transfer
    * transfer token from Mintee account to Bowser account
* storage test:
  * deploy contracts, setup KlktnNFT Collections
  * mint tokens to Mintee account to test space used per transaction
* stress test:
  * deploy contracts, setup KlktnNFT Collections
  * mint large number of tokens (default 100) to the default Minter account(0xf8d6e0586b0a20c7) to test `read_collection_ids.cdc` and `read_collection_length.cdc` scripts (Note: number of tokens can be changed in ./test/config.js file by modifying the stressTokenNumber value)
