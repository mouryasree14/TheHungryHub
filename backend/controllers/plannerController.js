const pool = require('../config/db');

exports.addMealPlan = async (req, res) => {
    const connection = await pool.getConnection();
    try {
        const { week, recipe_id, day_of_week, meal_type } = req.body;

        if (!week || !recipe_id || !day_of_week || !meal_type) {
            return res.status(400).json({ message: 'Missing required fields' });
        }

        await connection.beginTransaction();

        // Check if planner for this week exists
        let plannerId;
        const [planners] = await connection.query('SELECT planner_id FROM MEAL_PLANNER WHERE user_id = ? AND week = ?', [req.userId, week]);
        
        if (planners.length > 0) {
            plannerId = planners[0].planner_id;
        } else {
            const [newPlanner] = await connection.query('INSERT INTO MEAL_PLANNER (user_id, week) VALUES (?, ?)', [req.userId, week]);
            plannerId = newPlanner.insertId;
        }

        // Check for duplicates (No duplicate recipes same week)
        const [existingPlan] = await connection.query('SELECT * FROM MEAL_PLAN_RECIPE WHERE planner_id = ? AND recipe_id = ?', [plannerId, recipe_id]);
        if (existingPlan.length > 0) {
            await connection.rollback();
            return res.status(400).json({ message: 'Recipe already exists in this week\'s planner' });
        }

        // Insert into meal plan
        await connection.query(
            'INSERT INTO MEAL_PLAN_RECIPE (planner_id, recipe_id, day_of_week, meal_type) VALUES (?, ?, ?, ?)',
            [plannerId, recipe_id, day_of_week, meal_type]
        );

        await connection.commit();
        res.status(201).json({ message: 'Meal plan added successfully' });

    } catch (error) {
        await connection.rollback();
        res.status(500).json({ message: 'Error adding meal plan', error: error.message });
    } finally {
        connection.release();
    }
};

exports.getMealPlan = async (req, res) => {
    try {
        const userId = req.params.userId;
        const week = req.query.week;

        if (parseInt(userId) !== req.userId && req.userRole !== 'admin') {
            return res.status(403).json({ message: 'Unauthorized access' });
        }

        let query = `
            SELECT mp.planner_id, mp.week, mpr.day_of_week, mpr.meal_type, r.recipe_id, r.name, r.image_url 
            FROM MEAL_PLANNER mp
            JOIN MEAL_PLAN_RECIPE mpr ON mp.planner_id = mpr.planner_id
            JOIN RECIPE r ON mpr.recipe_id = r.recipe_id
            WHERE mp.user_id = ?
        `;
        const queryParams = [userId];

        if (week) {
            query += ' AND mp.week = ?';
            queryParams.push(week);
        }

        query += ' ORDER BY FIELD(mpr.day_of_week, "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday")';

        const [plans] = await pool.query(query, queryParams);
        res.json(plans);

    } catch (error) {
        res.status(500).json({ message: 'Error fetching meal plans', error: error.message });
    }
};

exports.deleteMealPlan = async (req, res) => {
    try {
        // Here id could be a specific MEAL_PLAN_RECIPE composite key, but for simplicity, let's assume we pass planner_id and recipe_id
        const { planner_id, recipe_id } = req.body; // or delete by planner_id only
        
        // Ensure user owns planner
        const [planners] = await pool.query('SELECT user_id FROM MEAL_PLANNER WHERE planner_id = ?', [req.params.id]);
        if (planners.length === 0) return res.status(404).json({ message: 'Planner not found' });
        
        if (planners[0].user_id !== req.userId && req.userRole !== 'admin') {
            return res.status(403).json({ message: 'Unauthorized' });
        }

        await pool.query('DELETE FROM MEAL_PLANNER WHERE planner_id = ?', [req.params.id]);
        res.json({ message: 'Meal plan deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting meal plan', error: error.message });
    }
};
