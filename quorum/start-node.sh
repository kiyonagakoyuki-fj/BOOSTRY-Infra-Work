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
GLOBAL_ARGS='--syncmode full --mine --rpc --rpcaddr 0.0.0.0 --rpccorsdomain "*" --rpcapi admin,db,eth,debug,miner,net,shh,txpool,personal,web3,quorum,istanbul'
PRIVATE_CONFIG=$TMCONF /usr/local/bin/geth --datadir /qdata/dd $GLOBAL_ARGS --permissioned --rpcport 8545 --port 21000 2>> /qdata/logs/geth.log
