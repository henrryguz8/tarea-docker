# 🐳 Tarea Docker — Ecosistema Next.js + Laravel + MySQL

## Descripción general

Ecosistema de tres servicios listo para producción, orquestado con Docker Compose y construido con **Dockerfiles multi-stage** para obtener imágenes ligeras, seguras y reproducibles.

| Servicio | Tecnología | Imagen base | Puerto |
|----------|-----------|-------------|--------|
| Frontend | Next.js 16 (App Router) — *messages-app* | `node:20-alpine` | 3000 |
| Backend  | Laravel 12 + Sanctum — *final-api* (PHP-FPM + Nginx) | `php:8.4-fpm-alpine` | 8000 → 80 |
| Base de datos | MySQL 8.0 | `mysql:8.0` | 3306 (solo red interna) |

## Arquitectura de contenedores

```
                    Host (tu PC)
                         │
         ┌───────────────┼────────────────┐
     :3000│                           :8000│
 ┌────────▼────────┐             ┌────────▼─────────┐
 │    frontend     │   HTTP      │     backend      │
 │    Next.js      ├────────────►│  Nginx + PHP-FPM │
 │ (usuario nextjs)│  frontend-  │    (Laravel)     │
 └─────────────────┘    net      └────────┬─────────┘
                                          │ backend-net
                                 ┌────────▼─────────┐
                                 │       db         │
                                 │     MySQL 8.0    │
                                 │ volumen db_data  │
                                 └──────────────────┘
```

- **Dos redes aisladas**: `frontend-net` (frontend ↔ backend) y `backend-net` (backend ↔ db). El frontend **no** puede llegar a la base de datos.
- MySQL **no publica puertos** al host.
- Los datos de MySQL persisten en el volumen `db_data` (`/var/lib/mysql`).
- El backend espera a que MySQL esté *healthy* antes de arrancar (`depends_on` + `healthcheck`).

## Endpoints de la API (final-api)

| Método | Ruta | Acceso |
|--------|------|--------|
| GET | `/api/health` | Público (estado de la API y la BD) |
| POST | `/api/register`, `/api/login` | Público |
| GET | `/api/posts` | Público |
| POST/PUT/DELETE | `/api/posts...` | Token Sanctum |

Prueba rápida (PowerShell):
```powershell
curl.exe http://localhost:8000/api/health
```

## Estructura del repositorio

```
tarea-docker/
├── docker-compose.yml
├── .env.example
├── README.md
├── db/init/01-init.sql        # script opcional de inicialización
├── frontend/                  # Next.js (messages-app) + Dockerfile
└── backend/                   # Laravel (final-api) + Dockerfile + docker/ (nginx, supervisor, entrypoint)
```

## Cómo ejecutarlo

Requisitos: Docker Desktop (Docker Compose v2).

```powershell
# 1. Clonar el repositorio
git clone https://github.com/henrryguz8/tarea-docker.git
cd tarea-docker

# 2. Crear el archivo de variables de entorno
copy .env.example .env

# 3. (Recomendado) Generar la APP_KEY de Laravel y pegarla en .env
docker run --rm php:8.4-cli-alpine php -r "echo 'base64:'.base64_encode(random_bytes(32)).PHP_EOL;"

# 4. Construir y levantar todo con un solo comando
docker compose up -d --build
```

Abrir:
- Frontend: http://localhost:3000
- API: http://localhost:8000/api/health
- Estado combinado (Next → Laravel → MySQL): http://localhost:3000/api/status

Comandos útiles:

```powershell
docker compose ps              # estado de los servicios
docker compose logs -f backend # logs
docker compose down            # detener (conserva datos)
docker compose down -v         # detener y borrar el volumen de MySQL
docker images                  # comparar tamaños de las imágenes
```

## Decisiones técnicas

### Frontend (Next.js)
- **3 etapas** (`deps` → `builder` → `runner`): las dependencias de desarrollo y el código fuente nunca llegan a la imagen final.
- `output: 'standalone'` en `next.config.mjs`: Next genera `server.js` con solo los módulos necesarios, reduciendo drásticamente el tamaño (equivale a `next start` optimizado).
- **Caché de capas**: se copia primero `package*.json` y se instala; el código se copia después, así cambiar el código no reinstala dependencias.
- **Seguridad**: se ejecuta con el usuario `nextjs` (no root) y se usa `alpine` para reducir la superficie de ataque.
- Telemetría de Next desactivada.

### Backend (Laravel)
- **PHP 8.4 en lugar de 8.2**: el enunciado pide PHP 8.2+; el `composer.lock` del proyecto resolvió paquetes de Symfony 8 que requieren PHP ≥ 8.4.1, por lo que se usa `php:8.4-fpm-alpine` para que el código y las dependencias sean consistentes.
- **2 etapas**: `composer:2` instala dependencias (`--no-dev`, autoloader optimizado) y la imagen final `php:8.4-fpm-alpine` solo recibe el resultado: **Composer no existe en la imagen final**.
- **Extensiones**: se instala `pdo_mysql`; `mbstring`, `openssl`, `tokenizer`, `xml`, `ctype` y `json` ya vienen en la imagen oficial y se verifican con `php -m` durante el build.
- **Nginx + PHP-FPM** en un solo contenedor gestionados con `supervisord`; logs a stdout/stderr para verlos con `docker logs`.
- `entrypoint.sh` prepara permisos de `storage/`, ejecuta migraciones (opcional con `RUN_MIGRATIONS`) y cachea la configuración.
- `.dockerignore` excluye `.env`, `vendor`, `node_modules`, logs y tests: los secretos **nunca** entran en la imagen; se inyectan por variables de entorno.

### Base de datos (MySQL)
- Imagen oficial `mysql:8.0` configurada solo con variables de entorno.
- Volumen nombrado `db_data` para persistencia.
- Scripts SQL en `/docker-entrypoint-initdb.d/` (solo corren al crear el volumen por primera vez).
- `healthcheck` con `mysqladmin ping` para ordenar el arranque.
- Sin puerto publicado al host.

### Generales
- Un único `.env` (no versionado) alimenta todo; `.env.example` documenta cada variable.
- Imágenes etiquetadas `usuario/tarea-docker-<servicio>:1.0` para publicarlas en Docker Hub.

## Publicación en Docker Hub

```powershell
docker login
docker compose build
docker push henryguz8/tarea-docker-frontend:1.0
docker push henryguz8/tarea-docker-backend:1.0
```

Imágenes: 
- https://hub.docker.com/r/henryguz8/tarea-docker-frontend
- https://hub.docker.com/r/henryguz8/tarea-docker-backend
