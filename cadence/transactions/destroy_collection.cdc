// flow transactions send ./cadence/transactions/destroy_collection.cdc --signer account1

// This transaction destroys a KlktnNFT collection in an account

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction {
  prepare(signer: AuthAccount) {
    let collectionResource <- signer.load<@KlktnNFT.Collection>(from: KlktnNFT.CollectionStoragePath)
    destroy collectionResource
  }
}