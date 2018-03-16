# tmr-docker
# 1. 【全ノード共通】環境構築（Ubuntu 16.04）
## 1.1 docker-ceインストール
### 1.1.1 インストール
下記を参考。
https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository

```
# 必要パッケージのインストール
sudo apt-get update
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common

# GPG鍵の取得
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# dockerのソースリストの更新
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# docker-engineのインストール
sudo apt-get update
sudo apt-get install docker-ce
```

### 1.1.2 dockerグループにubuntuユーザを追加
```
sudo usermod -aG docker $USER
su - $USER
```
※passwordがない環境の場合は、再度ログイン。

## 1.2 docker-composeインストール
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.19.0/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose -v
```

## 1.3 tmr-dockerリポジトリのクローン
```
git clone https://github.com/N-Village/tmr-docker
```



# 2. 【発行体ノード】環境構築（Ubuntu 16.04）

## 2.1 nginxコンテナ



