#!/bin/bash
set -Ceu

# 引数チェック
MESSAGE='Usage: quorum-add-node.sh <enode id> <coinbase> <NODE_TYPE>
                NODE_TYPE: validator, general'
if ( [ $# -ne 3 ] ); then
    echo "$MESSAGE"
    exit
fi

# 初期設定
cd quorum
pwd=`pwd`
ENODE_ID="$1"
COINBASE="$2"
NODE_TYPE="$3"
STATIC_NODES=$(cat static-nodes.json)

# static-nodes.jsonの作成
ENODE_STR=",
\"$ENODE_ID\"
]"
STATIC_NODES=${STATIC_NODES::-2}
STATIC_NODES="$STATIC_NODES$ENODE_STR"
sudo echo "$STATIC_NODES" >|static-nodes.json
sudo cp static-nodes.json qdata/dd/static-nodes.json
sudo cp static-nodes.json qdata/dd/permissioned-nodes.json

# istanbul.propose;
if [[ "$NODE_TYPE" == "validator" ]]; then
sudo docker run --rm -v $pwd/qdata:/qdata quorum geth attach qdata/dd/geth.ipc <<END
istanbul.propose("$COINBASE", true)
exit
END
fi

# 結果出力
echo "quorumノードの追加完了"