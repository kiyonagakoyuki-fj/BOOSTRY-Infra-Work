FROM nginx

ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./app.conf /etc/nginx/conf.d/app.conf
ADD ./index.html /etc/nginx/html/index.html
ADD ./auth.htpasswd /etc/nginx/auth.htpasswd
ADD ./start.sh /start.sh

RUN chmod 755 -R /var

EXPOSE 80
CMD ["/start.sh"]
