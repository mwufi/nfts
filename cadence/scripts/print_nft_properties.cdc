// e.g.: flow scripts execute ./cadence/scripts/print_nft_properties.cdc --arg Address:0x01cf0e2f2f715450 --arg UInt64:0

// This script returns the reference to KlktnNFT of a particular id

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

pub fun main(address: Address, tokenID: UInt64): &KlktnNFT.NFT {
  let account = getAccount(address)

  let collectionRef = account.getCapability(KlktnNFT.CollectionPublicPath)
    .borrow<&KlktnNFT.Collection{KlktnNFT.KlktnNFTCollectionPublic}>()
    ?? panic("Could not borrow capability from public collection")
  
  // Borrow a reference to a specific NFT in the Collection
  let klktnNFT = collectionRef.borrowKlktnNFT(id: tokenID)
    ?? panic("No such token in that collection")

  return klktnNFT
}