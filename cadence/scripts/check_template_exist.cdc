// e.g.: flow scripts execute ./cadence/scripts/check_template_exist.cdc --arg UInt64:1

import MelonToken from "../contracts/MelonToken.cdc"

pub fun main(typeID: UInt64): Bool {
  return MelonToken.checkTemplate(typeID: typeID)
}