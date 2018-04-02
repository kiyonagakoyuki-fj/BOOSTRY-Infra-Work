#!/bin/bash
set -Ceu
pwd=`pwd`

# quorum docker imageの作成
cd quorum
sudo docker build -t quorum .

# datadir作成
mkdir -p qdata/{logs,keys}
mkdir -p qdata/dd/geth
mkdir -p qdata/dd/keystore

# enode id 取得
enode=`docker run --rm -d --name quorum -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode --datadir=/qdata -writeaddress`

echo $enode
# 設定copy
# cp istanbul-genesis.json qdata/genesis.json
# cp static-nodes.json qdata/dd/static-nodes.json
# cp static-nodes.json qdata/dd/permissioned-nodes.json
# cp start-node.sh qdata/start-node.sh

