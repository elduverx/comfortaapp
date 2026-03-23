const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const dotenv = require('dotenv');
const http = require('http');
const { Server } = require('socket.io');

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require('./routes/auth');
const tripRoutes = require('./routes/trips');
const userRoutes = require('./routes/users');
const profileRoutes = require('./routes/profile');
const adminRoutes = require('./routes/admin');
const pricingRoutes = require('./routes/pricing');
const deviceTokenRoutes = require('./routes/deviceTokens');

// Import middleware
const errorHandler = require('./middleware/errorHandler');

// Create Express app
const app = express();
const server = http.createServer(app);

// Initialize Socket.IO for real-time updates
const io = new Server(server, {
  cors: {
    origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
    methods: ['GET', 'POST', 'PATCH', 'DELETE']
  }
});

// Make io accessible in routes
app.set('io', io);

// Middleware
app.use(helmet()); // Security headers
app.use(compression()); // Gzip compression
app.use(cors({
  origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
  credentials: true
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/trips', tripRoutes);
app.use('/api/users', userRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/pricing', pricingRoutes);
app.use('/api/device-tokens', deviceTokenRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint not found'
  });
});

// Error handler
app.use(errorHandler);

// Socket.IO connection handling
io.on('connection', (socket) => {
  console.log('✅ Client connected:', socket.id);

  // Join room for admin updates
  socket.on('join-admin', () => {
    socket.join('admin-room');
    console.log('Admin joined room');
  });

  // Join room for specific trip updates
  socket.on('join-trip', (tripId) => {
    socket.join(`trip-${tripId}`);
    console.log(`User joined trip room: ${tripId}`);
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

// Start server
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

server.listen(PORT, HOST, () => {
  console.log('🚀 ComfortaApp Backend Server');
  console.log(`📍 Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`🌐 Server running on http://${HOST}:${PORT}`);
  console.log(`💚 Health check: http://${HOST}:${PORT}/health`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('Server closed');
    process.exit(0);
  });
});

module.exports = { app, server, io };
