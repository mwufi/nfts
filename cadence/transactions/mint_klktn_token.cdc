// example emulator command:
// flow transactions send ./cadence/transactions/mint_melon_token.cdc --arg Address:0x01cf0e2f2f715450 --arg UInt64:1

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

// This transction uses the NFTMinter resource to mint a new NFT.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(recipient: Address, typeID: UInt64) {

  // local variable for storing the minter reference
  let minter: &KlktnNFT.NFTMinter

  prepare(signer: AuthAccount) {
    // borrow a reference to the NFTMinter resource in storage
    self.minter = signer.borrow<&KlktnNFT.NFTMinter>(from: KlktnNFT.MinterStoragePath)
      ?? panic("Could not borrow a reference to the NFTMinter")
  }

  execute {
    // get the public account object for the recipient
    let recipient = getAccount(recipient)

    // borrow the recipient's public NFT collection reference
    let receiver = recipient
      .getCapability(KlktnNFT.CollectionPublicPath)
      .borrow<&{NonFungibleToken.CollectionPublic}>()
      ?? panic ("Could not get receiver reference to the NFT Collection")

    // mint the NFT and deposit it to the recipient's collection
    self.minter.mintNFT(recipient: receiver, typeID: typeID)
  }
}