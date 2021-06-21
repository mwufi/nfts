// Archive: purpose is to create Flow accounts for each newly registered user

// transaction(flowKey: String, contract: String) {
//   prepare(acct: AuthAccount) {
//     newAccount = AuthAccount(payer: acct)
//     newAccount.addPublicKey(flowKey.decodeHex())
//     newAccount.setCode(contract.decodeHex())
//   }
// }