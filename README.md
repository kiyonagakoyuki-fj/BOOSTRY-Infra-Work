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

## 1.2 docker-composeインストール (現時点で未使用のため、実施しなくていい)
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.19.0/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose -v
```

## 1.3 tmr-dockerリポジトリのクローン
```
git clone https://github.com/N-Village/tmr-docker
```

## 1.4 quorumインストール
### 1.4.1 docker image作成
```
cd tmr-docker/quorum
docker build -t quorum .
```

### 1.4.2 quorum設定・起動
ノード稼動環境のIPアドレスに合わせて、「tmconf/tmA～D.conf」、「static-nodes.json」のIPアドレスを修正する。
修正後、下記コマンドを実行。引数はノードA~Dで変更する。
```
./quorum-init.sh A

# 稼動確認
docker exec -it quorum geth attach qdata/dd/geth.ipc
```

# 2. 【発行体 & APPノード】PostgreSQL
## 2.1 PostgreSQLコンテナ起動
```
cd /home/ubuntu/
mkdir postgresql_data
docker run -d --name postgres -p 5432:5432 -v ~/postgresql_data:/var/lib/postgresql/data postgres:9.6
```
## 2.2 DB作成

```
# DB接続
docker run -it --rm --link postgres:postgres postgres:9.6 psql -h postgres -U postgres

# role, db作成
postgres=# CREATE ROLE apluser LOGIN CREATEDB PASSWORD 'apluserpass';
postgres=# CREATE DATABASE apldb OWNER apluser;
postgres=# \l
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 apldb     | apluser  | UTF8     | en_US.utf8 | en_US.utf8 |
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(4 rows)
```


## 2.1 nginxコンテナ



