// API: https://github.com/onflow/flow-js-testing/blob/master/docs/api.md
// Basic Usage: https://github.com/onflow/flow-js-testing/blob/master/docs/examples/basic.md

import path from "path"
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

const chai = require('chai')
const should = chai.should()

const basePath = path.resolve(__dirname, "../cadence")
const port = 8080
const Minter = '0xf8d6e0586b0a20c7'

// transaction and scripts file names
const contractName = "MelonToken"
const setupAccountTransactionFileName = 'setup_account'
const mintMelonTokenTransactionFileName = 'mint_melon_token'
const createTokenTemplateFileName = 'create_token_template'
const checkExpirationFileName = 'check_token_expiration'
const transferTokenFileName = 'transfer_melon_token'

beforeAll(async () => {
  // initializes framework variables and specifies port to use for HTTP and grpc access.
  // start a new emulator on port 8080 at the start of this test
  init(basePath, port)
  await emulator.start(port, false)
})

afterAll(async () => {
  await emulator.stop()
})

// -----------------------------------------------------------------------
// Tests Account Creation
// -----------------------------------------------------------------------
describe("Test Account Creation", () => {
  test("Create Minter Account", async () => {
    const Mintee = await getAccountAddress("Mintee")
    console.log("Mintee account was created with following addresses:\n", {
      Mintee,
    })
  })
})

// -----------------------------------------------------------------------
// Tests Contract Deployment
// -----------------------------------------------------------------------
describe("Test MelonToken Deployment", () => {
  test("Deploy MelonToken Contract", async () => {
    try {
      // deploy MelonToken Contract
      const deploymentResult = await deployContractByName({
        to: Minter,
        name: contractName,
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
    const deployedContractAddress = await getContractAddress(contractName)
    expect(deployedContractAddress).to.equal(Minter)
  })
})

// -----------------------------------------------------------------------
// Tests on Transaction Code (Account Setup + Template Creation)
// -----------------------------------------------------------------------
describe("Test Transaction Code", () => {

  test("Setup Account for Minter & Mintee", async () => {
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    // get transaction code template
    const txTemplate = await getTransactionCode({
      name: setupAccountTransactionFileName,
      addressMap,
    })

    // send the account setup transaction to Minter
    var signers = [Minter]
    const args = []
    try {
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args,
        signers
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
    signers = [Mintee]
    try {
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args,
        signers
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
    const readCollectionLengthScriptFileName = 'read_collection_length'
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    // get transaction code template
    const scriptTemplate = await getScriptCode({
      name: readCollectionLengthScriptFileName,
      addressMap,
    })
    // Minter should have empty Collection 
    var args = [
      [Minter, Address]
    ]
    try {
      const minterScriptResult = await executeScript({
        code: scriptTemplate,
        args
      })
      // there should be 0 tokens in Minter's Collection
      expect(minterScriptResult).to.equal(0)
    } catch (error) {
      throw error
    }
    // Mintee should have empty Collection
    const Mintee = await getAccountAddress("Mintee")
    args = [
      [Mintee, Address]
    ]
    try {
      const minteeScriptResult = await executeScript({
        code: scriptTemplate,
        args
      })
      // there should be 0 tokens in Mintee's Collection
      expect(minteeScriptResult).to.equal(0)
    } catch (error) {
      throw error
    }
  })

  test("Create Token Template", async () => {
    const MelonToken = await getContractAddress(contractName)
    const addressMap = { MelonToken }
    let typeID
    let tokenName
    let mintLimit
    let metaData
    let signers
    const txTemplate = await getTransactionCode({
      name: createTokenTemplateFileName,
      addressMap,
    })
    // send the transaction to create an NFT template (setup template for typeID == 1)
    try {
      typeID = 1
      tokenName = 'Kevin Number 1'
      mintLimit = 299
      metaData = [
        {key: 'artist', value: 'Kevin Woo'},
        {key: 'releaseYear', value: '2021'},
      ]
      signers = [Minter]
      const args = [
        [typeID, UInt64],
        [tokenName, String],
        [mintLimit, UInt64],
        [metaData, Dictionary({key: String, value: String})],
      ]

      const txResult = await sendTransaction({ 
        code: txTemplate,
        args,
        signers
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
      expect(txResult.events[0].data.metaData).to.have.deep.property('artist', 'Kevin Woo')
      expect(txResult.events[0].data.metaData).to.have.deep.property('releaseYear', '2021')
    } catch (error) {
      throw error
    }
    // send the transaction to create an NFT template (setup template for typeID == 2)
    // this will have a mintLimit of 2 tokens in totoal (extremely rare, for testing only)
    try {
      typeID = 2
      tokenName = 'Kevin Number 2'
      mintLimit = 2
      metaData = [
        {key: 'artist', value: 'Kevin Woo'},
        {key: 'releaseYear', value: '2021'},
      ]
      signers = [Minter]
      const args = [
        [typeID, UInt64],
        [tokenName, String],
        [mintLimit, UInt64],
        [metaData, Dictionary({key: String, value: String})],
      ]

      const txResult = await sendTransaction({ 
        code: txTemplate,
        args,
        signers
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
      expect(txResult.events[0].data.metaData).to.have.deep.property('artist', 'Kevin Woo')
      expect(txResult.events[0].data.metaData).to.have.deep.property('releaseYear', '2021')
    } catch (error) {
      throw error
    }
  })

  test("Mint Tokens to Mintee Account", async () => {
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    // get transaction code template
    const txTemplate = await getTransactionCode({
      name: mintMelonTokenTransactionFileName,
      addressMap,
    })
    // send the mint token transaction to Mintee
    const Mintee = await getAccountAddress("Mintee")
    const signers = [Minter]
    // mint 3 tokens of typeID == 1
    for (const _ of Array(3).keys()) {
      try {
        const typeID = 1
        const args = [
          [Mintee, Address],
          [typeID, UInt64],
        ]

        const txResult = await sendTransaction({ 
          code: txTemplate,
          args,
          signers
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
        const args = [
          [Mintee, Address],
          [typeID, UInt64],
        ]

        const txResult = await sendTransaction({ 
          code: txTemplate,
          args,
          signers
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

  const readCollectionLengthScriptFileName = 'read_collection_length'
  const printNFTPropertiesScriptFileName = 'print_nft_properties'

  test("Check Number of Minted Tokens", async () => {
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    // get the script template
    const scriptTemplate = await getScriptCode({
      name: readCollectionLengthScriptFileName,
      addressMap,
    })
    // execute script for Mintee Collection
    const Mintee = await getAccountAddress("Mintee")
    const args = [
      [Mintee, Address]
    ]
    try {
      const scriptResult = await executeScript({
        code: scriptTemplate,
        args
      })
      // there should be 5 tokens in Mintee's Collection
      expect(scriptResult).to.equal(5)
    } catch (error) {
      throw error
    }
  })

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

  test("Check id, serialNumber, and metaData of Minted Tokens", async () => {
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    // get the script template
    const scriptTemplate = await getScriptCode({
      name: printNFTPropertiesScriptFileName,
      addressMap,
    })
    // execute script for Mintee Collection
    const Mintee = await getAccountAddress("Mintee")
    for (const tokenID of Array(5).keys()) {
      const typeID = typeIDHash[tokenID]
      const args = [
        [Mintee, Address],
        [tokenID, UInt64],
      ]
      try {
        const scriptResult = await executeScript({
          code: scriptTemplate,
          args
        })
        // typeID should be the intended typeID
        expect(scriptResult.typeID).to.equal(typeID)
        // id should equal to tokenID
        expect(scriptResult.id).to.equal(tokenCounter++)
        // serialNumber should auto-increment from 0 per typeID
        expect(scriptResult.serialNumber).to.equal(serialNumberCounter[typeID]++)
        // metaData matches with template
        expect(scriptResult.metaData).to.have.deep.property('artist', 'Kevin Woo')
        expect(scriptResult.metaData).to.have.deep.property('releaseYear', '2021')
      } catch (error) {
        throw error
      }
    }
  })

  test("token expires when last token minted", async () => {
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    // get transaction code template
    const txTemplate = await getTransactionCode({
      name: mintMelonTokenTransactionFileName,
      addressMap,
    })
    // send the mint token transaction to Mintee
    const Mintee = await getAccountAddress("Mintee")
    const signers = [Minter]
    const mintFunction = async () => {
      try {
        const typeID = 2
        const args = [
          [Mintee, Address],
          [typeID, UInt64],
        ]
        const txResult = await sendTransaction({ 
          code: txTemplate,
          args,
          signers
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
    // contract should have typeID of this token in the expired dictionary
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    // get transaction code template
    const scriptTemplate = await getScriptCode({
      name: checkExpirationFileName,
      addressMap,
    })
    const typeID = 2
    var args = [
      [typeID, UInt64]
    ]
    try {
      const minterScriptResult = await executeScript({
        code: scriptTemplate,
        args
      })
      // token should have expired
      expect(minterScriptResult).to.be.true
    } catch (error) {
      throw error
    }
  })

  test("transfer to external Flow Address", async () => {
    // contract should have typeID of this token in the expired dictionary
    const MelonToken = await getContractAddress(contractName)
    // note: addressMap format must be: {contractName: contractDeployedAddress}
    const addressMap = { MelonToken }
    const txTemplate = await getTransactionCode({
      name: transferTokenFileName,
      addressMap,
    })
    let requester
    let tokenId
    let recipient
    // TODO: complete the unit test cases below
    // scenario 1: tokedId does not exist
    try {
      // requester = 1
      // tokenId = 1
      // recipient = 
      // signers = [Minter]
      // const args = [
      //   [typeID, UInt64],
      //   [tokenName, String],
      //   [mintLimit, UInt64],
      //   [metaData, Dictionary({key: String, value: String})],
      // ]

      // const txResult = await sendTransaction({ 
      //   code: txTemplate,
      //   args,
      //   signers
      // })
      // // should have 1 event emitted for success creation
      // expect(txResult.events.length).to.equal(2)
    } catch (error) {
      throw error
    }
    // scenario 2: requester does not have permission on tokenId

    // scrnario 3: recipient does not have MelonToken Collection

    // scenario 4: success transfer
  })
})