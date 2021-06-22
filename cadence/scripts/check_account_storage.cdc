// flow scripts execute ./cadence/scripts/check_account_storage.cdc --arg Address:0xf8d6e0586b0a20c7

// checks account storage used and storage capacity
pub fun main(address: Address): {String: UInt64} {
  let account = getAccount(address)
  let storageUsed = account.storageUsed
  let storageCapacity = account.storageCapacity
  let storageAvailable = storageCapacity - storageUsed
  return {
    "storageUsed": storageUsed,
    "storageCapacity": storageCapacity,
    "storageAvailable": storageAvailable
  }
}