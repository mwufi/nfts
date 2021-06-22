// e.g. flow transactions send ./cadence/transactions/destroy_minter.cdc --network testnet --signer testnet-minter

// This transaction is used to remove the minter from Minter storage when we remove the contract.

import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction {
  prepare(signer: AuthAccount) {
    let minterResource <- signer.load<@KlktnNFT.NFTMinter>(from: KlktnNFT.MinterStoragePath)
    destroy minterResource
  }
}