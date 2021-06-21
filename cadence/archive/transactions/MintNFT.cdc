// 0xf8d6e0586b0a20c7 is the account that deployed the contract
import NonFungibleToken from "../contracts/NonFungibleToken.cdc"

transaction {

    // receiverRef type is reference of NFTReceiver interface
    let receiverRef: &{NonFungibleToken.NFTReceiver}
    // mintRef is the NFTMinter resource
    let minterRef: &NonFungibleToken.NFTMinter

    prepare(acct: AuthAccount) {
        self.receiverRef = acct.getCapability<&{NonFungibleToken.NFTReceiver}>(/public/NFTReceiver)
            .borrow()
            ?? panic("Could not borrow receiver reference")

        self.minterRef = acct.borrow<&NonFungibleToken.NFTMinter>(from: /storage/NFTMinter)
            ?? panic("Could not borrow minter reference")
    }

    execute {
        // the template token
        let metadata: {String: String} = {
            "type_id": TYPE_ID,
            "artist":  ARTIST,
            "item_description": ITEM_DESCRIPTION,
            "uri": URI_LINK,
            "serial_number": SERIAL_NUMBER,
            "owner": OWNER
        }
        // // the bunny video
        // let metadata: {String: String} = {
        //     "name": "The Giant Rabbit",
        //     "video_length": "125",
        //     "rabbit_colow": "grey",
        //     "uri": "ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7",
        //     "cute_butt": "true",
        //     "owner": "",
        // }
        
        let newNFT <- self.minterRef.mintNFT()
        self.receiverRef.deposit(token: <-newNFT, metadata: metadata)
        log ("NFT minted and deposited to Deployer Account's Collection")

        // // the globe video
        // let metadata: {String: String} = {
        //     "name": "The Giant Globe",
        //     "video_length": "30",
        //     "rabbit_colow": "NA",
        //     "uri": "ipfs://QmeynYjeMnWVXs4APAfr1GNRqUteAz3ABxYfBYGdstNvVB",
        //     "cute_butt": "false"
        // }
        
        // let newNFT <- self.minterRef.mintNFT()
        // self.receiverRef.deposit(token: <-newNFT, metadata: metadata)
        // log ("NFT minted and deposited to Account 2's Collection")
    }
}