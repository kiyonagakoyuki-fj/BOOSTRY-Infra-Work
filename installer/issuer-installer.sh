#!/bin/bash
set -Ceu

pwd=`pwd`

if ( [ `sudo docker ps -a --filter "name=postgres" | wc -l` -ne 2  ] ); then
  # postgresqlコンテナ作成
  mkdir -p ~/postgresql_data
  sudo docker run --rm -d --name postgres -p 5432:5432 -v ~/postgresql_data:/var/lib/postgresql/data postgres:9.6

  # 5秒待つ
  sleep 5

  # DB作成
  sudo docker run --rm --link postgres:postgres -v $pwd/installer:/installer postgres:9.6 psql -f /installer/createdb.sql -h postgres -U postgres 
fi

# issuerコンテナ作成
rm -rf issuer/tmr-issuer
rm -rf issuer/pyenv
rm -rf issuer/pyethereum
git clone https://github.com/N-Village/tmr-issuer.git issuer/tmr-issuer
git clone https://github.com/pyenv/pyenv.git issuer/pyenv
git clone https://github.com/ethereum/pyethereum/ issuer/pyethereum
rm issuer/pyethereum/.python-version

# docker build
sudo docker build -t issuer issuer/.

# migrate
sudo docker run --rm --link postgres:postgres --link quorum:quorum \
                    -e DEV_DATABASE_URL=postgresql://apluser:apluserpass@postgres:5432/apldb \
                    -e WEB3_HTTP_PROVIDER=http://quorum:8545  -v $pwd/installer:/installer issuer /installer/issuer-migrate.sh

# 起動
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
