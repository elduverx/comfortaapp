const express = require('express');
const router = express.Router();
const { body, validationResult } = require('express-validator');
const { v4: uuidv4 } = require('uuid');

// In-memory trip storage (for development without PostgreSQL)
// TODO: Replace with PostgreSQL in production
const trips = new Map();

// Helper to use database if available, fallback to in-memory
let useDatabase = false;
try {
  const { query } = require('../config/database');
  // Test database connection (will fail gracefully if not configured)
  useDatabase = false; // For now always use in-memory for quick setup
} catch (error) {
  console.log('📝 Using in-memory storage (PostgreSQL not configured)');
  useDatabase = false;
}

// Create new trip
router.post('/', async (req, res, next) => {
  try {
    const {
      lugarRecogida,
      destino,
      fechaInicio,
      fechaFin,
      franjaHoraria,
      notas,
      distanciaKm,
      precioBase,
      precioTotal,
      pickupLat,
      pickupLng,
      destinationLat,
      destinationLng,
      pickup_lat,
      pickup_lng,
      destination_lat,
      destination_lng
    } = req.body;

    const userId = req.user?.id || req.body.userId || 'anonymous';

    // Create trip object
    const trip = {
      id: uuidv4(),
      user_id: userId,
      pickup_location: lugarRecogida,
      destination: destino,
      pickup_lat: pickupLat ?? pickup_lat ?? null,
      pickup_lng: pickupLng ?? pickup_lng ?? null,
      destination_lat: destinationLat ?? destination_lat ?? null,
      destination_lng: destinationLng ?? destination_lng ?? null,
      start_date: fechaInicio,
      end_date: fechaFin,
      time_slot: franjaHoraria,
      notes: notas,
      distance_km: distanciaKm,
      base_price: precioBase,
      total_price: precioTotal,
      status: 'PENDIENTE',
      paid: false,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };

    // Store trip in memory
    trips.set(trip.id, trip);

    console.log('✅ Trip created:', trip.id);
    console.log('📍 Destination:', trip.destination);
    console.log('💰 Price:', trip.total_price);

    // Emit real-time event to admin
    const io = req.app.get('io');
    if (io) {
      io.to('admin-room').emit('trip-created', {
        id: trip.id,
        destination: trip.destination,
        total_price: trip.total_price,
        created_at: trip.created_at
      });
      console.log('📡 Real-time event sent to admin');
    }

    res.status(201).json({
      success: true,
      trip: {
        id: trip.id,
        shortId: trip.id.substring(0, 8),
        nombreUsuario: null,
        email: null,
        telefono: null,
        lugarRecogida: trip.pickup_location || "",
        destino: trip.destination,
        pickupLat: trip.pickup_lat ? parseFloat(trip.pickup_lat) : null,
        pickupLng: trip.pickup_lng ? parseFloat(trip.pickup_lng) : null,
        destinationLat: trip.destination_lat ? parseFloat(trip.destination_lat) : null,
        destinationLng: trip.destination_lng ? parseFloat(trip.destination_lng) : null,
        fechaInicio: trip.start_date,
        fechaFin: trip.end_date || null,
        franjaHoraria: trip.time_slot || null,
        duracion: null,
        distanciaKm: parseFloat(trip.distance_km || 0),
        precioBase: parseFloat(trip.base_price || 0),
        recargoAeropuerto: parseFloat(trip.airport_surcharge || 0),
        precioTotal: parseFloat(trip.total_price || 0),
        estado: trip.status,
        pagado: trip.paid || false,
        numeroFactura: trip.invoice_number || null,
        paymentOrderId: trip.payment_order_id || null,
        paymentAuthCode: null,
        paymentMethod: trip.payment_method || null,
        paymentDate: trip.payment_date || null,
        paymentResponse: null,
        notas: trip.notes || null,
        notasAdmin: trip.admin_notes || null,
        conductorId: trip.driver_id || null,
        conductorNombre: trip.driver_name || null,
        createdAt: trip.created_at,
        updatedAt: trip.updated_at
      }
    });
  } catch (error) {
    console.error('❌ Error creating trip:', error);
    next(error);
  }
});

// Get trip history
router.get('/', async (req, res, next) => {
  try {
    const userId = req.user?.id || req.query.userId;
    const limit = parseInt(req.query.limit) || 20;
    const offset = parseInt(req.query.offset) || 0;

    // Get all trips for user from memory
    const userTrips = Array.from(trips.values())
      .filter(trip => !userId || trip.user_id === userId)
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
      .slice(offset, offset + limit);

    const tripList = userTrips.map(trip => ({
      id: trip.id,
      destino: trip.destination,
      lugarRecogida: trip.pickup_location,
      pickupLat: trip.pickup_lat ? parseFloat(trip.pickup_lat) : null,
      pickupLng: trip.pickup_lng ? parseFloat(trip.pickup_lng) : null,
      destinationLat: trip.destination_lat ? parseFloat(trip.destination_lat) : null,
      destinationLng: trip.destination_lng ? parseFloat(trip.destination_lng) : null,
      precioTotal: parseFloat(trip.total_price || 0),
      distanciaKm: parseFloat(trip.distance_km || 0),
      estado: trip.status,
      pagado: trip.paid,
      createdAt: trip.created_at
    }));

    res.json({ success: true, trips: tripList });
  } catch (error) {
    next(error);
  }
});

// Get trip by ID
router.get('/:id', async (req, res, next) => {
  try {
    const trip = trips.get(req.params.id);

    if (!trip) {
      return res.status(404).json({ success: false, message: 'Trip not found' });
    }

    res.json({
      success: true,
      trip: {
        id: trip.id,
        shortId: trip.id.substring(0, 8),
        nombreUsuario: null,
        email: null,
        telefono: null,
        lugarRecogida: trip.pickup_location || "",
        destino: trip.destination,
        pickupLat: trip.pickup_lat ? parseFloat(trip.pickup_lat) : null,
        pickupLng: trip.pickup_lng ? parseFloat(trip.pickup_lng) : null,
        destinationLat: trip.destination_lat ? parseFloat(trip.destination_lat) : null,
        destinationLng: trip.destination_lng ? parseFloat(trip.destination_lng) : null,
        fechaInicio: trip.start_date || trip.created_at,
        fechaFin: trip.end_date || null,
        franjaHoraria: trip.time_slot || null,
        duracion: null,
        distanciaKm: parseFloat(trip.distance_km || 0),
        precioBase: parseFloat(trip.base_price || 0),
        recargoAeropuerto: parseFloat(trip.airport_surcharge || 0),
        precioTotal: parseFloat(trip.total_price || 0),
        estado: trip.status,
        pagado: trip.paid || false,
        numeroFactura: trip.invoice_number || null,
        paymentOrderId: trip.payment_order_id || null,
        paymentAuthCode: null,
        paymentMethod: trip.payment_method || null,
        paymentDate: trip.payment_date || null,
        paymentResponse: null,
        notas: trip.notes || null,
        notasAdmin: trip.admin_notes || null,
        conductorId: trip.driver_id || null,
        conductorNombre: trip.driver_name || null,
        createdAt: trip.created_at,
        updatedAt: trip.updated_at || trip.created_at
      }
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
module.exports.trips = trips;
