#!/bin/bash
set -Ceu

# 引数チェック
MESSAGE='Usage: quorum-remove-node.sh <enode id> <coinbase> <NODE_TYPE>
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

# static-nodes.jsonからノードを削除
del_flg=0
i=1
count=`cat static-nodes.json | wc -l`
count=$((count - 2))
STATIC_NODES=""
while read line
do
  line_str=`echo $line`
  if echo $line | grep $ENODE_ID > /dev/null
  then
    del_flg=1
    echo "delete: "$ENODE_ID
  else
    if [ $del_flg = 0 -a $i = $count ]; then
       line=`echo $line | sed -e 's#,##g'`
    fi
    STATIC_NODES=$STATIC_NODES$line\\n
  fi
  i=$((i + 1))
done < static-nodes.json

sudo -e echo "$STATIC_NODES" >|static-nodes.json
sudo cp static-nodes.json qdata/dd/static-nodes.json
sudo cp static-nodes.json qdata/dd/permissioned-nodes.json

# istanbul.propose;
if [[ "$NODE_TYPE" == "validator" ]]; then
  sudo docker run --rm -v $pwd/qdata:/qdata quorum geth attach qdata/dd/geth.ipc --exec "istanbul.propose('$COINBASE', false)"
fi

# 結果出力
echo "quorumノードの削除完了"