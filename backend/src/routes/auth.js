const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');

// In-memory user storage (for development without PostgreSQL)
const users = new Map();

// Helper to decode Apple identity token (without verification for simplicity)
function decodeAppleToken(identityToken) {
  try {
    const parts = identityToken.split('.');
    if (parts.length !== 3) {
      throw new Error('Invalid token format');
    }

    const payload = JSON.parse(Buffer.from(parts[1], 'base64').toString());
    return payload;
  } catch (error) {
    console.error('Error decoding Apple token:', error);
    return null;
  }
}

// Apple Sign In - Login/Register
router.post('/login/apple', async (req, res) => {
  try {
    const { identityToken, user, authorizationCode } = req.body;

    console.log('📱 Apple Sign In request received');
    console.log('Identity Token:', identityToken ? 'Present' : 'Missing');
    console.log('Identity Token value:', identityToken);
    console.log('User data:', user);
    console.log('Full request body:', JSON.stringify(req.body, null, 2));

    if (!identityToken) {
      return res.status(400).json({
        success: false,
        message: 'Identity token is required'
      });
    }

    // Decode Apple identity token
    const applePayload = decodeAppleToken(identityToken);

    if (!applePayload) {
      return res.status(400).json({
        success: false,
        message: 'Invalid identity token'
      });
    }

    console.log('✅ Apple token decoded:', {
      sub: applePayload.sub,
      email: applePayload.email,
      email_verified: applePayload.email_verified
    });

    // Extract user info
    const appleUserId = applePayload.sub;
    const email = applePayload.email;
    const emailVerified = applePayload.email_verified;

    // Check if user exists or create new
    let userData = users.get(appleUserId);

    if (!userData) {
      // New user - create record
      userData = {
        id: appleUserId,
        email: email,
        name: user?.name?.firstName || user?.name?.lastName
          ? `${user.name.firstName || ''} ${user.name.lastName || ''}`.trim()
          : null,
        telefono: null,
        appleUserId: appleUserId,
        emailVerified: emailVerified,
        role: 'user',
        createdAt: new Date().toISOString(),
        updatedAt: new Date().toISOString()
      };

      users.set(appleUserId, userData);
      console.log('✅ New user created:', userData.id);
    } else {
      // Existing user - update last login
      userData.updatedAt = new Date().toISOString();
      users.set(appleUserId, userData);
      console.log('✅ Existing user logged in:', userData.id);
    }

    // Generate JWT access token
    const accessToken = jwt.sign(
      {
        id: userData.id,
        email: userData.email,
        role: userData.role
      },
      process.env.JWT_SECRET || 'default-secret-key',
      { expiresIn: '1h' }
    );

    // Generate refresh token (longer expiry)
    const refreshToken = jwt.sign(
      {
        id: userData.id,
        type: 'refresh'
      },
      process.env.JWT_SECRET || 'default-secret-key',
      { expiresIn: '30d' }
    );

    console.log('✅ JWT tokens generated');

    // Return response matching iOS app expectations
    res.json({
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: {
        id: userData.id,
        email: userData.email,
        name: userData.name,
        telefono: null
      }
    });

  } catch (error) {
    console.error('❌ Apple Sign In error:', error);
    res.status(500).json({
      success: false,
      message: 'Authentication failed',
      error: error.message
    });
  }
});

// Refresh token endpoint
router.post('/refresh', async (req, res) => {
  try {
    const { refreshToken: oldRefreshToken } = req.body;

    if (!oldRefreshToken) {
      return res.status(400).json({
        message: 'Refresh token is required'
      });
    }

    // Verify refresh token
    const decoded = jwt.verify(oldRefreshToken, process.env.JWT_SECRET || 'default-secret-key');

    if (decoded.type !== 'refresh') {
      return res.status(401).json({
        message: 'Invalid refresh token'
      });
    }

    const userData = users.get(decoded.id);

    if (!userData) {
      return res.status(404).json({
        message: 'User not found'
      });
    }

    // Generate new tokens
    const accessToken = jwt.sign(
      {
        id: userData.id,
        email: userData.email,
        role: userData.role
      },
      process.env.JWT_SECRET || 'default-secret-key',
      { expiresIn: '1h' }
    );

    const refreshToken = jwt.sign(
      {
        id: userData.id,
        type: 'refresh'
      },
      process.env.JWT_SECRET || 'default-secret-key',
      { expiresIn: '30d' }
    );

    res.json({
      accessToken: accessToken,
      refreshToken: refreshToken
    });

  } catch (error) {
    console.error('❌ Refresh token error:', error);
    res.status(401).json({
      message: 'Invalid or expired refresh token'
    });
  }
});

// Logout endpoint
router.post('/logout', async (req, res) => {
  // For now, just return success since we're using JWT (stateless)
  // In production, you would add the refresh token to a blacklist
  res.json({
    message: 'Logged out successfully'
  });
});

module.exports = router;
module.exports.users = users;
