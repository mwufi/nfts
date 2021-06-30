// flow transactions send ./cadence/transactions/try_mutate_metadata.cdc --signer account1 --arg UInt64: 0

// For testing purpose only
// This transaction tries to mutate the metadata for a token
// but metadata won't be mutated as the klktnNFT.getNFTMetadata() method only returns a copy of the metadata

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction (tokenID: UInt64) {
  prepare(signer: AuthAccount) {
    let collectionRef = signer.getCapability(KlktnNFT.CollectionPublicPath)
    .borrow<&KlktnNFT.Collection{KlktnNFT.KlktnNFTCollectionPublic}>()
    ?? panic("Could not borrow capability from public collection")

    // Borrow a reference to a specific NFT in the Collection
    let klktnNFT = collectionRef.borrowKlktnNFT(id: tokenID)
    ?? panic("No such token in that collection")

    let metadata = klktnNFT.getNFTMetadata()
    metadata["extra"] = "345"
    metadata["releaseYear"] = "2039"
  }
}