# ComfortaApp Backend - Guía de Instalación Rápida

## 📋 Requisitos Previos

- Node.js 18+ instalado
- PostgreSQL instalado y corriendo
- Cuenta en Hostinger (para producción)

## 🚀 Inicio Rápido (5 minutos)

### 1. Instalar Dependencias

```bash
cd backend
npm install
```

### 2. Configurar Variables de Entorno

```bash
cp .env.example .env
```

Editar `.env` con tus credenciales:

```env
# Base de Datos PostgreSQL
DB_HOST=localhost
DB_PORT=5432
DB_NAME=comfortaapp
DB_USER=tu_usuario_postgres
DB_PASSWORD=tu_password_seguro

# JWT Secret (genera uno aleatorio)
JWT_SECRET=tu-clave-super-secreta-jwt-cambiar-en-produccion
```

### 3. Crear Base de Datos

```bash
# Conectar a PostgreSQL
psql -U postgres

# Ejecutar en PostgreSQL:
CREATE DATABASE comfortaapp;
CREATE USER comfortaapp_user WITH PASSWORD 'tu_password_seguro';
GRANT ALL PRIVILEGES ON DATABASE comfortaapp TO comfortaapp_user;
\q
```

### 4. Ejecutar Migraciones

```bash
psql -U comfortaapp_user -d comfortaapp -f src/database/schema.sql
```

### 5. Iniciar Servidor

```bash
# Desarrollo (con auto-reload)
npm run dev

# Producción
npm start
```

El servidor estará corriendo en `http://localhost:3000`

## ✅ Verificar Funcionamiento

Abre en tu navegador o usa curl:

```bash
curl http://localhost:3000/health
```

Deberías ver:

```json
{
  "status": "ok",
  "timestamp": "2024-01-24T...",
  "uptime": 1.234,
  "environment": "development"
}
```

## 📱 Configurar App iOS

La app iOS ya está configurada para conectarse al nuevo backend:

**En desarrollo**: 
- La app apunta a `http://localhost:3000`
- Asegúrate de que el backend esté corriendo

**En producción**: 
- Cambia la URL en `APIConfiguration.swift` línea 33 a tu dominio de Hostinger

## 🌐 Desplegar en Hostinger

### Opción 1: FTP/SFTP (Más Fácil)

1. Comprimir backend:
```bash
tar -czf backend.tar.gz backend/
```

2. Subir a Hostinger vía FTP

3. En servidor Hostinger:
```bash
ssh usuario@tu-servidor.com
tar -xzf backend.tar.gz
cd backend
npm install --production
```

4. Iniciar con PM2:
```bash
npm install -g pm2
pm2 start src/server.js --name comfortaapp
pm2 startup
pm2 save
```

### Opción 2: Git (Recomendado)

1. Crear repositorio Git:
```bash
cd backend
git init
git add .
git commit -m "Initial backend setup"
git remote add origin tu-repo-git
git push -u origin main
```

2. En Hostinger:
```bash
git clone tu-repo-git comfortaapp-backend
cd comfortaapp-backend
npm install --production
pm2 start src/server.js --name comfortaapp
```

## 🔐 Configurar HTTPS (Hostinger)

Hostinger generalmente proporciona SSL automático. Si no:

1. Obtener certificado SSL gratis con Let's Encrypt
2. Configurar nginx como reverse proxy
3. Actualizar .env con `NODE_ENV=production`

## 📊 Monitoreo

Ver logs en tiempo real:
```bash
pm2 logs comfortaapp
```

Ver estado del servidor:
```bash
pm2 status
pm2 monit
```

Reiniciar servidor:
```bash
pm2 restart comfortaapp
```

## 🆘 Solución de Problemas

### Puerto 3000 ocupado
```bash
# Linux/Mac
lsof -ti:3000 | xargs kill

# Windows
netstat -ano | findstr :3000
taskkill /PID <PID> /F
```

### Error de conexión a PostgreSQL
1. Verificar que PostgreSQL esté corriendo:
   ```bash
   # Mac
   brew services list
   
   # Linux
   sudo systemctl status postgresql
   ```

2. Verificar credenciales en `.env`

3. Verificar que el usuario tenga permisos:
   ```sql
   GRANT ALL PRIVILEGES ON DATABASE comfortaapp TO comfortaapp_user;
   ```

### node_modules corrupto
```bash
rm -rf node_modules package-lock.json
npm install
```

## 📱 Probar con la App

1. Asegúrate de que el backend esté corriendo
2. Abre la app en simulador de iOS
3. Intenta crear un viaje
4. Verás logs en el terminal del backend
5. El viaje debería aparecer en el panel de admin en tiempo real

## 🎯 Próximos Pasos

1. Implementar autenticación con Apple Sign In
2. Agregar notificaciones push con APNs
3. Implementar rate limiting para seguridad
4. Configurar monitoreo con logs externos
5. Agregar tests unitarios

## 📞 Soporte

Si tienes problemas, revisa los logs:
```bash
pm2 logs comfortaapp --lines 100
```

¡Listo! Tu backend está completamente separado y funcionando. 🚀
