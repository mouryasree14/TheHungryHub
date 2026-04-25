const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const { verifyToken, isAdmin } = require('../middleware/authMiddleware');

router.get('/users', verifyToken, isAdmin, adminController.getAllUsers);
router.delete('/user/:id', verifyToken, isAdmin, adminController.deleteUser);

module.exports = router;
