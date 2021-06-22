// e.g.: flow scripts execute ./cadence/scripts/check_template_exist.cdc --arg UInt64:1

// This script checks if a template of typeID exists.

import KlktnNFT from "../contracts/KlktnNFT.cdc"

pub fun main(typeID: UInt64): Bool {
  return KlktnNFT.checkTemplate(typeID: typeID)
}