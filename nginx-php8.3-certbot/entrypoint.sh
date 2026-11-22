#!/bin/sh
set -e

CONF_FILE="/etc/nginx/http.d/default.conf"
TEMPLATE_FILE="/etc/nginx/templates/default.conf.template"

# Убираем лишние пробелы по краям, если переменная передана
TRIMMED_DOMAIN=$(echo "${DOMAIN}" | xargs)

# Если имя домена не передано — принимаем любые домены (_)
if [ -z "$TRIMMED_DOMAIN" ]; then
    export DOMAIN="_"
else
    export DOMAIN="$TRIMMED_DOMAIN"
fi

# Генерируем конфиг из шаблона, если файла еще нет или в нем нет SSL-блока от Certbot
if [ ! -f "$CONF_FILE" ] || ! grep -q "managed by Certbot" "$CONF_FILE"; then
    envsubst '${DOMAIN}' < "$TEMPLATE_FILE" > "$CONF_FILE"
fi

exec "$@"
