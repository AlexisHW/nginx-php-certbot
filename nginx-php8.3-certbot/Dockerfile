FROM alpine:3.24

# Устанавливаем Nginx (OpenSSL 3.5), CLI openssl, Certbot с плагином Nginx, Supervisor, PHP 8.3 и envsubst
RUN apk add --no-cache \
    openssl \
    nginx \
    certbot \
    certbot-nginx \
    supervisor \
    gettext-envsubst \
    php83 \
    php83-fpm \
    php83-mbstring \
    php83-curl \
    php83-zip \
    php83-session \
    php83-openssl \
    php83-opcache \
    && ln -sf /usr/bin/php83 /usr/bin/php

# Подготовка директорий и прав
RUN mkdir -p /var/www/html /run/nginx /var/log/supervisor /etc/nginx/templates \
    && chown -R nginx:nginx /var/www/html

# Перенаправляем логи Nginx в stdout и stderr
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Настраиваем PHP-FPM: порт 9000, пользователь nginx и перенаправление всех ошибок в stderr
RUN sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's|^user = nobody|user = nginx|' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's|^group = nobody|group = nginx|' /etc/php83/php-fpm.d/www.conf \
    && sed -i 's|^;error_log = .*|error_log = /proc/self/fd/2|' /etc/php83/php-fpm.conf \
    && { \
        echo "catch_workers_output = yes"; \
        echo "decorate_workers_output = no"; \
        echo "php_admin_flag[log_errors] = on"; \
        echo "php_admin_value[error_log] = /proc/self/fd/2"; \
    } >> /etc/php83/php-fpm.d/www.conf \
    && { \
        echo "log_errors = On"; \
        echo "display_errors = Off"; \
        echo "expose_php = Off"; \
    } > /etc/php83/conf.d/99-custom.ini

# Добавляем задачу в системный crontab (запуск в 03:00 каждый день)
RUN echo "0 3 * * * /usr/bin/certbot renew --nginx --quiet" >> /etc/crontabs/root

COPY nginx-main.conf /etc/nginx/nginx.conf
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
COPY certbot-init.sh /certbot-init.sh
RUN chmod +x /certbot-init.sh

RUN chmod +x /entrypoint.sh

ENV DOMAIN=""
ENV EMAIL=""

WORKDIR /var/www/html

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
