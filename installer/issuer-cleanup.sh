#!/bin/bash
set -Ceu

# postgresql削除
sudo docker stop postgres
rm -rf ~/postgresql_data