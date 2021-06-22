import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

// flow transactions send ./cadence/transactions/setup_account.cdc --signer account1

// This transaction configures an account to hold KlktnNFT.

transaction {
  prepare(signer: AuthAccount) {
    // if the account already had a collection
    if signer.borrow<&KlktnNFT.Collection>(from: KlktnNFT.CollectionStoragePath) != nil {
      panic("A Collection is already setup for this account")
    }
    // if the account doesn't already have a collection
    if signer.borrow<&KlktnNFT.Collection>(from: KlktnNFT.CollectionStoragePath) == nil {
      // create a new empty collection
      let collection <- KlktnNFT.createEmptyCollection()
      // save it to the account
      signer.save(<-collection, to: KlktnNFT.CollectionStoragePath)
      // create a public capability for the collection
      signer.link<&KlktnNFT.Collection{NonFungibleToken.CollectionPublic, KlktnNFT.KlktnNFTCollectionPublic}>(KlktnNFT.CollectionPublicPath, target: KlktnNFT.CollectionStoragePath)
    }
  }
}