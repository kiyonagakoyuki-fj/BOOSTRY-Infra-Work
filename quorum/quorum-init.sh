#!/bin/bash
set -u
set -e

# 引数チェック
MESSAGE='Usage: quorum-init.sh <node-label>
                node-label: A ~ D'

if ( [ $# -ne 1 ] ); then
    echo "$MESSAGE"
    exit
fi

# datadirの初期化
sudo rm -rf qdata
mkdir qdata/{logs,keys}
mkdir qdata/dd/geth
mkdir qdata/dd/keystore


# 変数
node_label="$1"
pwd=`pwd`

# 設定copy
cp istanbul-genesis.json qdata/genesis.json
cp static-nodes.json qdata/dd/static-nodes.json
cp static-nodes.json qdata/dd/permissioned-nodes.json
cp tmconf/tm${node_label}.conf qdata/tm.conf

# key copy
cp keys/nodekey${node_label} qdata/dd/geth/nodekey
cp keys/key${node_label}.json qdata/dd/keystore/acckey
cp keys/tm${node_label}.key qdata/keys/tm.key
cp keys/tm${node_label}.pub qdata/keys/tm.pub

# docker run時の実行sh
cp start-node.sh qdata/start-node.sh

