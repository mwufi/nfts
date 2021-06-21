// import NonFungibleToken from "./NonFungibleToken.cdc"

// MelonToken contract implements the NonFungibleToken interface
// so it implements the behavior including
// Collection resource with Provider, Receiver, CollectionPublic resource interfaces
// ContractInitialized(), Withdraw(), Deposit() events
// createEmptyCollection() method
// and UInt64 totalSupply property

pub contract MelonToken {

  // -----------------------------------------------------------------------
  // MelonToken Contract Events
  // -----------------------------------------------------------------------

  // Emitted when MelonToken contract is created
  pub event ContractInitialized()
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Minted(id: UInt64, typeID: UInt64, serialNumber: UInt64, metaData: {String: String})
  pub event NFTTemplateCreated(typeID: UInt64, tokenName: String, mintLimit: UInt64, metaData: {String: String})
  // -----------------------------------------------------------------------
  // MelonToken Contract Named Paths
  // -----------------------------------------------------------------------
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath

  // -----------------------------------------------------------------------
  // MelonToken Contract Properties
  // -----------------------------------------------------------------------
  // The total number of MelonTokens that have been minted
  pub var totalSupply: UInt64
  // The hashtable for metaData and administrative parameters per typeID
  pub var melonTokenTypeSet: {UInt64: MelonTokenMetaData}
  pub var tokenExpiredPerType: {UInt64: Bool}
  pub var tokenMintedPerType: {UInt64: UInt64}

  // -----------------------------------------------------------------------
  // MelonToken Contract Resource Interfaces
  // -----------------------------------------------------------------------
  // Interface to mediate withdraws from the Collection
  pub resource interface Provider {
      // withdraw removes an NFT from the collection and moves it to the caller
      pub fun withdraw(withdrawID: UInt64): @NFT {
          post {
            result.id == withdrawID: "The ID of the withdrawn token must be the same as the requested ID"
          }
      }
  }

  // Interface to mediate deposits to the Collection
  pub resource interface Receiver {
    // deposit takes an NFT as an argument and adds it to the Collection
    pub fun deposit(token: @NFT)
  }

  // Interface that the NFTs have to conform to
  pub resource interface INFT {
      // The unique ID that each NFT has
      pub let id: UInt64
  }

  // This is the interface that users can cast their MelonToken Collection as
  // to allow others to deposit MelonTokens into their Collection. It also allows for reading
  // the details of MelonTokens in the Collection.
  pub resource interface CollectionPublic {
    pub fun deposit(token: @NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NFT
    pub fun borrowMelonToken(id: UInt64): &MelonToken.NFT? {
      // If the result isn't nil, the id of the returned reference
      // should be the same as the argument to the function
      post {
        (result == nil) || (result?.id == id):
          "Cannot borrow MelonToken reference: The ID of the returned reference is incorrect"
      }
    }
  }

  // -----------------------------------------------------------------------
  // MelonToken Structs
  // -----------------------------------------------------------------------
  // MelonTokenMetaData: metadata and admin properties of each typeID
  pub struct MelonTokenMetaData {
    pub let typeID: UInt64
    pub let tokenName: String
    pub var mintLimit: UInt64
    pub let metaData: {String: String}

    init(initTypeID: UInt64, initTokenName: String, initMintLimit: UInt64, initMetaData: {String: String}){
      self.typeID = initTypeID
      self.tokenName = initTokenName
      self.mintLimit = initMintLimit
      self.metaData = initMetaData
      emit NFTTemplateCreated(typeID: initTypeID, tokenName: initTokenName, mintLimit: initMintLimit, metaData: initMetaData)
    }
  }

  // -----------------------------------------------------------------------
  // MelonToken Resources
  // -----------------------------------------------------------------------
  pub resource NFT: INFT {
    // the unique id for the NFT
    pub let id: UInt64
    pub let typeID: UInt64
    pub let serialNumber: UInt64
    pub let metaData: {String: String}

    init(initID: UInt64, initTypeID: UInt64, initSerialNumber: UInt64) {
      self.id = initID
      self.typeID = initTypeID
      self.serialNumber = initSerialNumber
      self.metaData = MelonToken.melonTokenTypeSet[initTypeID]!.metaData
    }
  }

  // A collection of MelonToken NFTs owned by an account
  pub resource Collection: CollectionPublic, Provider, Receiver {
    pub var ownedNFTs: @{UInt64: NFT}

    // withdraw: Removes an NFT from the collection and moves it to the caller
    pub fun withdraw(withdrawID: UInt64): @MelonToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
      emit Withdraw(id: token.id, from: self.owner?.address)
      return <-token
    }

    // deposit: Takes a NFT and adds it to the collections dictionary
    // and adds the ID to the id array
    pub fun deposit(token: @MelonToken.NFT) {
      let token <- token as! @MelonToken.NFT
      let id: UInt64 = token.id
      // add the new token to the dictionary which removes the old one
      let oldToken <- self.ownedNFTs[id] <- token
      emit Deposit(id: id, to: self.owner?.address)
      destroy oldToken
    }

    // Returns an array of the IDs that are in the collection
    pub fun getIDs(): [UInt64] {
      return self.ownedNFTs.keys
    }

    // Gets a reference to an NFT in the collection
    // so that the caller can read its metadata and call its methods
    //
    pub fun borrowNFT(id: UInt64): &MelonToken.NFT {
      return &self.ownedNFTs[id] as &MelonToken.NFT
    }

    // Gets a reference to an NFT in the collection as a KittyItem,
    // exposing all of its fields (including the typeID).
    // This is safe as there are no functions that can be called on the KittyItem.
    //
    pub fun borrowMelonToken(id: UInt64): &MelonToken.NFT? {
      if self.ownedNFTs[id] != nil {
        let ref = &self.ownedNFTs[id] as auth &MelonToken.NFT
        return ref as! &MelonToken.NFT
      } else {
        return nil
      }
    }

    // destructor
    destroy() {
      destroy self.ownedNFTs
    }

    // initializer
    //
    init () {
      self.ownedNFTs <- {}
    }
  }

  // createEmptyCollection
  // public function that anyone can call to create a new empty collection
  //
  pub fun createEmptyCollection(): @MelonToken.Collection {
    return <- create Collection()
  }

  pub resource NFTMinter {

		// mintNFT: Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		pub fun mintNFT(recipient: &{MelonToken.CollectionPublic}, typeID: UInt64) {
      // check template existance
      if !MelonToken.melonTokenTypeSet.containsKey(typeID) {
        panic("template for typeID does not exist.")
      }
      // check if token template is expired
      if MelonToken.tokenExpiredPerType.containsKey(typeID) {
        panic("token of this typeID is no longer being offered.")
      }
      // check serial number existence, initialize it if serial number does not exist
      let targetTokenMetaData = MelonToken.melonTokenTypeSet[typeID]!
      if !MelonToken.tokenMintedPerType.containsKey(typeID) {
        MelonToken.tokenMintedPerType[typeID] = (0 as UInt64)
      }
      let serialNumber = MelonToken.tokenMintedPerType[typeID]! + (1 as UInt64)
      // emit Minted event
      emit Minted(id: MelonToken.totalSupply, typeID: typeID, serialNumber: serialNumber, metaData: targetTokenMetaData.metaData)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create MelonToken.NFT(
        initID: MelonToken.totalSupply,
        initTypeID: typeID,
        initSerialNumber: serialNumber
        )
      )

      MelonToken.totalSupply = MelonToken.totalSupply + (1 as UInt64)
      // expire token when mintLimit is hit
      if serialNumber >= targetTokenMetaData.mintLimit {
        MelonToken.tokenExpiredPerType[typeID] = true
      }
      // increse the serial number for the minted token type
      MelonToken.tokenMintedPerType[typeID] = serialNumber
		}

    // mintNFT: createTemplate: creates a template for token of typeID
    pub fun createTemplate(typeID: UInt64, tokenName: String, mintLimit: UInt64, metaData: {String: String}): UInt64 {
      // check if template with the same id exists
      if MelonToken.melonTokenTypeSet.containsKey(typeID) {
        panic("Token with the same typeID already exists.")
      }
      // create a new MelonTokenMetaData resource for the typeID
      var newNFTTemplate = MelonTokenMetaData(initTypeID: typeID, initTokenName: tokenName, initMintLimit: mintLimit, initMetaData: metaData)
      // store it in the melonTokenTypeSet mapping field
      MelonToken.melonTokenTypeSet[newNFTTemplate.typeID] = newNFTTemplate
      return newNFTTemplate.typeID
    }
	}

  // -----------------------------------------------------------------------
  // MelonToken contract-level function definitions
  // -----------------------------------------------------------------------
  // fetch
  // Get a reference to a MelonToken from an account's Collection, if available.
  // If an account does not have a MelonToken.Collection, panic.
  // If it has a collection but does not contain the itemID, return nil.
  // If it has a collection and that collection contains the itemID, return a reference to that.
  //
  pub fun fetch(_ from: Address, itemID: UInt64): &MelonToken.NFT? {
    let collection = getAccount(from)
      .getCapability(MelonToken.CollectionPublicPath)!
      .borrow<&MelonToken.Collection{MelonToken.CollectionPublic}>()
      ?? panic("Couldn't get collection")
    // We trust MelonToken.Collection.borrowMelonToken to get the correct itemID
    // (it checks it before returning it).
    return collection.borrowMelonToken(id: itemID)
  }

  pub fun peekTokenLimit(typeID: UInt64): UInt64? {
    if let token = MelonToken.melonTokenTypeSet[typeID] {
      return token.mintLimit
    } else {
      return nil
    }
  }

  pub fun checkTokenExpiration(typeID: UInt64): Bool {
    if MelonToken.tokenExpiredPerType.containsKey(typeID) {
      return true
    }
    return false
  }

  pub fun checkTemplate(typeID: UInt64): Bool {
    if MelonToken.melonTokenTypeSet.containsKey(typeID) {
      return true
    }
    return false
  }

  // -----------------------------------------------------------------------
  // MelonToken Contract Initializer
  // -----------------------------------------------------------------------
  init() {
    // Set our named paths
    self.CollectionStoragePath = /storage/MelonTokenCollection
    self.CollectionPublicPath = /public/MelonTokenCollection
    self.MinterStoragePath = /storage/MelonTokenMinter

    // Initialize the total supply
    self.totalSupply = 0

    // Initialize the type mappings
    self.melonTokenTypeSet = {}
    self.tokenExpiredPerType = {}
    self.tokenMintedPerType = {}

    // TODO consider: should we check for existing storage? https://github.com/versus-flow/versus-contracts/blob/master/transactions/buy/bid.cdc#L29
    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    self.account.save(<-minter, to: self.MinterStoragePath)
    emit ContractInitialized()
	}
}