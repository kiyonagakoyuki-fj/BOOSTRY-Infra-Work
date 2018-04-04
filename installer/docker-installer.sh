#!/bin/bash
set -Ceu

# 必要パッケージのインストール
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# GPG鍵の取得
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# dockerのソースリストの更新
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# docker-engineのインストール
sudo apt-get update
sudo apt-get install -y docker-ce

# dockerグループにubuntuユーザを追加する
sudo usermod -aG docker $USER

echo "docker-ce install 完了"
echo "ubuntuユーザでdockerコマンドを利用する場合は再ログインが必要"