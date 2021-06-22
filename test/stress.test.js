// stress test if any of the function breaks when we mint 2000 tokens

import { Address, UInt64, String, Dictionary } from "@onflow/types"
import {
  init,
  emulator,
  getAccountAddress,
  deployContractByName,
  getTransactionCode,
  sendTransaction,
  getScriptCode,
  executeScript,
} from "flow-js-testing"
import { expect } from "chai"
import { getFlowConfigs } from "./config"

const flowConfigs = getFlowConfigs()

// Account storage variables
var storageUsedLastTransaction = 0
let storageUsed
let storageAvailable
var numberOfTransactions = 0
var totalMintStorageCost = 0
var avgMintStorageCost = 0


beforeAll(async () => {
  // initializes framework variables and specifies port to use for HTTP and grpc access.
  // start a new emulator on port 8080 at the start of this test
  init(flowConfigs.basePath, flowConfigs.stressTestPort)
  await emulator.start(flowConfigs.stressTestPort, false)
})

afterAll(async () => {
  await emulator.stop()
})

// -----------------------------------------------------------------------
// Test Large Number token mint action of a single account storage (minter)
// -----------------------------------------------------------------------
describe("Flow Stress Test", () => {
  // function that checks account storage
  const logStorage = async (account, action) => {
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.checkAccountStorage,
      addressMap: {},
    })
    try {
      const scriptResult = await executeScript({
        code: scriptTemplate,
        args: [[account, Address]]
      })
      storageUsedLastTransaction = scriptResult.storageUsed - storageUsed || 0
      storageUsed = scriptResult.storageUsed || 0
      console.log(`This ${action} transaction used ${storageUsedLastTransaction} storage, there is ${scriptResult.storageAvailable} available.`)
      // update minter counters
      if (action === 'mint token') {
        numberOfTransactions += 1
        totalMintStorageCost += storageUsedLastTransaction
        avgMintStorageCost = totalMintStorageCost / numberOfTransactions
      }
    } catch (error) {
      throw error
    }
  }

  test("Prep: Setup Mintee Account", async () => {
    // Flow emulator bug: need to setup account for the default Minter account to exist
    const Mintee = await getAccountAddress("Mintee")
    console.log("Mintee account was created with following addresses:\n", {
      Mintee,
    })
  })

  test("Prep: KlktnNFT Contract Deployment", async () => {
    // Note: there might be a bug with the Flow emulator
    // - account '0xf8d6e0586b0a20c7' will not be created
    // - until the Mintee account (above) is created after we start the emulator
    // deploy contract to Minter
    // deploy NonFungibleToken Contract
    try {
      await deployContractByName({
        to: flowConfigs.Minter,
        name: flowConfigs.nonFungibleTokenContractName,
      })
    } catch (error) {
      throw error
    }
    // deploy KlktnNFT Contract
    try {
      await deployContractByName({
        addressMap: flowConfigs.minterAddressMap,
        to: flowConfigs.Minter,
        name: flowConfigs.contractName,
      })
    } catch (error) {
      throw error
    }
  })

  test("Prep: Transaction - Create NFT Template", async () => {
    // create mintee account
    const Mintee = await getAccountAddress("Mintee")
    // create template
    // TODO: stress test template storage cost (now it's in range 1000-1100)
    const createTokenTemplateTxTemplate = await getTransactionCode({
      name: flowConfigs.transactions.createTokenTemplate,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const typeID = 1
      const tokenName = 'Kevin Number 1'
      const mintLimit = 2000
      const metaData = [
        {key: 'artist', value: 'Kevin Woo'},
        {key: 'releaseYear', value: '2021'},
        {key: 'uri', value: 'ipfs://QmTv2Tx9XQeLrvg8rs9LCCih6FrHt2mXs3LVBt23ZD7eE7'},
      ]
      await sendTransaction({ 
        code: createTokenTemplateTxTemplate,
        args: [
          [typeID, UInt64],
          [tokenName, String],
          [mintLimit, UInt64],
          [metaData, Dictionary({key: String, value: String})],
        ],
        signers: [flowConfigs.Minter]
      })
    } catch (error) {
      throw error
    }
  })

  test("Prep: Transaction - Setup Minter Collection", async () => {
    const txTemplate = await getTransactionCode({
      name: flowConfigs.transactions.setupAccount,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args: [],
        signers: [flowConfigs.Minter]
      })
    } catch(error) {
      throw error
    }
  })

  test("Stress Test: Transactions - Mint Tokens to Minter Collection", async () => {
    // Note: Only the Minter Account has unlimited storage
    // expand timeout limit for testing mint transactions
    jest.setTimeout(3000000)
    // mint storage cost simulation
    const mintTokenTxTemplate = await getTransactionCode({
      name: flowConfigs.transactions.mintKlktnNFT,
      addressMap: flowConfigs.minterAddressMap,
    })
    // mint specified tokens of typeID === 1 to the Mintee account
    for (const _ of Array(flowConfigs.stressTokenNumber).keys()) {
      try {
        const mintTokenTxResult = await sendTransaction({ 
          code: mintTokenTxTemplate,
          args: [
            [flowConfigs.Minter, Address],
            [1, UInt64],
          ],
          signers: [flowConfigs.Minter]
        })
        await logStorage(flowConfigs.Minter, `mint token`)
      } catch(error) {
        throw error
      }
    }
    // log overall test result
    console.log(`(Overall) Average Mint Cost Per Contract is ${Math.round(avgMintStorageCost, 2)} from ${numberOfTransactions} transactions.`)
  })

  test("Stress Test: check collection length script", async () => {
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.checkCollectionLength,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const scriptResult = await executeScript({
        code: scriptTemplate,
        args: [[flowConfigs.Minter, Address]]
      })
      expect(scriptResult).to.equal(flowConfigs.stressTokenNumber)
    } catch (error) {
      throw error
    }
  })

  test("Stress Test: check collection ids script", async () => {
    const scriptTemplate = await getScriptCode({
      name: flowConfigs.scripts.listCollectionIds,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const scriptResult = await executeScript({
        code: scriptTemplate,
        args: [[flowConfigs.Minter, Address]]
      })
      expect(scriptResult.length).to.equal(flowConfigs.stressTokenNumber)
    } catch (error) {
      throw error
    }
  })

})