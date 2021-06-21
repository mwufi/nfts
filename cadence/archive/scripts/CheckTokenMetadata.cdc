// import NonFungibleToken from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0x3b233bf6e83b0030
pub fun main(): {String: String} {
    // nftOwner: the account that owns the NFT
    let nftOwner = getAccount(0x3b233bf6e83b0030)
    
    // borrow capability from the contract NFTReceiver interface reference
    let capability = nftOwner.getCapability<&{NonFungibleToken.NFTReceiver}>(/public/NFTReceiver)


    // takes our capability and tells the script to borrow from the deployed contract
    let receiverRef = capability.borrow()
        ?? panic("Could not borrow the receiver reference")

    return receiverRef.getMetadata(id: 6)
}