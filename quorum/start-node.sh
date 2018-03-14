#!/bin/bash

#
# This is used at Container start up to run the constellation and geth nodes
#

set -u
set -e

### Configuration Options
TMCONF=/qdata/tm.conf


echo "[*] Starting Constellation node"
nohup /usr/local/bin/constellation-node $TMCONF 2>> /qdata/logs/constellation.log &

sleep 10

echo "[*] Starting node"
GLOBAL_ARGS="--datadir /qdata/dd --rpc --rpcaddr 0.0.0.0 --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul --permissioned  --rpcport 22002 --port 21002"
PRIVATE_CONFIG=$TMCONF /usr/local/bin/geth $GLOBAL_ARGS 

