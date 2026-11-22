# Alpine 3.23 + Nginx + OpenSSL 3.5 + PHP 8.3 + Certbot

Готовая сборка на базе alpine:3.23 с Nginx (на системном OpenSSL 3.5), PHP 8.3 (с Memcached, Redis, Imagick, GD и остальными модулями для WordPress и Drupal) и Certbot приведена ниже.
В отличие от сборки с PHP 7.4, здесь не нужно подключать сторонние репозитории или компилировать PHP вручную: в официальном репозитории alpine:3.23 уже есть готовые бинарные пакеты и для OpenSSL 3.5, и для PHP 8.3 с расширением php83-pecl-memcached, и для Nginx (включая модуль headers-more).


# Особенности и запуск

• Кэширование: установлены php83-pecl-memcached, php83-pecl-redis, php83-pecl-apcu и php83-opcache. Обратите внимание, что это PHP-клиенты для подключения к внешним сервисам (демон самого сервера Memcached или Redis в контейнер не включен — к нему нужно подключаться по сети).
• Специфичные модули WordPress и Drupal: помимо стандартных расширений добавлены php83-exif (метаданные фото и ориентация при загрузке в медиатеку WP), php83-fileinfo (проверка MIME-типов загружаемых файлов) и php83-pecl-imagick (обработка изображений и WebP).

## Сборка и первый выпуск сертификата:
docker build -t nginx-php83-cms .
docker run -d --name web83 -p 80:80 -p 443:443 \
  -v $(pwd)/src:/var/www/html \
  -v $(pwd)/letsencrypt:/etc/letsencrypt \
  nginx-php83-cms

### Выпуск сертификата через webroot
docker exec -it web83 certbot certonly --webroot -w /var/www/certbot -d ваш-домен.ru
