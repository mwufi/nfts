// e.g.: flow scripts execute ./cadence/scripts/check_token_expiration.cdc --arg UInt64:1

import KlktnNFT from "../contracts/KlktnNFT.cdc"

pub fun main(typeID: UInt64): Bool {
  return KlktnNFT.checkTokenExpiration(typeID: typeID)
}