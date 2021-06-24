// flow transactions send ./cadence/transactions/create_token_template.cdc --arg UInt64:1 --arg String:"Kevin Heart" --arg UInt64:399 --arg {String: String}:[{key: 'artist', value: 'Kevin Woo'}]

// Question to Flow team: how to use flow CLI to pass in dictionary {String: String} objects (the command above is not working)?


// This transction uses the Admin resource to create an NFT template of typeID.
// - It must be run with the account that has the admin resource stored at path /storage/KlktnNFTAdmin.

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction(typeID: UInt64, tokenName: String, mintLimit: UInt64, metadata: {String: String}) {

  // local variable for storing the admin reference
  let admin: &KlktnNFT.Admin

  prepare(signer: AuthAccount) {
    // borrow a reference to the KlktnNFT admin resource in storage
    self.admin = signer.borrow<&KlktnNFT.Admin>(from: KlktnNFT.AdminStoragePath)
      ?? panic("Could not borrow a reference to the KlktnNFT Admin")
  }

  execute {
    self.admin.createTemplate(typeID: typeID, tokenName: tokenName, mintLimit: mintLimit, metadata: metadata)
  }
}