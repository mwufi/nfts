// e.g.: flow scripts execute ./cadence/scripts/peek_token_limit.cdc --arg UInt64:1

import MelonToken from "../contracts/MelonToken.cdc"

pub fun main(typeID: UInt64): UInt64 {

  let limit = MelonToken.peekTokenLimit(typeID: typeID) ?? panic("Play doesn't exist")
  return limit
}