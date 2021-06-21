// example emulator command:
// gave up on passing Dictionary{String: String} with bash or zsh after 4 hours try...rip
// the transaction can be sent via the NFT route and NFTService from the backend with Javascript SDK
// flow transactions send ./cadence/transactions/create_token_template.cdc --arg UInt64:1 --arg String:"Kevin Heart" --arg UInt64:399 --arg {String: String}:[{key: 'artist', value: 'Kevin Woo'}]

import MelonToken from "../contracts/MelonToken.cdc"

// This transction uses the NFTMinter resource to mint a new NFT.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(typeID: UInt64, tokenName: String, mintLimit: UInt64, metaData: {String: String}) {

  // local variable for storing the minter reference
  let minter: &MelonToken.NFTMinter

  prepare(signer: AuthAccount) {
    // borrow a reference to the NFTMinter resource in storage
    self.minter = signer.borrow<&MelonToken.NFTMinter>(from: MelonToken.MinterStoragePath)
      ?? panic("Could not borrow a reference to the NFTMinter")
  }

  execute {
    self.minter.createTemplate(typeID: typeID, tokenName: tokenName, mintLimit: mintLimit, metaData: metaData)
  }
}