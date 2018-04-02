#!/bin/bash
set -Ceu

# docker stop
sudo docker stop quorum

# ディレクトリ削除
rm -rf quorum/qdata