// e.g. flow transactions send ./cadence/transactions/destroy_admin.cdc --network testnet --signer testnet-minter

// This transaction is used to remove the admin from Admin storage when we remove the contract.

import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction {
  prepare(signer: AuthAccount) {
    let adminResource <- signer.load<@KlktnNFT.Admin>(from: KlktnNFT.AdminStoragePath)
    destroy adminResource
  }
}