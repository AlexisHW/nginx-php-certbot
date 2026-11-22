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

# Добавляем HTTPS-блок и редирект в default.conf, если они еще не прописаны
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

    location ~ /\. {
        deny all;
    }

    location / {
        try_files \$uri \$uri/ =404;
    }

    location ~ \.php\$ {
        try_files \$uri =404;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
    /usr/sbin/nginx -s reload
    echo "[certbot-init] HTTPS успешно активирован для $DOMAIN."
fi
