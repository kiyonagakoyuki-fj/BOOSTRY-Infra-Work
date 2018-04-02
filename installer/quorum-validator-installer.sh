#!/bin/bash
set -Ceu

# quorum docker imageの作成
cd quorum
sudo docker build -t quorum .


# 初期
pwd=`pwd`
mkdir -p qdata/{logs,keys}
mkdir -p qdata/dd/geth
mkdir -p qdata/dd/keystore

# Initializing quorum
cp istanbul-genesis.json qdata/genesis.json
sudo docker run --rm -d -v $pwd/qdata:/qdata quorum /usr/local/bin/geth --datadir /qdata/dd init /qdata/genesis.json

# Generate the node's Enode and key
sudo docker run --rm -d -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode -genkey /qdata/dd/nodekey
enode=`sudo docker run --rm -d -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode -nodekey /qdata/dd/nodekey -writeaddress`

echo $enode
# 設定copy
# cp istanbul-genesis.json qdata/genesis.json
# cp static-nodes.json qdata/dd/static-nodes.json
# cp static-nodes.json qdata/dd/permissioned-nodes.json
# cp start-node.sh qdata/start-node.sh

