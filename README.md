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

## 1.4 quorumコンテナ
### 1.4.1 docker image作成
```
cd tmr-docker/quorum
docker build -t quorum .
```

### 1.4.2 istanbul用ノードの設定
初期ノードの設定を新規で行う場合は、istanbul-toolsを入れてノード生成処理を実施する。
ソース：https://github.com/getamis/istanbul-tools
※Goが必要
```
cd /home/ubuntu/gowork/src/github.com/getamis/istanbul-tools
./build/bin/istanbul setup --num 4 --nodes --verbose --quorum
```
「static-nodes.json」「nodekeyA～D」「istanbul-genesis.json」を修正。


### 1.4.3 quorum設定・起動
ノード稼動環境のIPアドレスに合わせて、「tmconf/tmA～D.conf」、「static-nodes.json」のIPアドレスを修正する。
修正後、下記コマンドを実行。引数はノードA~Dで変更する。
```
./quorum-init.sh A
./quorum-start.sh

# 稼動確認
tail -f qdata/logs/geth.log
```

### 1.4.4 account作成・・・A(発行体ノード)、C・D（サトシナカモトノード）で実施
```
./quorum-create-account.sh
```
出力されたアカウントを控える



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

# 3. 【発行体】アプリインストール
## 3.1 issuerコンテナ
### 3.1.1 docker image作成
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

### 3.1.2 quorum, postgresqlのIPアドレス取得
```
docker inspect quorum | grep IPAddress
docker inspect postgres | grep IPAddress
```

### 3.1.3 migrate
```
# issuerコンテナに接続
docker run -it --rm -e DEV_DATABASE_URL=postgresql://apluser:apluserpass@<PostgreSQLコンテナのIP>:5432/apldb -e WEB3_HTTP_PROVIDER=http://<quorumコンテナのIP>:8545  issuer bash

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
### 3.1.4 コンテナ起動
```
docker run -it --rm -d --name issuer -e DEV_DATABASE_URL=postgresql://apluser:apluserpass@<PostgreSQLコンテナのIP>:5432/apldb \
                                     -e WEB3_HTTP_PROVIDER=http://<quorumコンテナのIP>:8545 \
                                     -e ETH_ACCOUNT_PASSWORD=nvillage201803+ \
                                     -p 5000:5000 issuer


```



## 2.1 nginxコンテナ



