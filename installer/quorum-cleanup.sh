#!/bin/bash
set -Ceu

# docker stop
sudo docker ps -a --filter "name=quorum" | awk 'BEGIN{i=0}{i++;}END{if(i>=2)system("sudo docker stop quorum")}'

# ディレクトリ削除
rm -rf quorum/qdata