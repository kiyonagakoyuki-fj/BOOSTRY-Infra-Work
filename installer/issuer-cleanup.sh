#!/bin/bash
set -Ceu

# postgresql削除
sudo docker stop postgres
sudo rm -rf ~/postgresql_data