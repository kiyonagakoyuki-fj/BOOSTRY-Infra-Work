#!/bin/bash
set -Ceu

# quorum docker imageの作成
cd quorum
pwd=`pwd`
sudo docker build -t quorum .

# datadir作成
mkdir -p qdata/{logs,keys}
mkdir -p qdata/dd/geth
mkdir -p qdata/dd/keystore

# Generate the node's Enode and key
enode=`sudo docker run --rm -d -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode -genkey /qdata/dd/nodekey -writeaddress`

echo $enode
# 設定copy
# cp istanbul-genesis.json qdata/genesis.json
# cp static-nodes.json qdata/dd/static-nodes.json
# cp static-nodes.json qdata/dd/permissioned-nodes.json
# cp start-node.sh qdata/start-node.sh

