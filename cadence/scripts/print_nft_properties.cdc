import MelonToken from "../contracts/MelonToken.cdc"

// e.g.: flow scripts execute ./cadence/scripts/print_nft_properties.cdc --arg Address:0x01cf0e2f2f715450 --arg UInt64:3

pub fun main(address: Address, tokenID: UInt64): &MelonToken.NFT {
  let account = getAccount(address)

  let collectionRef = account.getCapability(MelonToken.CollectionPublicPath)!.borrow<&{MelonToken.CollectionPublic}>()
    ?? panic("Could not borrow capability from public collection")
  
  return collectionRef.borrowNFT(id: tokenID)
}