//e.g. flow transactions send ./cadence/transactions/update_template_metadata.cdc --arg UInt64:1 -- arg <json>

// This transction uses the Admin resource to update metadata for token template of typeID
// It must be run with the account that has the admin resource stored at path /storage/KlktnNFTAdmin.

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction(typeID: UInt64, metadataToUpdate: {String: String}) {

  // local variable for storing the admin reference
  let admin: &KlktnNFT.Admin

  prepare(signer: AuthAccount) {
    // borrow a reference to the Admin resource in storage
    self.admin = signer.borrow<&KlktnNFT.Admin>(from: KlktnNFT.AdminStoragePath)
      ?? panic("Could not borrow a reference to the KlktnNFT Admin")
  }

  execute {
    // update metadata
    self.admin.updateTemplateMetadata(typeID: typeID, metadataToUpdate: metadataToUpdate)
  }
}