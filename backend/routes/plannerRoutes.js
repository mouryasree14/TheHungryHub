const express = require('express');
const router = express.Router();
const plannerController = require('../controllers/plannerController');
const { verifyToken } = require('../middleware/authMiddleware');

router.post('/', verifyToken, plannerController.addMealPlan);
router.get('/:userId', verifyToken, plannerController.getMealPlan);
router.delete('/:id', verifyToken, plannerController.deleteMealPlan);

module.exports = router;
