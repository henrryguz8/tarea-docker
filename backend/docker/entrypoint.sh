#!/bin/sh
set -e
cd /var/www/html

# Carpetas que Laravel necesita escribir
mkdir -p storage/framework/cache/data storage/framework/sessions storage/framework/views storage/logs bootstrap/cache

# Si no se definió APP_KEY, se genera una temporal (recomendado definirla en .env)
if [ -z "$APP_KEY" ]; then
  export APP_KEY="base64:$(head -c 32 /dev/urandom | base64)"
  echo "!! APP_KEY no definida: se generó una temporal. Define APP_KEY en tu .env"
fi

# Migraciones automáticas (se controla con RUN_MIGRATIONS en el .env)
if [ "$RUN_MIGRATIONS" = "true" ]; then
  echo ">> Ejecutando migraciones..."
  php artisan migrate --force || echo "!! Las migraciones fallaron, continuando..."
fi

php artisan config:cache || true

chown -R www-data:www-data storage bootstrap/cache

exec /usr/bin/supervisord -c /etc/supervisord.conf
