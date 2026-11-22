# Docker images Nginx + OpenSSL 3.5 + PHP (7.4 / 8.3) + Certbot

[![Build Status](https://github.com)](https://github.com)
[![GitHub Stars](https://shields.io)](https://github.com)

| Image | Version | Size | Pulls |
| :--- | :--- | :--- | :--- |
| **nginx-php8.3-certbot-cms** | ![Version](https://shields.io) | ![Size](https://shields.io) | ![Pulls](https://shields.io) |
| **nginx-php8.3-certbot** | ![Version](https://shields.io) | ![Size](https://shields.io) | ![Pulls](https://shields.io) |
| **nginx-php7.4-certbot-cms** | ![Version](https://shields.io) | ![Size](https://shields.io) | ![Pulls](https://shields.io) |
| **nginx-php7.4-certbot** | ![Version](https://shields.io) | ![Size](https://shields.io) | ![Pulls](https://shields.io) |
| **nginx-php7.4-certbot-cms-debian** | ![Version](https://shields.io) | ![Size](https://shields.io) | ![Pulls](https://shields.io) |

The aim of this repository is to build docker images with fresh set of **nginx + certbot + php-fpm and OpenSSL 3.5** (with support of X25519MLKEM768 required for iOS)

**Five variants provided:**
- nginx 1.24 + php 7.4 compiled
- nginx 1.24 + php 7.4 + Wordpress/Drupal support compiled (`cms` in the folder name)
- nginx 1.24 + php 7.4 + Wordpress/Drupal support Debian packages (`cms` in the folder name)
- nginx 1.30 + php 8.3.37 from Alpine packages
- nginx 1.30 + php 8.3.37 Wordpress/Drupal support from Alpine packages (`cms` in the folder name)

Provided images fix the following known vulnerabilities:
- **nginx2root**: HTTP/2 (CVE-2026-123633, CVE-2026-123007), CVE-2026-123634 in resolver - only in nginx 1.28 / 1.30
- **PHP2Shell**: (CVE-2026-109618, CVE-2026-109619)

## Russian

# Docker-образы Nginx + OpenSSL 3.5 + PHP (7.4 / 8.3) + Certbot

Набор легковесных все-в-одном (all-in-one) Docker-образов на базе **Alpine Linux** с веб-сервером **Nginx** (собранным с **OpenSSL 3.5**), **PHP-FPM** и автоматическим выпуском/продлением SSL-сертификатов **Let's Encrypt (Certbot)** по расписанию через `crond`.

Все службы внутри контейнера работают под управлением `supervisord`, а логи доступа и ошибок (Nginx, PHP-FPM, Cron, Certbot) выводятся напрямую в `stdout` / `stderr` (`docker logs`).

## Доступные образы

| Папка / Репозиторий | Базовая ОС | Nginx | OpenSSL (TLS) | PHP | Назначение |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`alexishw/nginx-php7.4-certbot`** | Alpine 3.22/3.24 | `1.24.0` | `3.5.x` | `7.4.33` (с патчами CVE) | Легковесный образ для legacy-проектов (~52 МБ) |
| **`alexishw/nginx-php7.4-certbot-cms`** | Alpine 3.22/3.24 | `1.24.0` | `3.5.x` | `7.4.33` (с патчами CVE) | Полный набор модулей для WordPress и Drupal (~61 МБ) |
| **`alexishw/nginx-php7.4-certbot-cms-debian`** | debian:trixie-slim | `1.24.0` | `3.5.x` | `7.4.33` (с патчами CVE) | Полный набор модулей для WordPress и Drupal (~224 МБ) |
| **`alexishw/nginx-php8.3-certbot`** | Alpine 3.24 | `1.30.x` | `3.5.x` | `8.3` | Легковесный образ для современных проектов (~40 МБ) |
| **`alexishw/nginx-php8.3-certbot-cms`** | Alpine 3.24 | `1.30.x` | `3.5.x` | `8.3` | Полный набор модулей для WordPress и Drupal (~60 МБ) |

### Особенности и безопасность сборок
* **Современный TLS (OpenSSL 3.5):** во всех 4 образах Nginx слинкован с системным OpenSSL 3.5 (поддержка TLS 1.2 / TLS 1.3 и современных криптоалгоритмов).
* **Актуальная защита от CVE для PHP 7.4:** при сборке образов `nginx-php7.4-certbot` и `nginx-php7.4-certbot-cms` автоматически скачивается и применяется полная серия бэкпорт-патчей безопасности из репозитория `deb.sury.org`.
* **Расширения PHP в `*-cms`:** `mysqli` и `pdo_mysql` (полная поддержка MariaDB и MySQL), `pgsql` и `pdo_pgsql` (PostgreSQL), `sqlite3`, `gd` (JPEG/PNG/WebP/FreeType), `imagick`, `mbstring`, `xml`, `curl`, `zip`, `intl`, `bcmath`, `soap`, `exif`, `sodium`, `opcache`, `apcu`, `redis`, `memcached`.
* **Настройки Nginx в `*-cms`:** подключен модуль `headers-more` (скрытие заголовка `Server`), включено Gzip-сжатие, увеличен лимит загрузки файлов (`client_max_body_size 128M`, `upload_max_filesize = 128M`), настроены правила ЧПУ и защиты системных файлов WordPress и Drupal.

---

## Переменные окружения

| Переменная | По умолчанию | Описание |
| :--- | :--- | :--- |
| **`DOMAIN`** | `""` (пусто) | Доменное имя или список доменов через пробел (например, `"example.ru www.example.ru"`). Если переменная не задана, Nginx настраивается на прием любых доменов и IP (`server_name _;`). |
| **`EMAIL`** | `""` (пусто) | Email администратора для регистрации в Let's Encrypt. Если заданы одновременно `DOMAIN` и `EMAIL`, контейнер при первом старте автоматически выпустит SSL-сертификат и настроит редирект на HTTPS. |

---

## Примеры запуска

### 1. Запуск в режиме HTTP (без SSL, для любых доменов)
```bash
docker run -d \
  --name web \
  -p 80:80 \
  -v $(pwd)/src:/var/www/html \
  --restart unless-stopped \
  alexishw/nginx-php8.3-certbot-cms:latest
```

### 2. Запуск с автоматическим выпуском SSL-сертификата
Убедитесь, что A-запись домена уже указывает на IP-адрес сервера, а порты `80` и `443` открыты.

```bash
docker run -d \
  --name web \
  -e DOMAIN="example.ru www.example.ru" \
  -e EMAIL="admin@example.ru" \
  -p 80:80 \
  -p 443:443 \
  -v $(pwd)/src:/var/www/html \
  -v $(pwd)/letsencrypt:/etc/letsencrypt \
  -v $(pwd)/nginx-conf:/etc/nginx/http.d \
  --restart unless-stopped \
  alexishw/nginx-php8.3-certbot-cms:latest
```
> **Примечание по путям конфигов Nginx:**
> * Для образов **`nginx-php8.3-certbot` и `nginx-php8.3-certbot-cms`** виртуальные хосты лежат в `/etc/nginx/http.d` (`-v $(pwd)/nginx-conf:/etc/nginx/http.d`).
> * Для образов **`nginx-php7.4-certbot` и `nginx-php7.4-certbot-cms`** виртуальные хосты лежат в `/etc/nginx/conf.d` (`-v $(pwd)/nginx-conf:/etc/nginx/conf.d`).

### 3. Запуск через `docker-compose.yml` (с базой данных MariaDB)

```yaml
services:
  web:
    image: alexishw/nginx-php8.3-certbot-cms:latest
    container_name: cms-web
    ports:
      - "80:80"
      - "443:443"
    environment:
      DOMAIN: "example.ru www.example.ru"
      EMAIL: "admin@example.ru"
    volumes:
      - ./src:/var/www/html
      - ./letsencrypt:/etc/letsencrypt
      - ./nginx-conf:/etc/nginx/http.d # Для nginx-php7.4-certbot / nginx-php7.4-certbot-cms замените на /etc/nginx/conf.d
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: mariadb:11
    container_name: cms-db
    environment:
      MARIADB_ROOT_PASSWORD: "strong_root_password"
      MARIADB_DATABASE: "cms_db"
      MARIADB_USER: "cms_user"
      MARIADB_PASSWORD: "strong_user_password"
    volumes:
      - ./db-data:/var/lib/mysql
    restart: unless-stopped
```

---

## Управление и обслуживание

* **Продление сертификатов:** выполняется автоматически системным планировщиком `crond` дважды в сутки (в `03:00` и `15:00`).
* **Просмотр логов (Nginx + PHP + Cron + Certbot):**
  ```bash
  docker logs -f web
  ```
* **Проверка версий и активных модулей внутри контейнера:**
  ```bash
  docker exec -it web sh -c "nginx -V && php -v && php -m && openssl version"
  ```

## Версионирование и CI/CD

Сборка и публикация образов настроены через GitHub Actions (`.github/workflows/docker-publish.yml`):
* При изменении файлов в любой из папок (кроме `README.md` и `VERSION`) собирается и публикуется только затронутый образ.
* Номер версии берется из файла `VERSION` внутри соответствующей папки (теги `:1.0`, `:1.1` и `:latest`), после чего минорная версия автоматически увеличивается на `+0.1`.
