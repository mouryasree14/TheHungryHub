const pool = require('../config/db');

exports.getAllUsers = async (req, res) => {
    try {
        const [users] = await pool.query('SELECT user_id, name, email, preference, role, created_at FROM USER ORDER BY created_at DESC');
        res.json(users);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching users', error: error.message });
    }
};

exports.deleteUser = async (req, res) => {
    try {
        const userId = req.params.id;

        // Prevent admin from deleting themselves
        if (parseInt(userId) === req.userId) {
            return res.status(400).json({ message: 'Admins cannot delete their own account' });
        }

        await pool.query('DELETE FROM USER WHERE user_id = ?', [userId]);
        res.json({ message: 'User deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting user', error: error.message });
    }
};
