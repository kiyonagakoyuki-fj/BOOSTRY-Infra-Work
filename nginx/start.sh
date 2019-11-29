#!/bin/sh
sed -i -e "s/TARGET_HOST/$TARGET_HOST/g" /etc/nginx/conf.d/app.conf
nginx -g "daemon off;"
