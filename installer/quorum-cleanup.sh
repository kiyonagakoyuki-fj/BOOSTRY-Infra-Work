#!/bin/bash
set -Ceu

# docker stop
docker stop quorum

# ディレクトリ削除
rm -rf quorum/qdata