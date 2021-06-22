// e.g.: flow scripts execute ./cadence/scripts/check_collection_exist.cdc --arg Address:0xf8d6e0586b0a20c7
// e.g.: flow scripts execute ./cadence/scripts/check_collection_exist.cdc --arg Address:0x01cf0e2f2f715450

// This script checks if KlkNFT Collection exists in an account.

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

pub fun main(address: Address): Bool {
  let account = getAccount(address)

  var collectionCap = account.getCapability<&{NonFungibleToken.CollectionPublic}>(KlktnNFT.CollectionPublicPath)

  if collectionCap.check() {
    return true
  } else {
    return false
  }
}
