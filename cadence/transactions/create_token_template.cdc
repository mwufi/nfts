// flow transactions send ./cadence/transactions/create_token_template.cdc --arg UInt64:1 --arg String:"Kevin Heart" --arg UInt64:399 --arg {String: String}:[{key: 'artist', value: 'Kevin Woo'}]

// Question to Flow team: how to use flow CLI to pass in dictionary {String: String} objects (the command aboce is not working)?


// This transction uses the NFTMinter resource to create an NFT template of typeID.
// - It must be run with the account that has the minter resource stored at path /storage/NFTMinter.

import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import KlktnNFT from "../contracts/KlktnNFT.cdc"

transaction(typeID: UInt64, tokenName: String, mintLimit: UInt64, metaData: {String: String}) {

  // local variable for storing the minter reference
  let minter: &KlktnNFT.NFTMinter

  prepare(signer: AuthAccount) {
    // borrow a reference to the NFTMinter resource in storage
    self.minter = signer.borrow<&KlktnNFT.NFTMinter>(from: KlktnNFT.MinterStoragePath)
      ?? panic("Could not borrow a reference to the NFTMinter")
  }

  execute {
    self.minter.createTemplate(typeID: typeID, tokenName: tokenName, mintLimit: mintLimit, metaData: metaData)
  }
}