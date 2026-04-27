const pool = require('../config/db');

exports.getProfile = async (req, res) => {
    try {
        const [users] = await pool.query(
            'SELECT user_id, name, email, preference, role, created_at FROM USER WHERE user_id = ?',
            [req.userId]
        );
        
        if (users.length === 0) {
            return res.status(404).json({ message: 'User not found' });
        }
        res.json(users[0]);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching profile', error: error.message });
    }
};

exports.updateProfile = async (req, res) => {
    try {
        const { name, preference } = req.body;
        
        if (!name) {
            return res.status(400).json({ message: 'Name is required' });
        }
        
        const pref = preference || 'Any';

        await pool.query(
            'UPDATE USER SET name = ?, preference = ? WHERE user_id = ?',
            [name, pref, req.userId]
        );
        
        res.json({ message: 'Profile updated successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error updating profile', error: error.message });
    }
};

exports.getMyRecipes = async (req, res) => {
    try {
        const [recipes] = await pool.query(
            `SELECT r.*, c.name as category_name, cu.cuisine_name, 
             IFNULL(AVG(ra.rating_value), 0) as average_rating, COUNT(ra.rating_id) as review_count
             FROM RECIPE r
             LEFT JOIN CATEGORY c ON r.category_id = c.category_id
             LEFT JOIN CUISINE cu ON r.cuisine_id = cu.cuisine_id
             LEFT JOIN RATING ra ON r.recipe_id = ra.recipe_id
             WHERE r.created_by_user_id = ?
             GROUP BY r.recipe_id
             ORDER BY r.created_at DESC`,
            [req.userId]
        );
        res.json(recipes);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching my recipes', error: error.message });
    }
};
