pub contract NonFungibleToken {

// ======================================== resources
    // the NFT resource with id to uniquely identify the token
    pub resource NFT {
        pub let id: UInt64
        
        init(initID: UInt64) {
            self.id = initID
        }
    }

    // token collection resource
    // think this as the wallet that houses all user's NFT
    pub resource Collection: NFTReceiver {

        // ownedNFTs
        // - keeps track of all the NFTs a user owns from this contract
        pub var ownedNFTs: @{UInt64: NFT}
        
        // metadataObjs
        // - maps the token id and the metadata
        pub var metadataObjs: {UInt64: {String: String}}

        init() {
            self.ownedNFTs <- {}
            self.metadataObjs = {}
        }

        // below are all of the available functions for our NFT collection resource
        pub fun withdraw(withdrawID: UInt64): @NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)!
            return <- token
        }

        pub fun deposit(token: @NFT, metadata: {String: String}) {
            self.metadataObjs[token.id] = metadata
            self.ownedNFTs[token.id] <-! token
        }

        pub fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        pub fun updateMetadata(id: UInt64, metadata: {String: String}) {
            self.metadataObjs[id] = metadata
        }

        pub fun getMetadata(id: UInt64): {String: String} {
            return self.metadataObjs[id]!
        }

        destroy () {
            destroy self.ownedNFTs
        }
    }

    // minter resource
    // - idCount is incremented to ensure we never have duplicated ids for out NFTs
    // - and the mintNFT function actually creates our NFT
    pub resource NFTMinter {
        pub var idCount: UInt64

        init() {
            self.idCount = 1
        }

        pub fun mintNFT(): @NFT {
            var newNFT <- create NFT(initID: self.idCount)
            self.idCount = self.idCount + 1 as UInt64
            return <- newNFT
        }
    }

// ======================================== interfaces

    // This NFTReceiver resource interface is saying that
    // whoever we define as having access to the resource
    // will be able to call the following methods
    pub resource interface NFTReceiver {
        pub fun deposit(token: @NFT, metadata: {String: String})
        pub fun getIDs(): [UInt64]
        pub fun idExists(id: UInt64): Bool
        pub fun getMetadata(id: UInt64): {String: String}
    }

// ======================================== methods
    // createEmptyCollection
    // - a function that creates an empty NFT collection when called
    pub fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

// ======================================== main contract initializer
    // the contract initalizer will only be called when contract is deployed
    // - 1. create aan empty collection for the deployer of the collectio
    // - so that the owner of the contract can mint and own NFTs from that contract
    // - 2. the Collection resource is published in a public location with reference to
    // - the NFTReceiver interface, so the functions in the NFTReceiver can be called by anyone
    // - 3. the NFTMinter resource is saved in account storage for the creator of the contract
    // - so that only the creator can mint tokens (with the NFTMinter)
    init() {
        self.account.save(<-self.createEmptyCollection(), to: /storage/NFTCollection)
        self.account.link<&{NFTReceiver}>(/public/NFTReceiver, target: /storage/NFTCollection)
        self.account.save(<-create NFTMinter(), to: /storage/NFTMinter)
    }

}