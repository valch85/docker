FROM nginx:1.10.3-alpine

RUN adduser -u 49 -s /sbin/nologin -H -D www

RUN rm /etc/nginx/conf.d/default.conf
COPY /config/blog /etc/nginx/sites-enabled/blog
RUN mkdir -p /etc/nginx/ssl
RUN mkdir -p /var/www/blog
COPY /config/logformat.cnf /etc/nginx/conf.d/logformat.cnf
COPY /config/nginx.conf /etc/nginx/nginx.conf
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh

RUN apk add wget ca-certificates --update-cache

CMD nginx