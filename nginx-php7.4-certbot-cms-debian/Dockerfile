FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NGINX_VERSION=1.30.7
ENV HEADERS_MORE_VERSION=v0.37
ENV DOMAIN=""
ENV EMAIL=""

# 1. Зависимости для сборки Nginx, Certbot, Cron, envsubst и утилиты
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    libpcre2-dev \
    libssl-dev \
    zlib1g-dev \
    certbot \
    cron \
    gettext-base \
    supervisor \
    && rm -rf /var/lib/apt/lists/*

# 2. Скачиваем Nginx 1.30.7 и модуль headers-more, компилируем с системным OpenSSL 3.5
RUN curl -fsSL https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
    && curl -fsSL https://github.com/openresty/headers-more-nginx-module/archive/refs/tags/${HEADERS_MORE_VERSION}.tar.gz -o headers-more.tar.gz \
    && tar -zxf nginx.tar.gz \
    && tar -zxf headers-more.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/run/nginx.lock \
        --user=www-data \
        --group=www-data \
        --with-http_ssl_module \
        --with-http_v2_module \
        --with-http_realip_module \
        --with-http_sub_module \
        --with-http_addition_module \
        --with-http_stub_status_module \
        --with-http_gzip_static_module \
        --with-http_secure_link_module \
        --with-pcre \
        --with-pcre-jit \
        --add-module=/headers-more-nginx-module-0.37 \
    && make -j$(nproc) \
    && make install \
    && cd .. \
    && rm -rf nginx-${NGINX_VERSION} nginx.tar.gz headers-more-nginx-module-0.37 headers-more.tar.gz \
    && mkdir -p /etc/nginx/conf.d /etc/nginx/templates /var/www/certbot /var/log/nginx

# 3. Удаляем пакеты компиляции
RUN apt-get purge -y --auto-remove build-essential libpcre2-dev libssl-dev zlib1g-dev

# 4. Подключаем репозиторий Sury и ставим PHP 7.4 со всеми модулями для WordPress и Drupal
RUN SURY_HOST="packages.sury.org" \
    && SURY_BASE="https://${SURY_HOST}/php" \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL "${SURY_BASE}/apt.gpg" -o /etc/apt/keyrings/deb.sury.org-php.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/deb.sury.org-php.gpg] ${SURY_BASE}/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list \
    && apt-get update && apt-get install -y --no-install-recommends \
        php7.4-fpm \
        php7.4-cli \
        php7.4-common \
        php7.4-mysql \
        php7.4-pgsql \
        php7.4-sqlite3 \
        php7.4-gd \
        php7.4-imagick \
        php7.4-mbstring \
        php7.4-xml \
        php7.4-curl \
        php7.4-zip \
        php7.4-intl \
        php7.4-bcmath \
        php7.4-soap \
        php7.4-opcache \
        php7.4-apcu \
        php7.4-redis \
        php7.4-memcached \
    && rm -rf /var/lib/apt/lists/*

# 5. Перенаправляем логи Nginx в stdout/stderr
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# 6. Настраиваем PHP-FPM: порт 9000, лимиты CMS и вывод всех ошибок в stderr
RUN mkdir -p /run/php /var/www/html /var/log/supervisor \
    && chown -R www-data:www-data /var/www/html /var/www/certbot \
    && sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php/7.4/fpm/pool.d/www.conf \
    && sed -i 's|^error_log = .*|error_log = /proc/self/fd/2|' /etc/php/7.4/fpm/php-fpm.conf \
    && { \
        echo "catch_workers_output = yes"; \
        echo "decorate_workers_output = no"; \
        echo "php_admin_flag[log_errors] = on"; \
        echo "php_admin_value[error_log] = /proc/self/fd/2"; \
    } >> /etc/php/7.4/fpm/pool.d/www.conf \
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
    } > /etc/php/7.4/fpm/conf.d/99-cms.ini

# 7. Добавляем задачу автопродления сертификатов в cron (в 03:00)
RUN echo "0 3 * * * root /usr/bin/certbot renew --webroot -w /var/www/certbot --deploy-hook '/usr/sbin/nginx -s reload' --quiet" > /etc/cron.d/certbot-renew \
    && chmod 0644 /etc/cron.d/certbot-renew

COPY nginx-main.conf /etc/nginx/nginx.conf
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
COPY certbot-init.sh /certbot-init.sh

RUN sed -i 's/\r$//' /entrypoint.sh /certbot-init.sh \
    && chmod +x /entrypoint.sh /certbot-init.sh

WORKDIR /var/www/html
EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
