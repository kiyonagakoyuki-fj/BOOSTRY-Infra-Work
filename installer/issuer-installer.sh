#!/bin/bash
set -Ceu

# postgresqlコンテナ作成
mkdir ~/postgresql_data
sudo docker run --rm -d --name postgres -p 5432:5432 -v ~/postgresql_data:/var/lib/postgresql/data postgres:9.6

# DB作成
sudo docker run --rm --link postgres:postgres postgres:9.6 psql -h postgres -U postgres <<END
CREATE ROLE apluser LOGIN CREATEDB PASSWORD 'apluserpass';
CREATE DATABASE apldb OWNER apluser;
\l
\q
END