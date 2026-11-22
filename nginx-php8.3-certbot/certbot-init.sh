#!/bin/sh
set -e

# Ждем запуска Nginx
sleep 3

# Если домен не задан (равен "_") или не указан EMAIL — выходим без действий
if [ "$DOMAIN" = "_" ] || [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "[certbot-init] DOMAIN или EMAIL не заданы, автоматический выпуск SSL пропущен."
    exit 0
fi
# Если скрипт вызван напрямую, и домен не указан - заменяем
sed -i 's/server_name _;/server_name $DOMAIN;/g' /etc/nginx/http.d/default.conf

# Берем первый домен из списка (имя директории сертификата в Let's Encrypt)
FIRST_DOMAIN=$(echo "$DOMAIN" | awk '{print $1}')

# Если сертификат уже существует — ничего не делаем (дальше им занимается crond)
if [ -d "/etc/letsencrypt/live/$FIRST_DOMAIN" ]; then
    echo "[certbot-init] Сертификат для $FIRST_DOMAIN уже существует."
    exit 0
fi

# Формируем флаги -d для всех указанных доменов
DOMAIN_ARGS=$(echo "$DOMAIN" | sed 's/ / -d /g')

echo "[certbot-init] Запускаем первичный выпуск сертификата для: $DOMAIN..."
certbot --nginx \
    --non-interactive \
    --agree-tos \
    --redirect \
    --email "$EMAIL" \
    -d $DOMAIN_ARGS
