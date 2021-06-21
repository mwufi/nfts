import MelonToken from "../contracts/MelonToken.cdc"

// This transaction configures an account to hold MelonTokens.

transaction {
  prepare(signer: AuthAccount) {
    // if the account already had a collection
    if signer.borrow<&MelonToken.Collection>(from: MelonToken.CollectionStoragePath) != nil {
      panic("A Collection is already setup for this account")
    }
    // if the account doesn't already have a collection
    if signer.borrow<&MelonToken.Collection>(from: MelonToken.CollectionStoragePath) == nil {
      // create a new empty collection
      let collection <- MelonToken.createEmptyCollection()
      // save it to the account
      signer.save(<-collection, to: MelonToken.CollectionStoragePath)
      // create a public capability for the collection
      signer.link<&MelonToken.Collection{MelonToken.CollectionPublic}>(MelonToken.CollectionPublicPath, target: MelonToken.CollectionStoragePath)
    }
  }
}