// e.g.: flow scripts execute ./cadence/scripts/check_token_expiration.cdc --arg UInt64:1

import MelonToken from "../contracts/MelonToken.cdc"

pub fun main(typeID: UInt64): Bool {
  return MelonToken.checkTokenExpiration(typeID: typeID)
}