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


# gethdirの初期化
sudo rm -rf qdata

# 
node_label="$1"
pwd=`pwd`

echo $node_label
echo $pwd