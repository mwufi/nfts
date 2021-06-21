// example emulator transaction command:
// flow transactions send ./cadence/transactions/transfer_melon_token.cdc --arg Address:0xf8d6e0586b0a20c7 --arg UInt64:1 --signer account1
// i.e. to send token with id 1 from the account1 to the emulator-account

import MelonToken from "../contracts/MelonToken.cdc"

// This transaction transfers a MelonToken from one account to another.

transaction(recipient: Address, withdrawID: UInt64) {
  prepare(signer: AuthAccount) {
    // get the recipients public account object
    let recipient = getAccount(recipient)

    // borrow a reference to the signer's NFT collection
    let collectionRef = signer.borrow<&MelonToken.Collection>(from: MelonToken.CollectionStoragePath)
      ?? panic("Could not borrow a reference to the owner's collection")

    // borrow a public reference to the receivers collection
    let depositRef = recipient.getCapability(MelonToken.CollectionPublicPath)!
      .borrow<&{MelonToken.CollectionPublic}>()!

    // withdraw the NFT from the owner's collection
    let nft <- collectionRef.withdraw(withdrawID: withdrawID)

    // Deposit the NFT in the recipient's collection
    depositRef.deposit(token: <-nft)
  }
}