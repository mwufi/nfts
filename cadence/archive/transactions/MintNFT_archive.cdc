// Archive: purpose is to mint token to user accounts


// 0xf8d6e0586b0a20c7 is the account that deployed the contract
// import NonFungibleToken from "../contracts/NonFungibleToken.cdc"
import NonFungibleToken from "f8d6e0586b0a20c7"

transaction {

    // local variable for storing the minter reference
    let minterRef: &NonFungibleToken.NFTMinter

    prepare(acct: AuthAccount) {
        // borrow a reference to the NFTMinter resource in storage
        self.minterRef = acct.borrow<&NonFungibleToken.NFTMinter>(from: /storage/NFTMinter)
            ?? panic("Could not borrow minter reference")
    }

    execute {
        // get public account object
        let receipient = getAccount(0x01cf0e2f2f715450)

        // borrow the recipient's public NFT collection reference
        let receipientCapability: receipient.getCapability(/public/NFTReceiver)
            .borrow<&{ExampleNFT.NFTReceiver}>()
            ?? panic("Could not borrow account 0x01cf0e2f2f715450 receiver reference")

        // the bunny video
        let metadata: {String: String} = {
            "name": "The Giant Rabbit",
            "video_length": "125",
            "rabbit_colow": "grey",
            "uri": "ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7",
            "cute_butt": "true"
        }

        // mint the NFT and deposit it to the recipient's collection
        self.minter.mintNFT(receipient: receiver, metaData: metaData)
        
        let newNFT <- self.minterRef.mintNFT()
        self.receiverRef.deposit(token: <-newNFT, metadata: metadata)
        log ("NFT minted and deposited to Account 0x01cf0e2f2f715450's Collection")

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