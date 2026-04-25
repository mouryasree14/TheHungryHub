const express = require('express');
const router = express.Router();
const recipeController = require('../controllers/recipeController');
const { verifyToken } = require('../middleware/authMiddleware');

router.get('/', recipeController.getAllRecipes);
router.get('/:id', recipeController.getRecipeById);
router.post('/', verifyToken, recipeController.createRecipe);
router.put('/:id', verifyToken, recipeController.updateRecipe);
router.delete('/:id', verifyToken, recipeController.deleteRecipe);

// Ingredient Search Route
router.post('/match-ingredients', recipeController.matchIngredients);

module.exports = router;
