//e.g. flow transactions send ./cadence/transactions/update_metadata.cdc --arg UInt64:1 -- arg <json>

// This transction uses the NFTMinter resource to update metadata for token template of typeID
// It must be run with the account that has the minter resource stored at path /storage/NFTMinter.

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction(typeID: UInt64, metadataToUpdate: {String: String}) {

  // local variable for storing the minter reference
  let minter: &KlktnNFT.NFTMinter

  prepare(signer: AuthAccount) {
    // borrow a reference to the NFTMinter resource in storage
    self.minter = signer.borrow<&KlktnNFT.NFTMinter>(from: KlktnNFT.MinterStoragePath)
      ?? panic("Could not borrow a reference to the NFTMinter")
  }

  execute {
    // update metadata
    self.minter.updateTemplateMetaData(typeID: typeID, metadataToUpdate: metadataToUpdate)
  }
}