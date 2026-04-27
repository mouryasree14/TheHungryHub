const pool = require('../config/db');

exports.addRating = async (req, res) => {
    try {
        const { recipe_id, rating_value, review_text } = req.body;

        if (!recipe_id || !rating_value) {
            return res.status(400).json({ message: 'Recipe ID and rating value are required' });
        }

        if (rating_value < 1 || rating_value > 5) {
            return res.status(400).json({ message: 'Rating must be between 1 and 5' });
        }

        // Insert or update rating (Upsert approach)
        await pool.query(`
            INSERT INTO RATING (user_id, recipe_id, rating_value, review_text) 
            VALUES (?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE rating_value = VALUES(rating_value), review_text = VALUES(review_text)
        `, [req.userId, recipe_id, rating_value, review_text]);

        res.status(201).json({ message: 'Rating added successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error adding rating', error: error.message });
    }
};

exports.getRecipeRatings = async (req, res) => {
    try {
        const [ratings] = await pool.query(`
            SELECT r.rating_id, r.rating_value, r.review_text, r.created_at, u.name as user_name 
            FROM RATING r
            JOIN USER u ON r.user_id = u.user_id
            WHERE r.recipe_id = ?
            ORDER BY r.created_at DESC
        `, [req.params.recipeId]);

        res.json(ratings);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching ratings', error: error.message });
    }
};
