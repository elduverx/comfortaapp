const express = require('express');
const router = express.Router();

// Import shared in-memory storage
const { trips } = require('./trips');
const { users } = require('./auth');

// Get all trips (admin)
router.get('/viajes', async (req, res, next) => {
  try {
    // Get all trips from memory
    const allTrips = Array.from(trips.values())
      .sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    const tripList = allTrips.map(trip => {
      const user = users.get(trip.user_id);
      return {
        id: trip.id,
        shortId: trip.id.substring(0, 8),
        userId: trip.user_id,
        lugarRecogida: trip.pickup_location || "",
        destino: trip.destination,
        fechaInicio: trip.start_date || trip.created_at,
        fechaFin: trip.end_date || null,
        franjaHoraria: trip.time_slot || null,
        nombreUsuario: user?.name || null,
        email: user?.email || null,
        telefono: user?.telefono || null,
        estado: trip.status,
        distanciaKm: parseFloat(trip.distance_km || 0),
        precioBase: parseFloat(trip.base_price || 0),
        recargoAeropuerto: parseFloat(trip.airport_surcharge || 0),
        precioTotal: parseFloat(trip.total_price || 0),
        pagado: trip.paid || false,
        numeroFactura: trip.invoice_number || null,
        paymentMethod: trip.payment_method || null,
        paymentOrderId: trip.payment_order_id || null,
        paymentDate: trip.payment_date || null,
        notas: trip.notes || null,
        notasAdmin: trip.admin_notes || null,
        conductorId: trip.driver_id || null,
        conductorNombre: trip.driver_name || null,
        createdAt: trip.created_at,
        updatedAt: trip.updated_at || trip.created_at
      };
    });

    res.json({ success: true, data: tripList });
  } catch (error) {
    console.error('❌ Error getting trips:', error);
    next(error);
  }
});

// Get single trip (admin)
router.get('/viajes/:id', async (req, res, next) => {
  try {
    const trip = trips.get(req.params.id);

    if (!trip) {
      return res.status(404).json({ success: false, message: 'Trip not found' });
    }

    const user = users.get(trip.user_id);

    res.json({
      success: true,
      trip: {
        id: trip.id,
        estado: trip.status,
        conductorId: trip.driver_id,
        conductorNombre: trip.driver_name,
        destino: trip.destination,
        lugarRecogida: trip.pickup_location,
        nombreUsuario: user?.name || null,
        email: user?.email || null,
        precioTotal: parseFloat(trip.total_price || 0)
      }
    });
  } catch (error) {
    console.error('❌ Error getting trip:', error);
    next(error);
  }
});

// Update trip status (admin)
router.patch('/viajes/:id', async (req, res, next) => {
  try {
    const { estado, notasAdmin, conductorId, conductorNombre } = req.body;
    const tripId = req.params.id;

    const trip = trips.get(tripId);

    if (!trip) {
      return res.status(404).json({ success: false, message: 'Trip not found' });
    }

    // Update fields
    if (estado) trip.status = estado;
    if (notasAdmin) trip.admin_notes = notasAdmin;
    if (conductorId) trip.driver_id = conductorId;
    if (conductorNombre) trip.driver_name = conductorNombre;

    trip.updated_at = new Date().toISOString();
    trips.set(tripId, trip);

    console.log('✅ Trip updated:', tripId);
    console.log('📊 Status:', trip.status);
    console.log('👤 Driver:', trip.driver_name);

    // Emit real-time update
    const io = req.app.get('io');
    if (io) {
      io.to(`trip-${tripId}`).emit('trip-updated', {
        id: trip.id,
        status: trip.status,
        driver_id: trip.driver_id,
        driver_name: trip.driver_name
      });
      console.log('📡 Real-time update sent to trip:', tripId);
    }

    res.json({ success: true, message: 'Trip updated successfully' });
  } catch (error) {
    console.error('❌ Error updating trip:', error);
    next(error);
  }
});

// Get all users (admin)
router.get('/users', async (req, res, next) => {
  try {
    const allUsers = Array.from(users.values())
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    const userList = allUsers.map(user => {
      // Count trips for this user
      const userTrips = Array.from(trips.values()).filter(t => t.user_id === user.id);
      const totalSpent = userTrips.reduce((sum, t) => sum + parseFloat(t.total_price || 0), 0);

      return {
        id: user.id,
        name: user.name,
        email: user.email,
        telefono: user.telefono || null,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        totalTrips: userTrips.length,
        totalSpent: totalSpent
      };
    });

    res.json({ success: true, data: userList });
  } catch (error) {
    console.error('❌ Error getting users:', error);
    next(error);
  }
});

module.exports = router;
