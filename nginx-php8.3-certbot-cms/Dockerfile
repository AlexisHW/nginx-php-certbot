FROM alpine:3.24

# Устанавливаем Nginx (OpenSSL 3.5), модуль headers-more, CLI openssl, Certbot, Supervisor, envsubst и полный набор PHP 8.3 для WP/Drupal
RUN apk add --no-cache \
    openssl \
    nginx \
    nginx-mod-http-headers-more \
    certbot \
    certbot-nginx \
    supervisor \
    gettext-envsubst \
    php83 \
    php83-fpm \
    php83-mysqli \
    php83-pdo_mysql \
    php83-pgsql \
    php83-pdo_pgsql \
    php83-sqlite3 \
    php83-pdo_sqlite \
    php83-gd \
    php83-pecl-imagick \
    php83-mbstring \
    php83-xml \
    php83-dom \
    php83-simplexml \
    php83-xmlreader \
    php83-xmlwriter \
    php83-curl \
    php83-zip \
    php83-intl \
    php83-bcmath \
    php83-soap \
    php83-exif \
    php83-fileinfo \
    php83-iconv \
    php83-tokenizer \
    php83-ctype \
    php83-session \
    php83-openssl \
    php83-opcache \
    php83-pecl-apcu \
    php83-pecl-redis \
    php83-pecl-memcached \
    && ln -sf /usr/bin/php83 /usr/bin/php

# Подготовка директорий и прав
RUN mkdir -p /var/www/html /run/nginx /var/log/supervisor /etc/nginx/templates \
    && chown -R nginx:nginx /var/www/html

# Перенаправляем логи Nginx в stdout и stderr контейнера
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Настраиваем PHP-FPM: порт 9000, пользователь nginx, лимиты CMS и вывод всех ошибок в stderr
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
        echo "upload_max_filesize = 128M"; \
        echo "post_max_size = 128M"; \
        echo "memory_limit = 256M"; \
        echo "max_execution_time = 300"; \
        echo "log_errors = On"; \
        echo "display_errors = Off"; \
        echo "expose_php = Off"; \
        echo "opcache.enable=1"; \
        echo "opcache.memory_consumption=128"; \
        echo "opcache.max_accelerated_files=10000"; \
        echo "opcache.revalidate_freq=2"; \
    } > /etc/php83/conf.d/99-cms.ini

# Добавляем задачу автопродления сертификатов в системный crontab (в 03:00)
RUN echo "0 3 * * * /usr/bin/certbot renew --nginx --quiet" >> /etc/crontabs/root

COPY nginx-main.conf /etc/nginx/nginx.conf
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
COPY certbot-init.sh /certbot-init.sh

# Очищаем возможные Windows-окончания строк (CRLF) и даем права на запуск
RUN sed -i 's/\r$//' /entrypoint.sh /certbot-init.sh \
    && chmod +x /entrypoint.sh /certbot-init.sh

ENV DOMAIN=""
ENV EMAIL=""

WORKDIR /var/www/html

EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
