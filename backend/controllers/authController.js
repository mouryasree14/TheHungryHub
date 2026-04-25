const pool = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
    try {
        const { name, email, password, preference } = req.body;

        // Validations
        if (!name) return res.status(400).json({ message: 'Name is required' });
        if (!email || !/^\S+@\S+\.\S+$/.test(email)) return res.status(400).json({ message: 'Valid email is required' });
        if (!password || password.length < 6) return res.status(400).json({ message: 'Password must be at least 6 characters' });

        // Check if user exists
        const [existingUsers] = await pool.query('SELECT * FROM USER WHERE email = ?', [email]);
        if (existingUsers.length > 0) {
            return res.status(400).json({ message: 'Email is already registered' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // Insert user
        const pref = preference || 'Any';
        const [result] = await pool.query(
            'INSERT INTO USER (name, email, password, preference, role) VALUES (?, ?, ?, ?, ?)',
            [name, email, hashedPassword, pref, 'user']
        );

        res.status(201).json({ message: 'User registered successfully', userId: result.insertId });

    } catch (error) {
        res.status(500).json({ message: 'Error registering user', error: error.message });
    }
};

exports.login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ message: 'Email and password are required' });
        }

        const [users] = await pool.query('SELECT * FROM USER WHERE email = ?', [email]);
        
        if (users.length === 0) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const user = users[0];
        const isMatch = await bcrypt.compare(password, user.password);

        if (!isMatch) {
            return res.status(401).json({ message: 'Invalid credentials' });
        }

        const token = jwt.sign(
            { id: user.user_id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.status(200).json({
            message: 'Login successful',
            token,
            user: {
                id: user.user_id,
                name: user.name,
                email: user.email,
                role: user.role,
                preference: user.preference
            }
        });

    } catch (error) {
        res.status(500).json({ message: 'Error logging in', error: error.message });
    }
};
