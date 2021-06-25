// API: https://github.com/onflow/flow-js-testing/blob/master/docs/api.md
// Basic Usage: https://github.com/onflow/flow-js-testing/blob/master/docs/examples/basic.md

// This test will test the lifecycle of Cadence contract deployment, transactions,
// and scripts

import { Address, UInt64, String, Dictionary } from "@onflow/types"
import {
  init,
  emulator,
  getAccountAddress,
  deployContractByName,
  getContractAddress,
  getTransactionCode,
  sendTransaction,
  getScriptCode,
  executeScript,
} from "flow-js-testing"
import { expect } from "chai"
import { getFlowConfigs } from "./config"

const flowConfigs = getFlowConfigs()

beforeAll(async () => {
  // initializes framework variables and specifies port to use for HTTP and grpc access.
  // start a new emulator on port 8080 at the start of this test
  init(flowConfigs.basePath, flowConfigs.defaultPort)
  await emulator.start(flowConfigs.defaultPort, false)
})

afterAll(async () => {
  await emulator.stop()
})

// -----------------------------------------------------------------------
// Tests Account Creation
// -----------------------------------------------------------------------
describe("Test Account Creation", () => {
  test("Create Mintee Account", async () => {
    const Mintee = await getAccountAddress("Mintee")
    console.log("Mintee account was created with following addresses:\n", {
      Mintee,
    })
  })

  test("Create Bowser Account", async () => {
    const Bowser = await getAccountAddress("Bowser")
    console.log("Bowser account was created with following addresses:\n", {
      Bowser,
    })
  })
})

// -----------------------------------------------------------------------
// Tests Contract Deployment
// -----------------------------------------------------------------------
describe("Test KlktnNFT Deployment", () => {
  test("Deploy NonFungibleToken Contract", async () => {
    try {
      // deploy NonFungibleToken Contract
      const deploymentResult = await deployContractByName({
        to: flowConfigs.Minter,
        name: flowConfigs.nonFungibleTokenContractName,
      })
      // deployment result should have no error message
      expect(deploymentResult.errorMessage).to.equal('')
    } catch (error) {
      throw error
    }
  })

  test("Deploy KlktnNFT Contract", async () => {
    try {
      // deploy KlktnNFT Contract
      const deploymentResult = await deployContractByName({
        // Flow SDK bug: addressMap has to be put before the other props
        addressMap: flowConfigs.minterAddressMap,
        to: flowConfigs.Minter,
        name: flowConfigs.contractName,
      })
      // deployment result should have no error message
      expect(deploymentResult.errorMessage).to.equal('')
      // deployment result should have 3 emitted events
      expect(deploymentResult.events.length).to.equal(3)
    } catch (error) {
      throw error
    }
  })

  test ("Deployed Contract Address", async () => {
    // deployed contract should be in the Minter address
    const deployedContractAddress = await getContractAddress(flowConfigs.contractName)
    expect(deployedContractAddress).to.equal(flowConfigs.Minter)
  })
})

// -----------------------------------------------------------------------
// Tests on Transaction Code (Account Setup + Template Creation)
// -----------------------------------------------------------------------
describe("Test Transaction Code", () => {

  test("Setup Account for Minter & Mintee", async () => {
    const txTemplate = await getTransactionCode({
      name: flowConfigs.transactions.setupAccount,
      addressMap: flowConfigs.minterAddressMap,
    })
    // send the account setup transaction to Minter
    try {
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args: [],
        signers: [flowConfigs.Minter]
      })
      // transaction result should have no error message
      expect(txResult.errorMessage).to.equal('')
      // transaction result should have 0 emitted events
      expect(txResult.events.length).to.equal(0)
    } catch(error) {
      throw error
    }
    // send the account setup transaction to Mintee.
    const Mintee = await getAccountAddress("Mintee")
    try {
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args: [],
        signers: [Mintee]
      })
      // transaction result should have no error message
      expect(txResult.errorMessage).to.equal('')
      // transaction result should have 0 emitted events
      expect(txResult.events.length).to.equal(0)
    } catch(error) {
      throw error
    }
  })

  test("Empty Collections Setup", async () => {
    // Minter should have empty Collection
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.checkCollectionLength,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const minterScriptResult = await executeScript({
        code: scriptTemplate,
        args: [
          [flowConfigs.Minter, Address]
        ]
      })
      expect(minterScriptResult).to.equal(0)
    } catch (error) {
      throw error
    }
    // Mintee should have empty Collection
    const Mintee = await getAccountAddress("Mintee")
    try {
      const minteeScriptResult = await executeScript({
        code: scriptTemplate,
        args: [
          [Mintee, Address]
        ]
      })
      expect(minteeScriptResult).to.equal(0)
    } catch (error) {
      throw error
    }
  })

  test("Create Token Template", async () => {
    // template metaData variables
    let typeID
    let tokenName
    let mintLimit
    let metadata
    let signers
    const txTemplate = await getTransactionCode({
      name: flowConfigs.transactions.createTokenTemplate,
      addressMap: flowConfigs.minterAddressMap,
    })
    // send the transaction to create an NFT template (setup template for typeID == 1)
    try {
      typeID = 1
      tokenName = 'Kevin Number 1'
      mintLimit = 299
      metadata = [
        {key: 'artist', value: 'Donkey King'},
        {key: 'releaseYear', value: '1983'},
      ]
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args: [
          [typeID, UInt64],
          [tokenName, String],
          [mintLimit, UInt64],
          [metadata, Dictionary({key: String, value: String})],
        ],
        signers: [flowConfigs.Minter]
      })
      // should have 1 event emitted for success creation
      expect(txResult.events.length).to.equal(1)
      // event should have the same typeID
      expect(txResult.events[0].data.typeID).to.equal(typeID)
      // event should have the same tokenName
      expect(txResult.events[0].data.tokenName).to.equal(tokenName)
      // event should have the same emit limit
      expect(txResult.events[0].data.mintLimit).to.equal(mintLimit)
      // metaData should match with template input (key)
      expect(txResult.events[0].data.metadata).to.have.deep.property('artist', 'Donkey King')
      expect(txResult.events[0].data.metadata).to.have.deep.property('releaseYear', '1983')
      expect(txResult.events[0].data.metadata).to.not.have.property('uri', 'ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7')
    } catch (error) {
      throw error
    }
    // update metadata by adding uri
    const updateMetadataTxTemplate = await getTransactionCode({
      name: flowConfigs.transactions.updateMetadata,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const updateMetadataTxResult = await sendTransaction({ 
        code: updateMetadataTxTemplate,
        args: [
          [typeID, UInt64],
          [
            [
            {key: 'artist', value: 'Kevin Woo'},
            {key: 'releaseYear', value: '2021'},
            {key: 'uri', value: 'ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7'},
            {key: 'releaseCompany', value: 'KLKTN Limited'},
            ],
            Dictionary({key: String, value: String}),
          ],
        ],
        signers: [flowConfigs.Minter]
      })
      // should have 1 event emitted for success creation (update)
      expect(updateMetadataTxResult.events.length).to.equal(1)
      // event should have the same typeID as the old one
      expect(updateMetadataTxResult.events[0].data.typeID).to.equal(typeID)
      // event should have the same tokenName as the old one
      expect(updateMetadataTxResult.events[0].data.tokenName).to.equal(tokenName)
      // event should have the same emit limit as the old one
      expect(updateMetadataTxResult.events[0].data.mintLimit).to.equal(mintLimit)
      // metadata should match with new template metaData
      expect(updateMetadataTxResult.events[0].data.metadata).to.have.deep.property('artist', 'Kevin Woo')
      expect(updateMetadataTxResult.events[0].data.metadata).to.have.deep.property('releaseYear', '2021')
      expect(updateMetadataTxResult.events[0].data.metadata).to.have.deep.property('uri', 'ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7')
      expect(updateMetadataTxResult.events[0].data.metadata).to.have.deep.property('releaseCompany', 'KLKTN Limited')
    } catch (error) {
      throw error
    }
    // send the transaction to create an NFT template (setup template for typeID == 2)
    // this will have a mintLimit of 2 tokens in totoal (extremely rare, for testing only)
    try {
      typeID = 2
      tokenName = 'Kevin Number 2'
      mintLimit = 2
      metadata = [
        {key: 'artist', value: 'Kevin Woo'},
        {key: 'releaseYear', value: '2021'},
        {key: 'uri', value: 'ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7'},
      ]
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args: [
          [typeID, UInt64],
          [tokenName, String],
          [mintLimit, UInt64],
          [metadata, Dictionary({key: String, value: String})],
        ],
        signers: [flowConfigs.Minter]
      })
      // should have 1 event emitted for success creation
      expect(txResult.events.length).to.equal(1)
      // event should have the same typeID
      expect(txResult.events[0].data.typeID).to.equal(typeID)
      // event should have the same tokenName
      expect(txResult.events[0].data.tokenName).to.equal(tokenName)
      // event should have the same emit limit
      expect(txResult.events[0].data.mintLimit).to.equal(mintLimit)
      // metaData should match with template input (key)
      expect(txResult.events[0].data.metadata).to.have.deep.property('artist', 'Kevin Woo')
      expect(txResult.events[0].data.metadata).to.have.deep.property('releaseYear', '2021')
      expect(txResult.events[0].data.metadata).to.have.deep.property('uri', 'ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7')
    } catch (error) {
      throw error
    }
  })

  test("Mint Tokens to Mintee Account", async () => {
    jest.setTimeout(10000)
    const txTemplate = await getTransactionCode({
      name: flowConfigs.transactions.mintKlktnNFT,
      addressMap: flowConfigs.minterAddressMap,
    })
    // send the mint token transaction to Mintee
    const Mintee = await getAccountAddress("Mintee")
    // mint 3 tokens of typeID == 1
    for (const _ of Array(3).keys()) {
      try {
        const typeID = 1
        const txResult = await sendTransaction({ 
          code: txTemplate,
          args: [
            [Mintee, Address],
            [typeID, UInt64],
          ],
          signers: [flowConfigs.Minter]
        })
        // transaction result should have no error message
        expect(txResult.errorMessage).to.equal('')
        // transaction result should have 2 emitted events
        expect(txResult.events.length).to.equal(2)
        // event type 1 should be Minted
        expect(txResult.events[0].type).to.include('Minted')
        // event type 2 should be Deposit
        expect(txResult.events[1].type).to.include('Deposit')
      } catch(error) {
        throw error
      }
    }
    // mint 2 tokens of typeID == 2
    for (const _ of Array(2).keys()) {
      try {
        const typeID = 2
        const txResult = await sendTransaction({ 
          code: txTemplate,
          args: [
            [Mintee, Address],
            [typeID, UInt64],
          ],
          signers: [flowConfigs.Minter]
        })
        // transaction result should have no error message
        expect(txResult.errorMessage).to.equal('')
        // transaction result should have 2 emitted events
        expect(txResult.events.length).to.equal(2)
        // event type 1 should be Minted
        expect(txResult.events[0].type).to.include('Minted')
        // event type 2 should be Deposit
        expect(txResult.events[1].type).to.include('Deposit')
      } catch(error) {
        throw error
      }
    }
  })
})

// -----------------------------------------------------------------------
// Tests on Transaction Code (Minter)
// -----------------------------------------------------------------------
describe("Check Token id and SerialNumber", () => {

  test("Check Number of Minted Tokens", async () => {
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.checkCollectionLength,
      addressMap: flowConfigs.minterAddressMap,
    })
    // execute script for Mintee Collection
    const Mintee = await getAccountAddress("Mintee")
    try {
      const scriptResult = await executeScript({
        code: scriptTemplate,
        args: [
          [Mintee, Address]
        ]
      })
      // there should be 5 tokens in Mintee's Collection
      expect(scriptResult).to.equal(5)
    } catch (error) {
      throw error
    }
  })

  test("Check id, serialNumber, and metaData of Minted Tokens", async () => {
    var tokenCounter = 0
    var serialNumberCounter = {
      1: 1,
      2: 1,
    }
    var typeIDHash = {
      0: 1,
      1: 1,
      2: 1,
      3: 2,
      4: 2,
    }
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.printNFTProperties,
      addressMap: flowConfigs.minterAddressMap,
    })
    // execute script for Mintee Collection
    const Mintee = await getAccountAddress("Mintee")
    for (const tokenId of Array(5).keys()) {
      const typeID = typeIDHash[tokenId]
      try {
        const scriptResult = await executeScript({
          code: scriptTemplate,
          args: [
            [Mintee, Address],
            [tokenId, UInt64],
          ]
        })
        // typeID should be the intended typeID
        expect(scriptResult.typeID).to.equal(typeID)
        // id should equal to tokenID
        expect(scriptResult.id).to.equal(tokenCounter++)
        // serialNumber should auto-increment from 0 per typeID
        expect(scriptResult.serialNumber).to.equal(serialNumberCounter[typeID]++)
        // metadata matches with template
        expect(scriptResult.metadata).to.have.deep.property('artist', 'Kevin Woo')
        expect(scriptResult.metadata).to.have.deep.property('releaseYear', '2021')
        expect(scriptResult.metadata).to.have.deep.property('uri', 'ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7')
        if (typeID === 1) {
          expect(scriptResult.metadata).to.have.deep.property('releaseCompany', 'KLKTN Limited')
        }
      } catch (error) {
        throw error
      }
    }
  })

  test("token expires when last token minted", async () => {
    const txTemplate = await getTransactionCode({
      name: flowConfigs.transactions.mintKlktnNFT,
      addressMap: flowConfigs.minterAddressMap,
    })
    // send the mint token transaction to Mintee
    const Mintee = await getAccountAddress("Mintee")
    const mintFunction = async () => {
      try {
        const typeID = 2
        const txResult = await sendTransaction({ 
          code: txTemplate,
          args: [
            [Mintee, Address],
            [typeID, UInt64],
          ],
          signers: [flowConfigs.Minter]
        })
      } catch(error) {
        return error
      }
    }
    // the error being catched is in string format so we can check if the expected panic warning
    // exists in the returned function
    expect(await mintFunction()).to.be.a('string')
    expect(await mintFunction()).to.have.string('token of this typeID is no longer being offered.')
  })

  test("token expiration state saved in contract", async () => {
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.checkTokenExpire,
      addressMap: flowConfigs.minterAddressMap,
    })
    const typeID = 2
    try {
      const minterScriptResult = await executeScript({
        code: scriptTemplate,
        args: [
          [typeID, UInt64]
        ]
      })
      // token should have expired
      expect(minterScriptResult).to.be.true
    } catch (error) {
      throw error
    }
  })

  test("transfer to external Flow Address", async () => {
    // extending timeout transactions takes time to run
    jest.setTimeout(100000)
    const Mintee = await getAccountAddress("Mintee")
    const Bowser = await getAccountAddress("Bowser")
    const txTemplate = await getTransactionCode({
      name: flowConfigs.transactions.transferToken,
      addressMap: flowConfigs.minterAddressMap,
    })
    const transferFunction = async (tokenId) => {
      try {  
        const txResult = await sendTransaction({ 
          code: txTemplate,
          args: [
            [Bowser, Address],
            [tokenId, UInt64]
          ],
          signers: [Mintee]
        })
        return txResult
      } catch (error) {
        return error
      }
    }
    // scenario 1: recipient does not have KlktnNFT Collection setup
    expect(await transferFunction(1)).to.be.a('string')
    // TODO: add more intuitive panic error warning in transaction contract
    expect(await transferFunction(1)).to.have.string('error: unexpectedly found nil while forcing an Optional value')
    expect(await transferFunction(1)).to.have.string('.borrow<&{NonFungibleToken.CollectionPublic}>()!')
    // scenario 2: token does not exist
    // setup KlktnNFT Collection for Bowser
    const setupAccountTxTemplate = await getTransactionCode({
      name: flowConfigs.transactions.setupAccount,
      addressMap: flowConfigs.minterAddressMap,
    })
    // send the account setup transaction to Minter
    try {
      await sendTransaction({ 
        code: setupAccountTxTemplate,
        args: [],
        signers: [Bowser]
      })
    } catch(error) {
      throw error
    }
    // try to transfer an non-exist token
    expect(await transferFunction(10)).to.be.a('string')
    expect(await transferFunction(10)).to.have.string('error: panic: missing NFT')
    // scenario 3: successful transfer
    const txResult = await transferFunction(1)
    expect(txResult.errorMessage).to.equal('')
    expect(txResult.events.length).to.equal(2)
    // 2 evernts: Withdraw and Deposit should have been emitted from this transaction
    expect(txResult.events[0].type).to.include('Withdraw')
    expect(txResult.events[1].type).to.include('Deposit')
    // and token #1 should have been deposited to Bowser's Collection
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.listCollectionIds,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const scriptResult = await executeScript({
        code: scriptTemplate,
        args: [
          [Bowser, Address]
        ]
      })
      // expected KlktnNFT Collection to be [1]
      expect(Object.values(scriptResult)).to.be.an('array')
      expect(Object.values(scriptResult)).to.have.lengthOf(1)
      expect(Object.values(scriptResult)).to.include(1)
    } catch (error) {
      throw error
    }
  })
})