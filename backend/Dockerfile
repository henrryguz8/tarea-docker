# syntax=docker/dockerfile:1

# ---------- Etapa 1: dependencias de Composer ----------
FROM composer:2 AS vendor
WORKDIR /app
# Primero solo composer.json/lock para aprovechar la caché de capas
COPY composer.json composer.lock ./
RUN composer install \
    --no-dev --no-interaction --prefer-dist \
    --no-scripts --no-autoloader --ignore-platform-reqs
# Luego el código y se genera el autoloader optimizado
COPY . .
RUN composer dump-autoload --optimize --no-dev --no-scripts --ignore-platform-reqs

# ---------- Etapa 2: imagen final (PHP-FPM + Nginx) ----------
FROM php:8.4-fpm-alpine AS production
WORKDIR /var/www/html

# Nginx + Supervisor (para correr nginx y php-fpm en el mismo contenedor)
RUN apk add --no-cache nginx supervisor \
    && docker-php-ext-install pdo_mysql \
    # La imagen oficial ya trae mbstring, openssl, tokenizer, xml, ctype y json.
    # Verificamos que estén todas:
    && php -m | grep -iE '^(pdo_mysql|mbstring|openssl|tokenizer|xml|ctype|json)$' | sort

# Configuración
COPY docker/nginx.conf /etc/nginx/http.d/default.conf
COPY docker/supervisord.conf /etc/supervisord.conf
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN sed -i 's/\r$//' /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh

# Código + vendor desde la etapa de build (sin Composer en la imagen final)
COPY --from=vendor --chown=www-data:www-data /app /var/www/html

EXPOSE 80
ENTRYPOINT ["entrypoint.sh"]
