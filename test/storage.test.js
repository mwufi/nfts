// This test will test the storage usage/cost for core-minter

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
  // start a new emulator on port 8081 at the start of this test
  // Note:
  // - the port has to be different from the ports used in other unit tests that involves Flow emulator
  //  - to avoid conflicts
  init(flowConfigs.basePath, flowConfigs.storageTestPort)
  await emulator.start(flowConfigs.storageTestPort, false)
})

afterAll(async () => {
  await emulator.stop()
})

// -----------------------------------------------------------------------
// Test token limit of a single account storage
// -----------------------------------------------------------------------
// Note: the emulator has storage limit of 10,000, however this is not applicable on testnet and mainnet
// https://docs.onflow.org/concepts/storage/
describe("Flow Storage Test", () => {
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
      const mintLimit = 299
      const metadata = [
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
          [metadata, Dictionary({key: String, value: String})],
        ],
        signers: [flowConfigs.Minter]
      })
    } catch (error) {
      throw error
    }
  })

  test("Prep: Transaction - Setup Mintee Collection", async () => {
    const Mintee = await getAccountAddress("Mintee")
    const txTemplate = await getTransactionCode({
      name: flowConfigs.transactions.setupAccount,
      addressMap: flowConfigs.minterAddressMap,
    })
    try {
      const txResult = await sendTransaction({ 
        code: txTemplate,
        args: [],
        signers: [Mintee]
      })
    } catch(error) {
      throw error
    }
  })

  test("Test: Transactions - Mint Tokens to Mintee", async () => {
    // expand timeout limit for testing mint transactions
    jest.setTimeout(30000)
    const Mintee = await getAccountAddress("Mintee")
    // mint storage cost simulation
    const mintTokenTxTemplate = await getTransactionCode({
      name: flowConfigs.transactions.mintKlktnNFT,
      addressMap: flowConfigs.minterAddressMap,
    })
    // mint 30 tokens of typeID === 1 to the Mintee account
    for (const _ of Array(30).keys()) {
      try {
        const mintTokenTxResult = await sendTransaction({ 
          code: mintTokenTxTemplate,
          args: [
            [Mintee, Address],
            [1, UInt64],
          ],
          signers: [flowConfigs.Minter]
        })
        await logStorage(Mintee, `mint token`)
      } catch(error) {
        throw error
      }
    }
    // log overall test result
    console.log(`(Mintee Account) Average Mint Cost Per Contract is ${Math.round(avgMintStorageCost, 2)} from ${numberOfTransactions} transactions.`)
  })
})