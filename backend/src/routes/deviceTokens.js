const express = require('express');
const router = express.Router();

// In-memory device token storage (development)
const deviceTokens = new Map();

router.post('/', async (req, res) => {
  const body = req.body || {};
  const userId = body.userId || body.user_id;
  const deviceToken = body.deviceToken || body.device_token;
  const platform = body.platform || 'ios';
  const appVersion = body.appVersion || body.app_version;
  const deviceModel = body.deviceModel || body.device_model;
  const osVersion = body.osVersion || body.os_version;
  const timestamp = body.timestamp;

  if (!userId || !deviceToken) {
    return res.status(400).json({
      success: false,
      message: 'userId and deviceToken are required'
    });
  }

  const tokenKey = `${userId}:${deviceToken}`;
  deviceTokens.set(tokenKey, {
    userId,
    token: deviceToken,
    platform,
    appVersion: appVersion || null,
    deviceModel: deviceModel || null,
    osVersion: osVersion || null,
    timestamp: timestamp || Date.now(),
    createdAt: new Date().toISOString()
  });

  res.json({ success: true });
});

module.exports = router;
module.exports.deviceTokens = deviceTokens;
