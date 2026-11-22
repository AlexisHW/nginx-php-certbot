# Alpine 3.23 + Nginx + OpenSSL 3.5 + PHP 8.3 + Certbot

```
docker run -d \
  --name web \
  -p 80:80 -p 443:443 \
  -v $(pwd)/src:/var/www/html \
  -v $(pwd)/letsencrypt:/etc/letsencrypt \
  my-nginx-php83
```

• Безопасность: try_files $uri =404; в блоке location ~ \.php$ закрывает классическую уязвимость выполнения произвольного кода через загрузку файлов с двойным расширением, а server_tokens off; скрывает версию Nginx.
• Логи: и access.log / error.log Nginx, и ошибки мастера/воркеров PHP-FPM идут напрямую в docker logs.


• Запуск без переменных (docker run -d ... nginx-php83-certbot): Nginx стартует с server_name _;, принимает запросы по любому домену/IP по HTTP, certbot-init тихо завершается, ничего не ломая.
• Запуск с доменом и почтой (-e DOMAIN="example.ru www.example.ru" -e EMAIL="admin@example.ru"): при первом старте Nginx поднимается с server_name example.ru www.example.ru;, через 3 секунды certbot-init автоматически выпускает сертификат, прописывает SSL и редирект в default.conf, а дальше crond продлевает его каждые 12 часов. При последующих перезапусках контейнера скрипт видит готовый сертификат в /etc/letsencrypt/live/ и сразу завершается.
