const express = require('express');
const router = express.Router();

// Placeholder user routes
router.get('/profile', (req, res) => {
  res.json({ success: true, message: 'User profile endpoint' });
});

module.exports = router;
