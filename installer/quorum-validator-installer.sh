#!/bin/bash
set -Ceu

# quorum docker imageの作成
cd quorum
sudo docker build -t quorum .


# 初期設定
mkdir -p qdata/{logs,keys}
mkdir -p qdata/dd/geth
mkdir -p qdata/dd/keystore
cp istanbul-genesis.json qdata/genesis.json

pwd=`pwd`
STATIC_NODES=$(cat static-nodes.json)
CURRENT_HOST_IP="10.0.0.0"

# Initializing quorum

sudo docker run --rm -v $pwd/qdata:/qdata quorum /usr/local/bin/geth --datadir /qdata/dd init /qdata/genesis.json

# Generate the node's Enode and key
sudo docker run --rm -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode -genkey /qdata/dd/nodekey
enode=`sudo docker run --rm -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode -nodekey /qdata/dd/nodekey -writeaddress`
ENODE=",
    \"$enode://${enode}@${CURRENT_HOST_IP}:21000?discport=0\"
]"
STATIC_NODES=${STATIC_NODES::-2}
STATIC_NODES="$STATIC_NODES$ENODE"
sudo echo "$STATIC_NODES" > qdata/dd/static-nodes.json


#enode://${enode}@${CURRENT_HOST_IP}:21000?discport=0"

# 設定copy
# cp istanbul-genesis.json qdata/genesis.json
# cp static-nodes.json qdata/dd/static-nodes.json
# cp static-nodes.json qdata/dd/permissioned-nodes.json
# cp start-node.sh qdata/start-node.sh

