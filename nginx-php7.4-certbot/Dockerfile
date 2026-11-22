# ==============================================================================
# ЭТАП 1: Сборка OpenSSL 1.1.1, Nginx 1.24.0 (с OpenSSL 3.5) и пропатченного PHP 7.4
# ==============================================================================
FROM alpine:3.24 AS builder

ENV NGINX_VERSION=1.24.0
ENV PHP_VERSION=7.4.33
ENV OPENSSL11_VERSION=1.1.1w

RUN apk add --no-cache \
    build-base \
    curl \
    perl \
    patch \
    linux-headers \
    autoconf \
    pcre2-dev \
    openssl-dev \
    zlib-dev \
    libxml2-dev \
    sqlite-dev \
    curl-dev \
    oniguruma-dev \
    libzip-dev \
    libsodium-dev

# 1.1 Собираем OpenSSL 1.1.1w в изолированную директорию /opt/openssl-1.1.1 (нужно только для PHP 7.4)
RUN OSSL_HOST="github.com" \
    && curl -fsSL "https://${OSSL_HOST}/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-${OPENSSL11_VERSION}.tar.gz" -o openssl11.tar.gz \
    && tar -zxf openssl11.tar.gz \
    && cd openssl-${OPENSSL11_VERSION} \
    && ./config --prefix=/opt/openssl-1.1.1 --openssldir=/opt/openssl-1.1.1 shared zlib \
    && make -j$(nproc) \
    && make install_sw \
    && cd .. && rm -rf openssl-${OPENSSL11_VERSION} openssl11.tar.gz

# 1.2 Собираем Nginx 1.24.0 с системным OpenSSL 3.5
RUN NGINX_HOST="nginx.org" \
    && curl -fsSL "https://${NGINX_HOST}/download/nginx-${NGINX_VERSION}.tar.gz" -o nginx.tar.gz \
    && tar -zxf nginx.tar.gz \
    && cd nginx-${NGINX_VERSION} \
    && ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/run/nginx.lock \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_stub_status_module \
        --with-http_gzip_static_module \
        --with-http_sub_module \
        --with-stream \
        --with-stream_ssl_module \
        --with-pcre \
        --with-pcre-jit \
    && make -j$(nproc) \
    && make install \
    && cd .. && rm -rf nginx-${NGINX_VERSION} nginx.tar.gz

# 1.3 Скачиваем PHP 7.4.33, накатываем все актуальные CVE-патчи из репозитория Sury и компилируем
RUN PHP_HOST="www.php.net" \
    && SURY_HOST="packages.sury.org" \
    && curl -fsSL "https://${PHP_HOST}/distributions/php-${PHP_VERSION}.tar.xz" -o php.tar.xz \
    && tar -xJf php.tar.xz \
    && DEBIAN_PATCH_TAR=$(curl -fsSL "https://${SURY_HOST}/php/pool/main/p/php7.4/" | grep -oE 'php7\.4_7\.4\.33-[^"]+\.debian\.tar\.xz' | sort -V | tail -n 1) \
    && echo "Applying security patches from: ${DEBIAN_PATCH_TAR}" \
    && curl -fsSL "https://${SURY_HOST}/php/pool/main/p/php7.4/${DEBIAN_PATCH_TAR}" -o debian.tar.xz \
    && tar -xJf debian.tar.xz -C php-${PHP_VERSION} \
    && cd php-${PHP_VERSION} \
    && while read -r p; do \
        case "$p" in \#*|"") continue ;; esac; \
        echo "Patching: $p"; \
        patch -p1 < "debian/patches/$p"; \
    done < debian/patches/series \
    && export PKG_CONFIG_PATH="/opt/openssl-1.1.1/lib/pkgconfig" \
    && export CFLAGS="-O2 -std=gnu99 -Wno-incompatible-pointer-types -I/opt/openssl-1.1.1/include" \
    && export LDFLAGS="-L/opt/openssl-1.1.1/lib -Wl,-rpath=/opt/openssl-1.1.1/lib" \
    && ./configure \
        --prefix=/usr/local/php74 \
        --with-config-file-path=/usr/local/php74/etc \
        --with-config-file-scan-dir=/usr/local/php74/etc/conf.d \
        --enable-fpm \
        --with-fpm-user=nginx \
        --with-fpm-group=nginx \
        --disable-cgi \
        --enable-mbstring \
        --enable-opcache \
        --enable-session \
        --with-curl \
        --with-openssl=/opt/openssl-1.1.1 \
        --with-zlib \
        --with-zip \
        --with-pdo-sqlite \
        --with-sqlite3 \
        --with-sodium \
    && make -j$(nproc) \
    && make install \
    && strip /usr/local/php74/bin/php /usr/local/php74/sbin/php-fpm /usr/sbin/nginx \
    && cd .. && rm -rf php-${PHP_VERSION} php.tar.xz debian.tar.xz

# ==============================================================================
# ЭТАП 2: Чистый финальный образ на Alpine 3.24 (OpenSSL 3.5 + Certbot)
# ==============================================================================
FROM alpine:3.24

# Устанавливаем только runtime-библиотеки (без компиляторов) и Certbot
RUN apk add --no-cache \
    openssl \
    pcre2 \
    zlib \
    libxml2 \
    sqlite-libs \
    libcurl \
    oniguruma \
    libzip \
    libsodium \
    certbot \
    supervisor \
    gettext-envsubst \
    && addgroup -S nginx 2>/dev/null || true \
    && adduser -D -S -h /var/cache/nginx -s /sbin/nologin -G nginx nginx 2>/dev/null || true

# Копируем скомпилированные бинарники и конфиги из этапа builder
COPY --from=builder /opt/openssl-1.1.1 /opt/openssl-1.1.1
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/local/php74 /usr/local/php74

RUN ln -sf /usr/local/php74/bin/php /usr/bin/php \
    && ln -sf /usr/local/php74/sbin/php-fpm /usr/sbin/php-fpm7.4 \
    && mkdir -p /var/www/html /var/www/certbot /run/nginx /var/log/nginx /var/log/supervisor /etc/nginx/conf.d /etc/nginx/templates /usr/local/php74/etc/conf.d /usr/local/php74/etc/php-fpm.d /usr/local/php74/etc/php/7.4/fpm \
    && ln -sf /usr/local/php74/etc/php-fpm.conf /usr/local/php74/etc/php/7.4/fpm/php-fpm.conf \
    && chown -R nginx:nginx /var/www/html /var/www/certbot \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Настраиваем PHP-FPM 7.4 (порт 9000, пользователь nginx, вывод всех ошибок в stderr)
RUN { \
        echo "[global]"; \
        echo "error_log = /proc/self/fd/2"; \
        echo "daemonize = no"; \
        echo "include = /usr/local/php74/etc/php-fpm.d/*.conf"; \
    } > /usr/local/php74/etc/php-fpm.conf \
    && { \
        echo "[www]"; \
        echo "user = nginx"; \
        echo "group = nginx"; \
        echo "listen = 127.0.0.1:9000"; \
        echo "pm = dynamic"; \
        echo "pm.max_children = 15"; \
        echo "pm.start_servers = 2"; \
        echo "pm.min_spare_servers = 1"; \
        echo "pm.max_spare_servers = 3"; \
        echo "catch_workers_output = yes"; \
        echo "decorate_workers_output = no"; \
        echo "php_admin_flag[log_errors] = on"; \
        echo "php_admin_value[error_log] = /proc/self/fd/2"; \
    } > /usr/local/php74/etc/php-fpm.d/www.conf \
    && { \
        echo "zend_extension=opcache.so"; \
        echo "log_errors = On"; \
        echo "display_errors = Off"; \
        echo "expose_php = Off"; \
    } > /usr/local/php74/etc/conf.d/99-custom.ini

# Задача автопродления сертификатов в cron (в 03:00)
RUN echo "0 3 * * * /usr/bin/certbot renew --webroot -w /var/www/certbot --deploy-hook '/usr/sbin/nginx -s reload' --quiet" >> /etc/crontabs/root

COPY nginx-main.conf /etc/nginx/nginx.conf
COPY default.conf.template /etc/nginx/templates/default.conf.template
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
COPY certbot-init.sh /certbot-init.sh

RUN sed -i 's/\r$//' /entrypoint.sh /certbot-init.sh \
    && chmod +x /entrypoint.sh /certbot-init.sh

ENV DOMAIN=""
ENV EMAIL=""

WORKDIR /var/www/html
EXPOSE 80 443

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
