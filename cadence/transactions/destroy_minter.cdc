import MelonToken from "../contracts/MelonToken.cdc"

// flow transactions send ./cadence/transactions/destroy_minter.cdc --network testnet --signer testnet-minter

// This transaction removes the minter from Minter storage

transaction {
  prepare(signer: AuthAccount) {
    let minterResource <- signer.load<@MelonToken.NFTMinter>(from: MelonToken.MinterStoragePath)
    destroy minterResource
  }
}