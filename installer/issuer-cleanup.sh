#!/bin/bash
set -Ceu

# postgresql削除
sudo docker ps -a --filter "name=postgres" | awk 'BEGIN{i=0}{i++;}END{if(i>=2)system("sudo docker stop postgres")}'
sudo rm -rf ~/postgresql_data

# issuerコンテナ削除
sudo docker ps -a --filter "name=issuer" | awk 'BEGIN{i=0}{i++;}END{if(i>=2)system("sudo docker stop issuer")}'
rm -rf issuer/tmr-issuer
rm -rf issuer/pyenv
rm -rf issuer/pyethereum