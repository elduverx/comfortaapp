const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

// Reference to users from auth.js (shared in-memory storage)
// In production, this would be a database
const users = require('./auth').users;

// Middleware to authenticate requests
const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        message: 'No token provided'
      });
    }

    const token = authHeader.substring(7);
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret-key');

    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({
      message: 'Invalid token'
    });
  }
};

// Get current user profile
router.get('/', authenticate, (req, res) => {
  try {
    const userData = users.get(req.user.id);

    if (!userData) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    res.json({
      profile: {
        id: userData.id,
        email: userData.email,
        name: userData.name,
        telefono: userData.telefono || null,
        image: null,
        emailVerified: userData.emailVerified ? "true" : "false"
      }
    });
  } catch (error) {
    console.error('❌ Get profile error:', error);
    res.status(500).json({
      message: 'Error fetching profile'
    });
  }
});

// Update user profile
router.patch('/', authenticate, async (req, res) => {
  try {
    const { name, telefono, email } = req.body;

    const userData = users.get(req.user.id);

    if (!userData) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    // Update fields if provided
    if (name !== undefined) userData.name = name;
    if (telefono !== undefined) userData.telefono = telefono;
    if (email !== undefined) userData.email = email;

    userData.updatedAt = new Date().toISOString();
    users.set(req.user.id, userData);

    console.log('✅ Profile updated:', req.user.id);

    res.json({
      profile: {
        id: userData.id,
        email: userData.email,
        name: userData.name,
        telefono: userData.telefono || null,
        image: null,
        emailVerified: userData.emailVerified ? "true" : "false"
      }
    });
  } catch (error) {
    console.error('❌ Update profile error:', error);
    res.status(500).json({
      message: 'Error updating profile'
    });
  }
});

module.exports = router;
