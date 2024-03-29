#!/usr/bin/env bash

set -ex

NETWORK_STRING=$1

PATH_TO_SCRIPT=$(realpath "$0")
PATH_TO_SCRIPTS_DIRECTORY=$(dirname "$PATH_TO_SCRIPT")
PATH_TO_PROJECT_ROOT=$(dirname "$PATH_TO_SCRIPTS_DIRECTORY")
PATH_TO_CONFIGS="${PATH_TO_PROJECT_ROOT}/dash-network-configs"
INVENTORY=${PATH_TO_CONFIGS}/${NETWORK_STRING}.inventory
CONFIG=${PATH_TO_CONFIGS}/${NETWORK_STRING}.yml

DAPI_SEED=$(awk -F '[= ]' '/^hp-masternode/ {print $5}' "$INVENTORY" | awk NF | shuf -n1)

echo "Running against node ${DAPI_SEED}"

FAUCET_ADDRESS=$(yq .faucet_address "$CONFIG")
FAUCET_PRIVATE_KEY=$(yq .faucet_privkey "$CONFIG")
DPNS_OWNER_PRIVATE_KEY=$(yq .dpns_hd_private_key "$CONFIG")
DASHPAY_OWNER_PRIVATE_KEY=$(yq .dashpay_hd_private_key "$CONFIG")
FEATURE_FLAGS_OWNER_PRIVATE_KEY=$(yq .feature_flags_hd_private_key "$CONFIG")

ST_EXECUTION_INTERVAL=$(yq .smoke_test_st_execution_interval "$CONFIG")

MASTERNODE_NAME=$(grep "$DAPI_SEED" "$INVENTORY" | awk '{print $1;}')

MASTERNODE_REWARD_SHARES_OWNER_PRO_REG_TX_HASH=$(grep "$DAPI_SEED" "$INVENTORY" | awk -F "=" '{print $6;}')
MASTERNODE_REWARD_SHARES_OWNER_PRIVATE_KEY=$(yq .mn_reward_shares_hd_private_key "$CONFIG")
MASTERNODE_REWARD_SHARES_MN_OWNER_PRIVATE_KEY=$(yq .masternodes."$MASTERNODE_NAME".owner.private_key "$CONFIG")

if [[ "$NETWORK_STRING" == "devnet"* ]]; then
  NETWORK=devnet
  INSIGHT_URL="http://insight.${NETWORK_STRING#devnet-}.networks.dash.org:3001/insight-api/sync"
else
  NETWORK=testnet
  INSIGHT_URL="http://insight.testnet.networks.dash.org:3001/insight-api/sync"
fi
SKIP_SYNC_BEFORE_HEIGHT=$(curl -s $INSIGHT_URL | jq '.height - 200')

# check variables are not empty
if [ -z "$FAUCET_ADDRESS" ] || \
    [ -z "$FAUCET_PRIVATE_KEY" ] || \
    [ -z "$DPNS_OWNER_PRIVATE_KEY" ] || \
    [ -z "$FEATURE_FLAGS_OWNER_PRIVATE_KEY" ] || \
    [ -z "$DASHPAY_OWNER_PRIVATE_KEY" ] || \
    [ -z "$MASTERNODE_REWARD_SHARES_OWNER_PRO_REG_TX_HASH" ] || \
    [ -z "$MASTERNODE_REWARD_SHARES_OWNER_PRIVATE_KEY" ] || \
    [ -z "$MASTERNODE_REWARD_SHARES_MN_OWNER_PRIVATE_KEY" ] || \
    [ -z "$NETWORK" ] || \
    [ -z "$SKIP_SYNC_BEFORE_HEIGHT" ] || \
    [ -z "$ST_EXECUTION_INTERVAL" ]
then
  echo "Internal error. Some of the env variables are empty. Please check logs above."
  exit 1
fi

echo "DAPI_SEED=${DAPI_SEED}:1443:self-signed
FAUCET_ADDRESS=${FAUCET_ADDRESS}
FAUCET_PRIVATE_KEY=${FAUCET_PRIVATE_KEY}
DPNS_OWNER_PRIVATE_KEY=${DPNS_OWNER_PRIVATE_KEY}
FEATURE_FLAGS_OWNER_PRIVATE_KEY=${FEATURE_FLAGS_OWNER_PRIVATE_KEY}
DASHPAY_OWNER_PRIVATE_KEY=${DASHPAY_OWNER_PRIVATE_KEY}
MASTERNODE_REWARD_SHARES_OWNER_PRO_REG_TX_HASH=${MASTERNODE_REWARD_SHARES_OWNER_PRO_REG_TX_HASH}
MASTERNODE_REWARD_SHARES_OWNER_PRIVATE_KEY=${MASTERNODE_REWARD_SHARES_OWNER_PRIVATE_KEY}
MASTERNODE_REWARD_SHARES_MN_OWNER_PRIVATE_KEY=${MASTERNODE_REWARD_SHARES_MN_OWNER_PRIVATE_KEY}
NETWORK=${NETWORK}
SKIP_SYNC_BEFORE_HEIGHT=${SKIP_SYNC_BEFORE_HEIGHT}
ST_EXECUTION_INTERVAL=${ST_EXECUTION_INTERVAL}" > "${PATH_TO_PROJECT_ROOT}/.env"
