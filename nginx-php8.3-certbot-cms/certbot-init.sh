#!/bin/sh
set -e

sleep 3

if [ "$DOMAIN" = "_" ] || [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "[certbot-init] DOMAIN или EMAIL не заданы, автоматический выпуск SSL пропущен."
    exit 0
fi

FIRST_DOMAIN=$(echo "$DOMAIN" | awk '{print $1}')

if [ -d "/etc/letsencrypt/live/$FIRST_DOMAIN" ]; then
    echo "[certbot-init] Сертификат для $FIRST_DOMAIN уже существует."
    exit 0
fi

DOMAIN_ARGS=$(echo "$DOMAIN" | sed 's/ / -d /g')

echo "[certbot-init] Запускаем первичный выпуск сертификата для: $DOMAIN..."
certbot --nginx \
    --non-interactive \
    --agree-tos \
    --redirect \
    --email "$EMAIL" \
    -d $DOMAIN_ARGS
