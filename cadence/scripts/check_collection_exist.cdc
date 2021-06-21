// Address arg needs to be added to execute the script
// e.g.: flow scripts execute ./cadence/scripts/check_collection_exist.cdc --arg Address:0xf8d6e0586b0a20c7
// e.g.: flow scripts execute ./cadence/scripts/check_collection_exist.cdc --arg Address:0x01cf0e2f2f715450

import MelonToken from "../contracts/MelonToken.cdc"

// This script returns an array of all the NFT IDs in an account's collection.

pub fun main(address: Address): Bool {
  let account = getAccount(address)

  var collectionCap = account.getCapability<&{MelonToken.CollectionPublic}>(MelonToken.CollectionPublicPath)

  if collectionCap.check() {
    return true
  } else {
    return false
  }
}
