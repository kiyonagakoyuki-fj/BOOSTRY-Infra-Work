#!/bin/bash
set -Ceu

# postgresqlコンテナ作成
mkdir -p ~/postgresql_data
sudo docker run --rm -d --name postgres -p 5432:5432 -v ~/postgresql_data:/var/lib/postgresql/data postgres:9.6

# 5秒待つ
sleep 5

# DB作成
sudo docker run --rm --link postgres:postgres -v $pwd/installer:/installer postgres:9.6 psql -f /installer/createdb.sql -h postgres -U postgres 

# issuerコンテナ作成
git clone https://github.com/N-Village/tmr-issuer.git issuer/tmr-issuer
git clone https://github.com/pyenv/pyenv.git issuer/pyenv
git clone https://github.com/ethereum/pyethereum/ issuer/pyethereum
rm issuer/pyethereum/.python-version

# docker build
docker build -t issuer issuer/.
