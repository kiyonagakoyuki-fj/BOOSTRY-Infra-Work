# tmr-docker
## 1. 【全ノード共通】環境構築（Ubuntu 16.04の場合）
### 1.1. docker-ceインストール
* 下記を参考。
* https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-using-the-repository

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

* dockerグループにubuntuユーザを追加する

```
sudo usermod -aG docker $USER
su - $USER
```
※passwordがない環境の場合は、再度ログイン。

### 1.2. docker-composeインストール (現時点で未使用のため、実施しなくていい)
```
sudo curl -L "https://github.com/docker/compose/releases/download/1.19.0/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose -v
```

### 1.3. tmr-dockerリポジトリのクローン
```
git clone https://github.com/N-Village/tmr-docker.git
```

### 1.4. quorumコンテナ作成
#### 1.4.1. docker image作成
```
cd tmr-docker/quorum
docker build -t quorum .
```

#### 1.4.2. istanbul用ノードの設定
* 初期ノードの設定を新規で行う場合は、istanbul-toolsを入れてノード生成処理を実施する。
* ソース：https://github.com/getamis/istanbul-tools
* ※Goが必要

```
cd /home/ubuntu/gowork/src/github.com/getamis/istanbul-tools
./build/bin/istanbul setup --num 4 --nodes --verbose --quorum
```

* 「static-nodes.json」「nodekeyA～D」「istanbul-genesis.json」を修正。

#### 1.4.3. quorum設定・起動
* ノード稼動環境のIPアドレスに合わせて、「tmconf/tmA～D.conf」、「static-nodes.json」のIPアドレスを修正する。
* 修正後、下記コマンドを実行。引数はノードA~Dで変更する。

```
./quorum-init.sh A
./quorum-start.sh

# 稼動確認
tail -f qdata/logs/geth.log
```

#### 1.4.4. account作成・・・A(発行体ノード)、C・D（サトシナカモトノード）で実施
* 以下のスクリプトを実行する。

```
./quorum-create-account.sh
```

* 実行結果として、アカウントが出力されるので、控えておく。


#### 1.4.5. コントラクトの登録
* サトシナカモトノードをアンロックし、Remix等からコントラクトを登録する。
* アカウントのアンロックは以下のようにして行う。

```
# gethにattach
docker exec -it quorum geth attach qdata/dd/geth.ipc

# アンロック
personal.unlockAccount(eth.accounts[0], "nvillage201803+", 1000)

# 登録後のコントラクト確認
eth.contract(<contract_address>)
```


## 2. 【ISSUERノード & APIノードで実施】DB（PostgreSQL）構築
### 2.1. PostgreSQLコンテナ起動
```
cd /home/ubuntu/
mkdir postgresql_data
docker run -d --name postgres -p 5432:5432 -v ~/postgresql_data:/var/lib/postgresql/data postgres:9.6
```

### 2.2. DB作成
* 以下の手順でDBを作成する。

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

## 3. 【ISSUERノードのみで実施】その他の環境構築
### 3.1. issuerコンテナ
#### 3.1.1. docker image作成
```
cd /home/ubuntu/tmr-docker/issuer

# 必要なソースを取得
git clone https://github.com/N-Village/tmr-issuer.git
git clone https://github.com/pyenv/pyenv.git
git clone https://github.com/ethereum/pyethereum/
rm pyethereum/.python-version

# docker build
docker build -t issuer .
```

#### 3.1.2. DBのマイグレート
```
# issuerコンテナに接続
docker run -it --rm --link postgres:postgres  --link quorum:quorum \
                    -e DEV_DATABASE_URL=postgresql://apluser:apluserpass@postgres:5432/apldb \
                    -e WEB3_HTTP_PROVIDER=http://quorum:8545  issuer bash

# ↓をコンテナ内で実施
source ~/.bash_profile
cd /app/tmr-issuer
python manage.py db init
python manage.py db migrate
python manage.py db upgrade
python manage.py shell

# shellで実施
roles = ['admin', 'user',]
for r in roles:
    role = Role.query.filter_by(name=r).first()
    if role is None:
        role = Role(name=r)
    db.session.add(role)

users = [
     {'login_id': 'admin', 'user_name': '管理者', 'role_id': 1, 'password': 'admin'},
]

for u_dict in users:
    user = User.query.filter_by(login_id=u_dict['login_id']).first()
    if user is None:
        user = User()
        for key, value in u_dict.items():
            setattr(user, key, value)
        db.session.add(user)

db.session.commit()
```

#### 3.1.3. issuerコンテナ起動
* ホストマシン上にRSA鍵（`/home/ubuntu/tmr-docker/issuer/data/rsa/private.pem`）を作成して保存する。

```
docker run -it --rm -d --name issuer --link postgres:postgres \
                                     --link quorum:quorum \
                                     -e FLASK_CONFIG=production \
                                     -e DATABASE_URL=postgresql://apluser:apluserpass@postgres:5432/apldb \
                                     -e WEB3_HTTP_PROVIDER=http://quorum:8545 \
                                     -e ETH_ACCOUNT_PASSWORD=nvillage201803+ \
                                     -e TOKEN_LIST_CONTRACT_ADDRESS=<contractアドレス> \
                                     -e PERSONAL_INFO_CONTRACT_ADDRESS=<contractアドレス> \
                                     -e WHITE_LIST_CONTRACT_ADDRESS=<contractアドレス> \
                                     -e IBET_SB_EXCHANGE_CONTRACT_ADDRESS=<contractアドレス> \
                                     -e AGENT_ADDRESS=<決済業者のアドレス> \
                                     -e RSA_PASSWORD=password \
                                     -p 5000:5000 \
                                     -v /home/ubuntu/tmr-docker/issuer/data:/app/tmr-issuer/data \
                                     issuer
```

* 直近のPOC用環境は以下の設定で起動している。

```
docker run -it --rm -d --name issuer --link postgres:postgres \
                                     --link quorum:quorum \
                                     -e FLASK_CONFIG=production \
                                     -e DATABASE_URL=postgresql://apluser:apluserpass@postgres:5432/apldb \
                                     -e WEB3_HTTP_PROVIDER=http://quorum:8545 \
                                     -e ETH_ACCOUNT_PASSWORD=nvillage201803+ \
                                     -e TOKEN_LIST_CONTRACT_ADDRESS=0x492bb01ff36ecb6848f7a0c214886d172706431a \
                                     -e PERSONAL_INFO_CONTRACT_ADDRESS=0x358442a720a96987d25b9d7e07ec57a7d301a276 \
                                     -e WHITE_LIST_CONTRACT_ADDRESS=0x8337fa10730b22f3cffa6b9ec53bc7f098041e25 \
                                     -e IBET_SB_EXCHANGE_CONTRACT_ADDRESS=0x5daad7f8a070cbaf8a1c15f5964f64196b1cf907 \
                                     -e AGENT_ADDRESS=0x9982f688af88ee715015dc3d351d8cdc23024ff4 \
                                     -e RSA_PASSWORD=password \
                                     -p 5000:5000 \
                                     -v /home/ubuntu/tmr-docker/issuer/data:/app/tmr-issuer/data \
                                     issuer
```
### 3.2 nginxコンテナ
※TODO

### 3.3 issuerコンテナ更新手順
```
# ソース更新
cd /home/ubuntu/tmr-docker/issuer/tmr-issuer
git pull origin master

# コンテナ停止
docker stop issuer

# docker image削除
docker rmi issuer
```

* 上記を実施後に、docker build & docker run


## 4. 【APIノードのみで実施】その他の環境構築
### 4.1. APIコンテナ
#### 4.1.1. docker image作成
```
cd /home/ubuntu/tmr-docker/api

# 必要なソースを取得
git clone https://github.com/N-Village/tmr-node.git
git clone https://github.com/pyenv/pyenv.git
git clone https://github.com/ethereum/pyethereum/
rm pyethereum/.python-version

# docker build
docker build -t api .
```

#### 4.1.2 APIコンテナ起動
```
docker run -it --rm -d --name api --link postgres:postgres \
                                     --link quorum:quorum \
                                     -e APP_ENV=live \
                                     -e TOKEN_LIST_CONTRACT_ADDRESS=<contractアドレス> \
                                     -e PERSONAL_INFO_CONTRACT_ADDRESS=<contractアドレス> \
                                     -e IBET_SB_EXCHANGE_CONTRACT_ADDRESS=<contractアドレス> \
                                     -e WHITE_LIST_CONTRACT_ADDRESS=<contractアドレス> \
                                     -p 5000:5000 api
```

* 直近のPOC用環境は以下の設定で起動している。

```
docker run -it --rm -d --name api --link postgres:postgres \
                                     --link quorum:quorum \
                                     -e APP_ENV=live \
                                     -e TOKEN_LIST_CONTRACT_ADDRESS=0x492bb01ff36ecb6848f7a0c214886d172706431a \
                                     -e PERSONAL_INFO_CONTRACT_ADDRESS=0x358442a720a96987d25b9d7e07ec57a7d301a276 \
                                     -e IBET_SB_EXCHANGE_CONTRACT_ADDRESS=0x5daad7f8a070cbaf8a1c15f5964f64196b1cf907 \
                                     -e WHITE_LIST_CONTRACT_ADDRESS=0x8337fa10730b22f3cffa6b9ec53bc7f098041e25 \
                                     -p 5000:5000 api
```

### 4.2. nginxコンテナ
#### 4.2.1. docker image作成
```
cd /home/ubuntu/tmr-docker/nginx

# docker build
docker build -t nginx .
```

#### 4.2.2. nginxコンテナ起動
```
docker run -itd --rm --name nginx --link api:api -p 443:443 nginx
```
* ※basic認証あり。apluser/nvillage201803+

### 4.3. APIコンテナ更新手順
```
# ソース更新
cd /home/ubuntu/tmr-docker/api/tmr-node
git pull origin master

# コンテナ停止
docker stop api

# docker image削除
docker rmi api
```

* 上記後、docker build & docker run

## 5. 【BANKノードのみで実施】その他の環境構築
### 5.1. BANKコンテナ
#### 5.1.1. docker image作成

```
cd /home/ubuntu/tmr-docker/bank

# 必要なソースを取得
git clone https://github.com/N-Village/tmr-bank.git
git clone https://github.com/pyenv/pyenv.git

# docker build
docker build -t bank .
```

#### 5.1.2. BANKコンテナ起動
* BANKノードはコンテナに直接ログインする。詳細は`tmr-bank`リポジトリのREADMEを参照。

```
docker run -it --rm —name bank —link quorum:quorum \
              -e WEB3_HTTP_PROVIDER=http://quorum:8545 \
              -e WHITE_LIST_CONTRACT_ADDRESS=<contractアドレス> \
              -e AGENT_ADDRESS= <決済業者のアドレス> \
              bank bash
```

* 直近のPOC用環境は以下の設定で起動している。

```
docker run -it --rm —name bank —link quorum:quorum \
              -e WEB3_HTTP_PROVIDER=http://quorum:8545 \
              -e WHITE_LIST_CONTRACT_ADDRESS=0x8337fa10730b22f3cffa6b9ec53bc7f098041e25 \
              -e AGENT_ADDRESS= 0x9982f688af88ee715015dc3d351d8cdc23024ff4 \
              bank bash
```
