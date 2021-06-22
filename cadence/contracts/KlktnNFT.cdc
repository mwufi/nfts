import NonFungibleToken from "./NonFungibleToken.cdc"

pub contract KlktnNFT: NonFungibleToken {

  // -----------------------------------------------------------------------
  // KlktnNFT Contract Events
  // -----------------------------------------------------------------------

  // Emitted when KlktnNFT contract is created
  pub event ContractInitialized()
  // Emitted when Collection events are created
  pub event Withdraw(id: UInt64, from: Address?)
  pub event Deposit(id: UInt64, to: Address?)
  pub event Minted(id: UInt64, typeID: UInt64, serialNumber: UInt64, metaData: {String: String})
  // Emitted when nft template is created
  pub event NFTTemplateCreated(typeID: UInt64, tokenName: String, mintLimit: UInt64, metaData: {String: String})
  
  // -----------------------------------------------------------------------
  // KlktnNFT Contract Named Paths
  // -----------------------------------------------------------------------
  pub let CollectionStoragePath: StoragePath
  pub let CollectionPublicPath: PublicPath
  pub let MinterStoragePath: StoragePath

  // -----------------------------------------------------------------------
  // KlktnNFT Contract Properties
  // -----------------------------------------------------------------------
  // The total number of KlktnNFTs that have been minted
  pub var totalSupply: UInt64
  // The hashtable for metaData and administrative parameters per typeID
  pub var klktnNFTTypeSet: {UInt64: KlktnNFTMetaData}
  // Dictionary to track expired token templates
  pub var tokenExpiredPerType: {UInt64: Bool}
  // Dictionary to track minted tokens
  pub var tokenMintedPerType: {UInt64: UInt64}

  // -----------------------------------------------------------------------
  // KlktnNFT Contract Resource Interfaces
  // -----------------------------------------------------------------------

  // This is the interface that users can cast their KlktnNFT Collection as
  // to allow others to deposit KlktnNFT into their Collection. It also allows for reading
  // the details of KlktnNFT in the Collection.
  pub resource interface KlktnNFTCollectionPublic {
    pub fun deposit(token: @NonFungibleToken.NFT)
    pub fun getIDs(): [UInt64]
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
    pub fun borrowKlktnNFT(id: UInt64): &KlktnNFT.NFT? {
      // If the result isn't nil, the id of the returned reference
      // should be the same as the argument to the function
      post {
        (result == nil) || (result?.id == id):
          "Cannot borrow KlktnNFT reference: The ID of the returned reference is incorrect"
      }
    }
  }

  // -----------------------------------------------------------------------
  // KlktnNFT Structs
  // -----------------------------------------------------------------------
  // KlktnNFTMetaData: metadata and admin properties of each typeID
  pub struct KlktnNFTMetaData {
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
  // KlktnNFT Resources
  // -----------------------------------------------------------------------
  pub resource NFT: NonFungibleToken.INFT {
    // the unique id for the NFT
    pub let id: UInt64
    // the token's type, e.g. 1 == Heart
    pub let typeID: UInt64
    // the serial number of token, this is uniquely auto-increment per typeID
    pub let serialNumber: UInt64
    // metaData of the NFT
    pub let metaData: {String: String}

    init(initID: UInt64, initTypeID: UInt64, initSerialNumber: UInt64) {
      self.id = initID
      self.typeID = initTypeID
      self.serialNumber = initSerialNumber
      self.metaData = KlktnNFT.klktnNFTTypeSet[initTypeID]!.metaData
    }
  }

  // A collection of KlktnNFT NFTs owned by an account
  pub resource Collection: KlktnNFTCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
    pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

    // withdraw: Removes an NFT from the collection and moves it to the caller
    pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
      let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")
      emit Withdraw(id: token.id, from: self.owner?.address)
      return <-token
    }

    // deposit: Takes a NFT and adds it to the collections dictionary
    // and adds the ID to the id array
    pub fun deposit(token: @NonFungibleToken.NFT) {
      let token <- token as! @KlktnNFT.NFT
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
    pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
      return &self.ownedNFTs[id] as &NonFungibleToken.NFT
    }

    // Gets a reference to an NFT in the collection as a KlktnNFT,
    // exposing all of its fields (including the typeID).
    // This is safe as there are no functions that can be called on the KlktnNFT.
    //
    pub fun borrowKlktnNFT(id: UInt64): &KlktnNFT.NFT? {
      if self.ownedNFTs[id] != nil {
        let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
        return ref as! &KlktnNFT.NFT
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
  pub fun createEmptyCollection(): @NonFungibleToken.Collection {
    return <- create Collection()
  }

  pub resource NFTMinter {

		// mintNFT: Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
		pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64) {
      // check template existance
      if !KlktnNFT.klktnNFTTypeSet.containsKey(typeID) {
        panic("template for typeID does not exist.")
      }
      // check if token template is expired
      if KlktnNFT.tokenExpiredPerType.containsKey(typeID) {
        panic("token of this typeID is no longer being offered.")
      }
      // check serial number existence, initialize it if serial number does not exist
      let targetTokenMetaData = KlktnNFT.klktnNFTTypeSet[typeID]!
      if !KlktnNFT.tokenMintedPerType.containsKey(typeID) {
        KlktnNFT.tokenMintedPerType[typeID] = (0 as UInt64)
      }
      let serialNumber = KlktnNFT.tokenMintedPerType[typeID]! + (1 as UInt64)
      // emit Minted event
      emit Minted(id: KlktnNFT.totalSupply, typeID: typeID, serialNumber: serialNumber, metaData: targetTokenMetaData.metaData)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create KlktnNFT.NFT(
        initID: KlktnNFT.totalSupply,
        initTypeID: typeID,
        initSerialNumber: serialNumber
        )
      )

      KlktnNFT.totalSupply = KlktnNFT.totalSupply + (1 as UInt64)
      // expire token when mintLimit is hit
      if serialNumber >= targetTokenMetaData.mintLimit {
        KlktnNFT.tokenExpiredPerType[typeID] = true
      }
      // increse the serial number for the minted token type
      KlktnNFT.tokenMintedPerType[typeID] = serialNumber
		}

    // mintNFT: createTemplate: creates a template for token of typeID
    pub fun createTemplate(typeID: UInt64, tokenName: String, mintLimit: UInt64, metaData: {String: String}): UInt64 {
      // check if template with the same id exists
      if KlktnNFT.klktnNFTTypeSet.containsKey(typeID) {
        panic("Token with the same typeID already exists.")
      }
      // create a new KlktnNFTMetaData resource for the typeID
      var newNFTTemplate = KlktnNFTMetaData(initTypeID: typeID, initTokenName: tokenName, initMintLimit: mintLimit, initMetaData: metaData)
      // store it in the klktnNFTTypeSet mapping field
      KlktnNFT.klktnNFTTypeSet[newNFTTemplate.typeID] = newNFTTemplate
      return newNFTTemplate.typeID
    }
	}

  // -----------------------------------------------------------------------
  // KlktnNFT contract-level function definitions
  // -----------------------------------------------------------------------
  // fetch
  // Get a reference to a KlktnNFT from an account's Collection, if available.
  // If an account does not have a KlktnNFT.Collection, panic.
  // If it has a collection but does not contain the itemID, return nil.
  // If it has a collection and that collection contains the itemID, return a reference to that.
  //
  pub fun fetch(_ from: Address, itemID: UInt64): &KlktnNFT.NFT? {
    let collection = getAccount(from)
      .getCapability(KlktnNFT.CollectionPublicPath)
      .borrow<&KlktnNFT.Collection{KlktnNFT.KlktnNFTCollectionPublic}>()
      ?? panic("Couldn't get collection")
    // We trust KlktnNFT.Collection.borrowKlktnNFT to get the correct itemID
    // (it checks it before returning it).
    return collection.borrowKlktnNFT(id: itemID)
  }

  pub fun peekTokenLimit(typeID: UInt64): UInt64? {
    if let token = KlktnNFT.klktnNFTTypeSet[typeID] {
      return token.mintLimit
    } else {
      return nil
    }
  }

  pub fun checkTokenExpiration(typeID: UInt64): Bool {
    if KlktnNFT.tokenExpiredPerType.containsKey(typeID) {
      return true
    }
    return false
  }

  pub fun checkTemplate(typeID: UInt64): Bool {
    if KlktnNFT.klktnNFTTypeSet.containsKey(typeID) {
      return true
    }
    return false
  }

  // -----------------------------------------------------------------------
  // KlktnNFT Contract Initializer
  // -----------------------------------------------------------------------
  init() {
    // Set our named paths
    self.CollectionStoragePath = /storage/KlktnNFTCollection
    self.CollectionPublicPath = /public/KlktnNFTCollection
    self.MinterStoragePath = /storage/KlktnNFTMinter

    // Initialize the total supply
    self.totalSupply = 0

    // Initialize the type mappings
    self.klktnNFTTypeSet = {}
    self.tokenExpiredPerType = {}
    self.tokenMintedPerType = {}

    // TODO consider: should we check for existing storage? https://github.com/versus-flow/versus-contracts/blob/master/transactions/buy/bid.cdc#L29
    // Create a Minter resource and save it to storage
    let minter <- create NFTMinter()
    self.account.save(<-minter, to: self.MinterStoragePath)
    emit ContractInitialized()
	}
}