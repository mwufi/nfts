// Address arg needs to be added to execute the script
// e.g.: flow scripts execute ./cadence/scripts/read_collection_ids.cdc --arg Address:0xf8d6e0586b0a20c7
// e.g.: flow scripts execute ./cadence/scripts/read_collection_ids.cdc --arg Address:0x01cf0e2f2f715450

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

// This script returns an array of all the NFT IDs in an account's collection.

pub fun main(address: Address): [UInt64] {
  let account = getAccount(address)

  let collectionRef = account.getCapability(KlktnNFT.CollectionPublicPath)
    .borrow<&{NonFungibleToken.CollectionPublic}>()
    ?? panic("Could not borrow capability from public collection")
  
  return collectionRef.getIDs()
}
