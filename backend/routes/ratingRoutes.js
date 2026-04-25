const express = require('express');
const router = express.Router();
const ratingController = require('../controllers/ratingController');
const { verifyToken } = require('../middleware/authMiddleware');

router.post('/', verifyToken, ratingController.addRating);
router.get('/:recipeId', ratingController.getRecipeRatings);

module.exports = router;
