!/bin/bash
docker exec -i `docker ps | grep start.sh | cut -d' ' -f1`  nginx -s reload