# Nginx 1.24 + OpenSSL 3.5 + PHP 7.4 + Certbot

Включает базовые настройки, Gzip-сжатие для статики и поддержку больших загрузок (медиафайлы, плагины, темы).

# Что добавлено в сборку для CMS

• Базы данных: mysql (MySQL / MariaDB), pgsql (PostgreSQL — часто используется для Drupal), sqlite3 (для легких установок и тестов).
• Графика: gd и imagick с поддержкой WebP, JPEG, PNG, SVG (нужны для генерации миниатюр в WordPress и Image Styles в Drupal).
• Строки, локали и данные: mbstring, intl (обязателен для мультиязычности Drupal и WooCommerce), xml, soap, zip, curl, bcmath.
• Производительность: opcache (уже включен с базовым тюнингом) и apcu + redis для объектного кэширования.
• Nginx: добавлен ngx_http_sub_module (подмена URL в ответе, удобно при работе за прокси/CDN), ngx_http_realip_module (корректное определение IP посетителей за Cloudflare/прокси) и headers-more (управление HTTP-заголовками).

Конфиг настроен так, чтобы одновременно корректно обрабатывать ЧПУ обоих движков, защиту системных файлов Drupal/WordPress, ресайз картинок Drupal (styles) и валидацию Certbot.