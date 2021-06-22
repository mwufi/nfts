// Address arg needs to be added to execute the script
// e.g.: flow scripts execute ./cadence/scripts/read_collection_length.cdc --arg Address:0xf8d6e0586b0a20c7

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

// This script returns an array of all the NFT IDs in an account's collection.

pub fun main(address: Address): Int {
  let account = getAccount(address)

  let collectionRef = account.getCapability(KlktnNFT.CollectionPublicPath)
    .borrow<&{NonFungibleToken.CollectionPublic}>()
    ?? panic("Could not borrow capability from public collection")
  
  return collectionRef.getIDs().length
}
