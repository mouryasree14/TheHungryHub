const pool = require('../config/db');

exports.getAllRecipes = async (req, res) => {
    try {
        const { search, category, cuisine, mood, difficulty } = req.query;
        let query = `
            SELECT r.*, c.name as category_name, cu.cuisine_name, m.mood_type, u.name as author_name,
            IFNULL(AVG(ra.rating_value), 0) as average_rating, COUNT(ra.rating_id) as review_count
            FROM RECIPE r
            LEFT JOIN CATEGORY c ON r.category_id = c.category_id
            LEFT JOIN CUISINE cu ON r.cuisine_id = cu.cuisine_id
            LEFT JOIN MOOD m ON r.mood_id = m.mood_id
            LEFT JOIN USER u ON r.created_by_user_id = u.user_id
            LEFT JOIN RATING ra ON r.recipe_id = ra.recipe_id
            WHERE 1=1
        `;
        const queryParams = [];

        if (search) {
            query += ` AND r.name LIKE ?`;
            queryParams.push(`%${search}%`);
        }
        if (category) {
            query += ` AND c.name = ?`;
            queryParams.push(category);
        }
        if (cuisine) {
            query += ` AND cu.cuisine_name = ?`;
            queryParams.push(cuisine);
        }
        if (mood) {
            query += ` AND m.mood_type = ?`;
            queryParams.push(mood);
        }
        if (difficulty) {
            query += ` AND r.difficulty = ?`;
            queryParams.push(difficulty);
        }

        query += ` GROUP BY r.recipe_id ORDER BY r.created_at DESC`;

        const [recipes] = await pool.query(query, queryParams);
        res.json(recipes);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching recipes', error: error.message });
    }
};

exports.getRecipeById = async (req, res) => {
    try {
        const [recipes] = await pool.query(`
            SELECT r.*, c.name as category_name, cu.cuisine_name, m.mood_type, u.name as author_name,
            IFNULL(AVG(ra.rating_value), 0) as average_rating, COUNT(ra.rating_id) as review_count
            FROM RECIPE r
            LEFT JOIN CATEGORY c ON r.category_id = c.category_id
            LEFT JOIN CUISINE cu ON r.cuisine_id = cu.cuisine_id
            LEFT JOIN MOOD m ON r.mood_id = m.mood_id
            LEFT JOIN USER u ON r.created_by_user_id = u.user_id
            LEFT JOIN RATING ra ON r.recipe_id = ra.recipe_id
            WHERE r.recipe_id = ?
            GROUP BY r.recipe_id
        `, [req.params.id]);

        if (recipes.length === 0) {
            return res.status(404).json({ message: 'Recipe not found' });
        }

        const recipe = recipes[0];

        // Fetch ingredients
        const [ingredients] = await pool.query(`
            SELECT i.ingredient_name, ri.quantity_desc 
            FROM RECIPE_INGREDIENT ri
            JOIN INGREDIENT i ON ri.ingredient_id = i.ingredient_id
            WHERE ri.recipe_id = ?
        `, [req.params.id]);

        recipe.ingredients = ingredients;

        res.json(recipe);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching recipe', error: error.message });
    }
};

exports.createRecipe = async (req, res) => {
    const connection = await pool.getConnection();
    try {
        const { name, cooking_time, difficulty, prep_notes, steps, category_id, cuisine_id, mood_id, image_url, ingredients } = req.body;

        // Validations
        if (!name) return res.status(400).json({ message: 'Name is required' });
        if (!cooking_time || cooking_time <= 0) return res.status(400).json({ message: 'Cooking time must be > 0' });
        if (!['Easy', 'Medium', 'Hard'].includes(difficulty)) return res.status(400).json({ message: 'Difficulty must be Easy, Medium, or Hard' });

        await connection.beginTransaction();

        const [result] = await connection.query(`
            INSERT INTO RECIPE (name, cooking_time, difficulty, prep_notes, steps, category_id, cuisine_id, mood_id, image_url, created_by_user_id)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        `, [name, cooking_time, difficulty, prep_notes, steps || null, category_id || null, cuisine_id || null, mood_id || null, image_url || null, req.userId]);

        const recipeId = result.insertId;

        // Insert ingredients if provided
        if (ingredients && ingredients.length > 0) {
            for (let ing of ingredients) {
                // Find or create ingredient
                let ingId;
                const [existing] = await connection.query('SELECT ingredient_id FROM INGREDIENT WHERE ingredient_name = ?', [ing.name]);
                if (existing.length > 0) {
                    ingId = existing[0].ingredient_id;
                } else {
                    const [newIng] = await connection.query('INSERT INTO INGREDIENT (ingredient_name) VALUES (?)', [ing.name]);
                    ingId = newIng.insertId;
                }

                await connection.query('INSERT INTO RECIPE_INGREDIENT (recipe_id, ingredient_id, quantity_desc) VALUES (?, ?, ?)', [recipeId, ingId, ing.quantity]);
            }
        }

        await connection.commit();
        res.status(201).json({ message: 'Recipe created successfully', recipeId });

    } catch (error) {
        await connection.rollback();
        res.status(500).json({ message: 'Error creating recipe', error: error.message });
    } finally {
        connection.release();
    }
};

exports.updateRecipe = async (req, res) => {
    try {
        const { name, cooking_time, difficulty, prep_notes, steps, image_url } = req.body;
        const recipeId = req.params.id;

        // Check ownership or admin
        const [recipes] = await pool.query('SELECT created_by_user_id FROM RECIPE WHERE recipe_id = ?', [recipeId]);
        if (recipes.length === 0) return res.status(404).json({ message: 'Recipe not found' });
        
        if (recipes[0].created_by_user_id !== req.userId && req.userRole !== 'admin') {
            return res.status(403).json({ message: 'Not authorized to update this recipe' });
        }

        await pool.query(`
            UPDATE RECIPE SET name = ?, cooking_time = ?, difficulty = ?, prep_notes = ?, steps = ?, image_url = ?
            WHERE recipe_id = ?
        `, [name, cooking_time, difficulty, prep_notes, steps || null, image_url, recipeId]);

        res.json({ message: 'Recipe updated successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error updating recipe', error: error.message });
    }
};

exports.deleteRecipe = async (req, res) => {
    try {
        const recipeId = req.params.id;

        // Check ownership or admin
        const [recipes] = await pool.query('SELECT created_by_user_id FROM RECIPE WHERE recipe_id = ?', [recipeId]);
        if (recipes.length === 0) return res.status(404).json({ message: 'Recipe not found' });
        
        if (recipes[0].created_by_user_id !== req.userId && req.userRole !== 'admin') {
            return res.status(403).json({ message: 'Not authorized to delete this recipe' });
        }

        await pool.query('DELETE FROM RECIPE WHERE recipe_id = ?', [recipeId]);
        res.json({ message: 'Recipe deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting recipe', error: error.message });
    }
};

exports.matchIngredients = async (req, res) => {
    try {
        const { ingredients } = req.body; // Array of ingredient names

        if (!ingredients || !Array.isArray(ingredients) || ingredients.length === 0) {
            return res.status(400).json({ message: 'Please provide an array of ingredients' });
        }

        // Validate ingredients exist in INGREDIENT table
        const placeholders = ingredients.map(() => '?').join(',');
        const [dbIngredients] = await pool.query(`SELECT ingredient_name FROM INGREDIENT WHERE ingredient_name IN (${placeholders})`, ingredients);
        
        const validNames = dbIngredients.map(i => i.ingredient_name.toLowerCase());
        const invalidIngredients = ingredients.filter(i => !validNames.includes(i.toLowerCase()));

        if (invalidIngredients.length > 0) {
            return res.status(400).json({ message: `Invalid ingredients: ${invalidIngredients.join(', ')}` });
        }

        // Find recipes that can be made with these ingredients (or partially)
        // Simple approach: Find recipes where at least one ingredient matches, order by match count
        const query = `
            SELECT r.recipe_id, r.name, r.cooking_time, r.difficulty, r.image_url, COUNT(ri.ingredient_id) as match_count
            FROM RECIPE r
            JOIN RECIPE_INGREDIENT ri ON r.recipe_id = ri.recipe_id
            JOIN INGREDIENT i ON ri.ingredient_id = i.ingredient_id
            WHERE i.ingredient_name IN (${placeholders})
            GROUP BY r.recipe_id
            ORDER BY match_count DESC
        `;

        const [matchedRecipes] = await pool.query(query, ingredients);
        res.json(matchedRecipes);

    } catch (error) {
        res.status(500).json({ message: 'Error matching ingredients', error: error.message });
    }
};
