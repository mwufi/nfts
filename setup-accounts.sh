#!/usr/bin/env bash

# deploy MelonToken contract
flow project deploy

# create mintee account
flow accounts create --key 1475d6686bd1c2aff572fe2234a63d872f53bf1c22d4281f98ab574466d655b711b3f307616127acc5073369e55a844e25e4acfa90381ad2e1b3baa004fce05c

# create test transfer account
flow accounts create --key 4580efac3270d67a6164d761048cbe21c4957c636e2b66332653cf549d3547f474d1165a4dd5f3f8d78d038a84312d778cc9e27eea5de14b1c33c1ce3163d36e

# setup Minter Collection
# flow transactions send ./cadence/transactions/setup_account.cdc

# setup Mintee Collection
# flow transactions send ./cadence/transactions/setup_account.cdc --signer account1