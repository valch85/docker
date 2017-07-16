#!/usr/bin/env sh

#for i in $(grep -h _log /etc/nginx/sites-enabled/* | awk {'print $2'} |grep '^/var/log' |  sed 's/;//g'); do
#    if [ $(echo $i | grep error) ]; then
#        ln -sf /dev/stderr $i
#    else
#        ln -sf /dev/stdout $i
#    fi
#done

#exec nginx-debug "$@"
exec nginx
