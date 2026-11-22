#!/bin/sh
set -e

sleep 3

if [ "$DOMAIN" = "_" ] || [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "[certbot-init] DOMAIN или EMAIL не заданы, автоматический выпуск SSL пропущен."
    exit 0
fi

FIRST_DOMAIN=$(echo "$DOMAIN" | awk '{print $1}')
CONF_FILE="/etc/nginx/conf.d/default.conf"

if [ ! -d "/etc/letsencrypt/live/$FIRST_DOMAIN" ]; then
    DOMAIN_ARGS=$(echo "$DOMAIN" | sed 's/ / -d /g')
    echo "[certbot-init] Запускаем первичный выпуск сертификата для: $DOMAIN..."
    certbot certonly --webroot \
        -w /var/www/certbot \
        --non-interactive \
        --agree-tos \
        --email "$EMAIL" \
        -d $DOMAIN_ARGS
fi

# Добавляем HTTPS-блок и редирект в default.conf с правилами для WordPress и Drupal
if [ -d "/etc/letsencrypt/live/$FIRST_DOMAIN" ] && ! grep -q "ssl_certificate" "$CONF_FILE"; then
    cat <<EOF > "$CONF_FILE"
server {
    listen 80;
    server_name ${DOMAIN};

    location ^~ /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};
    root /var/www/html;
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/${FIRST_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${FIRST_DOMAIN}/privkey.pem;

    location ~ /\.(?!well-known).* {
        deny all;
    }

    location ~* /(?:uploads|files)/.*\.php\$ {
        deny all;
    }

    location ~* \.(engine|inc|install|make|module|profile|po|sh|.*sql|theme|twig|tpl(\.php)?|xtmpl|yml)(~|\.sw[op]|\.bak|\.orig|\.save)?\$ {
        deny all;
    }

    location ~ ^/sites/.*/files/styles/ {
        try_files \$uri @rewrite;
    }

    location / {
        try_files \$uri \$uri/ @rewrite;
    }

    location @rewrite {
        rewrite ^ /index.php?\$query_string last;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_read_timeout 300;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff|woff2|ttf|eot)\$ {
        expires max;
        log_not_found off;
        access_log off;
        try_files \$uri @rewrite;
    }
}
EOF
    /usr/sbin/nginx -s reload
    echo "[certbot-init] HTTPS успешно активирован для $DOMAIN."
fi
