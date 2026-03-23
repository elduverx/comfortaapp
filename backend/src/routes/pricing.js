const express = require('express');
const router = express.Router();

// Calculate trip pricing
router.post('/calculate', (req, res) => {
  const { distanceKm } = req.body;
  
  const BASE_FARE = 7.50;
  const MINIMUM_FARE_LONG = 15.00;
  const AIRPORT_SURCHARGE = 8.00;
  
  let pricePerKm;
  if (distanceKm < 50) {
    pricePerKm = 1.50;
  } else if (distanceKm < 100) {
    pricePerKm = 1.20;
  } else {
    pricePerKm = 1.10;
  }
  
  let fare = distanceKm * pricePerKm;
  
  if (distanceKm >= 10) {
    fare = Math.max(fare, MINIMUM_FARE_LONG);
  } else {
    fare = Math.max(fare, BASE_FARE);
  }
  
  const hasAirport = req.body.includesAirport || false;
  if (hasAirport) {
    fare += AIRPORT_SURCHARGE;
  }
  
  fare = Math.round(fare * 100) / 100;
  
  res.json({
    success: true,
    pricing: {
      distance: distanceKm,
      basePrice: fare,
      totalPrice: fare,
      pricePerKm
    }
  });
});

module.exports = router;
