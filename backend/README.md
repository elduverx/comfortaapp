# ComfortaApp Backend

Backend Node.js + Express completamente nuevo y dedicado para ComfortaApp, desvinculado de comforta.es

## 🚀 Stack Tecnológico

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Base de Datos**: PostgreSQL
- **Real-time**: Socket.IO
- **Autenticación**: JWT
- **Hosting**: Hostinger (VPS)

## 📦 Instalación

1. Instalar dependencias:
```bash
npm install
```

2. Configurar variables de entorno:
```bash
cp .env.example .env
# Editar .env con tus credenciales
```

3. Crear base de datos PostgreSQL:
```bash
# Conectar a PostgreSQL
psql -U postgres

# Crear base de datos
CREATE DATABASE comfortaapp;

# Crear usuario
CREATE USER comfortaapp_user WITH PASSWORD 'tu_password_seguro';
GRANT ALL PRIVILEGES ON DATABASE comfortaapp TO comfortaapp_user;
```

4. Ejecutar migraciones:
```bash
psql -U comfortaapp_user -d comfortaapp -f src/database/schema.sql
```

5. Iniciar servidor en desarrollo:
```bash
npm run dev
```

## 🌐 Endpoints API

### Autenticación
- `POST /api/auth/login` - Login con Apple ID
- `POST /api/auth/register` - Registro de usuario
- `POST /api/auth/refresh` - Refrescar token JWT

### Viajes (Usuarios)
- `POST /api/trips` - Crear nuevo viaje
- `GET /api/trips` - Obtener historial de viajes
- `GET /api/trips/:id` - Obtener detalle de viaje
- `PATCH /api/trips/:id` - Actualizar viaje
- `DELETE /api/trips/:id` - Cancelar viaje

### Administración
- `GET /api/admin/trips` - Listar todos los viajes
- `GET /api/admin/trips/:id` - Detalle de viaje (admin)
- `PATCH /api/admin/trips/:id` - Actualizar estado de viaje
- `GET /api/admin/users` - Listar usuarios
- `GET /api/admin/stats` - Estadísticas del sistema

### Pricing
- `POST /api/pricing/calculate` - Calcular precio de viaje

### Usuarios
- `GET /api/users/profile` - Obtener perfil
- `PATCH /api/users/profile` - Actualizar perfil
- `POST /api/users/device-token` - Registrar token para push notifications

## 🔄 Real-time con Socket.IO

### Eventos del Cliente
- `join-admin` - Unirse a sala de administración
- `join-trip` - Unirse a sala de viaje específico

### Eventos del Servidor
- `trip-created` - Nuevo viaje creado
- `trip-updated` - Viaje actualizado
- `trip-assigned` - Conductor asignado

## 🚀 Deployment en Hostinger

1. Conectar por SSH:
```bash
ssh usuario@tu-servidor-hostinger.com
```

2. Instalar Node.js (si no está instalado):
```bash
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs
```

3. Instalar PostgreSQL:
```bash
sudo apt-get install postgresql postgresql-contrib
```

4. Clonar o subir el proyecto:
```bash
git clone <tu-repo> comfortaapp-backend
cd comfortaapp-backend
npm install --production
```

5. Configurar .env con credenciales de producción

6. Usar PM2 para mantener el servidor corriendo:
```bash
npm install -g pm2
pm2 start src/server.js --name comfortaapp-backend
pm2 startup
pm2 save
```

7. Configurar nginx como reverse proxy:
```nginx
server {
    listen 80;
    server_name api.tudominio.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

## 📱 Configuración en la App Swift

Actualizar `APIConfiguration.swift`:

```swift
static let baseURL = "https://api.tudominio.com"
static let apiBasePath = "/api"
```

## 🔐 Seguridad

- Todas las rutas protegidas requieren token JWT
- Helmet.js para headers de seguridad
- CORS configurado
- Rate limiting (opcional, agregar express-rate-limit)
- Validación de datos con express-validator

## 📊 Monitoreo

Ver logs en producción:
```bash
pm2 logs comfortaapp-backend
pm2 monit
```

## 🧪 Testing

```bash
npm test
```

## 📝 Variables de Entorno Requeridas

Ver `.env.example` para la lista completa de variables necesarias.

## 🆘 Troubleshooting

### Error de conexión a PostgreSQL
- Verificar que PostgreSQL esté corriendo: `sudo systemctl status postgresql`
- Verificar credenciales en .env
- Verificar que el usuario tiene permisos

### Puerto ya en uso
- Cambiar PORT en .env
- O matar proceso: `lsof -ti:3000 | xargs kill`

## 📚 Documentación Adicional

- [Express.js Docs](https://expressjs.com/)
- [PostgreSQL Docs](https://www.postgresql.org/docs/)
- [Socket.IO Docs](https://socket.io/docs/)
