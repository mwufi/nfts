// e.g.: flow scripts execute ./cadence/scripts/peek_token_limit.cdc --arg UInt64:1

// This script checks the enforced mint limit for token of a typeID.

import KlktnNFT from "../contracts/KlktnNFT.cdc"

pub fun main(typeID: UInt64): UInt64 {

  let limit = KlktnNFT.peekTokenLimit(typeID: typeID) ?? panic("Play doesn't exist")
  return limit
}