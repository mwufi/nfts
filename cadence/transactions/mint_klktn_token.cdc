//e.g. flow transactions send ./cadence/transactions/mint_klktn_token.cdc --arg Address:0x01cf0e2f2f715450 --arg UInt64:1

// This transction uses the Admin resource to mint a new NFT.
// It must be run with the account that has the admin resource stored at path /storage/KlktnNFTAdmin.

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction(recipient: Address, typeID: UInt64) {

  // local variable for storing the admin reference
  let admin: &KlktnNFT.Admin

  prepare(signer: AuthAccount) {
    // borrow a reference to the KlktnNFT Admin resource in storage
    self.admin = signer.borrow<&KlktnNFT.Admin>(from: KlktnNFT.AdminStoragePath)
      ?? panic("Could not borrow a reference to the KlktnNFT Admin")
  }

  execute {
    // get the public account object for the recipient
    let recipient = getAccount(recipient)

    // borrow the recipient's public NFT collection reference
    let receiver = recipient
      .getCapability(KlktnNFT.CollectionPublicPath)
      .borrow<&{NonFungibleToken.CollectionPublic}>()
      ?? panic ("Could not get receiver reference to the NFT Collection")

    // mint the NFT and deposit it to the recipient's collection
    self.admin.mintNFT(recipient: receiver, typeID: typeID)
  }
}