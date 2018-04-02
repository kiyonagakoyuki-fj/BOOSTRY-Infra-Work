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
cp generate-keys.sh qdata/generate-keys.sh

pwd=`pwd`
STATIC_NODES=$(cat static-nodes.json)
TM_CONF=$(cat tm_base.conf)
CURRENT_HOST_IP="10.0.0.0"

# Initializing quorum
sudo docker run --rm -v $pwd/qdata:/qdata quorum /usr/local/bin/geth --datadir /qdata/dd init /qdata/genesis.json

# Generate the node's Enode and key
sudo docker run --rm -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode -genkey /qdata/dd/nodekey
enode=`sudo docker run --rm -v $pwd/qdata:/qdata quorum /usr/local/bin/bootnode -nodekey /qdata/dd/nodekey -writeaddress`

# static-nodes.jsonの作成
ENODE_ID="enode://${enode}@${CURRENT_HOST_IP}:21000?discport=0"
ENODE_STR=",
\"$ENODE_ID\"
]"
STATIC_NODES=${STATIC_NODES::-2}
STATIC_NODES="$STATIC_NODES$ENODE_STR"
sudo echo "$STATIC_NODES" > qdata/dd/static-nodes.json

# permissioned-nodes.json
cp qdata/dd/static-nodes.json qdata/dd/permissioned-nodes.json

# constellation-node generatekeys
sudo docker run --rm -v $pwd/qdata:/qdata quorum /qdata/generate-keys.sh

# tm.confの作成
TM_CONF_URL="
url = \"http://${CURRENT_HOST_IP}:9000/\"
"
TM_CONF="$TM_CONF$TM_CONF_URL"
sudo echo "$TM_CONF" > qdata/tm.conf

# geth 起動
sudo docker run --rm -d --name quorum -v $pwd/qdata:/qdata -p 9000:9000 -p 21000:21000 -p 21000:21000/udp -p 8545:8545 quorum

echo "quorum(validator)ノードの起動完了"
echo $ENODE_ID