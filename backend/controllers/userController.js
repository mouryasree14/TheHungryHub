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
