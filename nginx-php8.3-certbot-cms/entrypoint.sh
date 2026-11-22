#!/bin/sh
set -e

CONF_FILE="/etc/nginx/http.d/default.conf"
TEMPLATE_FILE="/etc/nginx/templates/default.conf.template"

TRIMMED_DOMAIN=$(echo "${DOMAIN}" | xargs)

if [ -z "$TRIMMED_DOMAIN" ]; then
    export DOMAIN="_"
else
    export DOMAIN="$TRIMMED_DOMAIN"
fi

if [ ! -f "$CONF_FILE" ] || ! grep -q "managed by Certbot" "$CONF_FILE"; then
    envsubst '${DOMAIN}' < "$TEMPLATE_FILE" > "$CONF_FILE"
fi

exec "$@"
