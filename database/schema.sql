-- The Hungry Hub Database Schema

CREATE DATABASE IF NOT EXISTS hungry_hub;
USE hungry_hub;

-- 1. CATEGORY Table
CREATE TABLE IF NOT EXISTS CATEGORY (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE
);

-- 2. CUISINE Table
CREATE TABLE IF NOT EXISTS CUISINE (
    cuisine_id INT AUTO_INCREMENT PRIMARY KEY,
    cuisine_name VARCHAR(100) NOT NULL UNIQUE
);

-- 3. MOOD Table
CREATE TABLE IF NOT EXISTS MOOD (
    mood_id INT AUTO_INCREMENT PRIMARY KEY,
    mood_type VARCHAR(100) NOT NULL UNIQUE
);

-- 4. INGREDIENT Table
CREATE TABLE IF NOT EXISTS INGREDIENT (
    ingredient_id INT AUTO_INCREMENT PRIMARY KEY,
    ingredient_name VARCHAR(150) NOT NULL UNIQUE
);

-- 5. USER Table
CREATE TABLE IF NOT EXISTS USER (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    preference ENUM('Vegetarian', 'Vegan', 'Non-Vegetarian', 'Pescatarian', 'Any') DEFAULT 'Any',
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. RECIPE Table
CREATE TABLE IF NOT EXISTS RECIPE (
    recipe_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    cooking_time INT NOT NULL CHECK (cooking_time > 0), -- in minutes
    difficulty ENUM('Easy', 'Medium', 'Hard') NOT NULL,
    prep_notes TEXT,
    category_id INT,
    cuisine_id INT,
    mood_id INT,
    image_url VARCHAR(255) DEFAULT 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=800',
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES CATEGORY(category_id) ON DELETE SET NULL,
    FOREIGN KEY (cuisine_id) REFERENCES CUISINE(cuisine_id) ON DELETE SET NULL,
    FOREIGN KEY (mood_id) REFERENCES MOOD(mood_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by) REFERENCES USER(user_id) ON DELETE SET NULL
);

-- 7. RATING Table
CREATE TABLE IF NOT EXISTS RATING (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    rating_value INT NOT NULL CHECK (rating_value BETWEEN 1 AND 5),
    comment TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES RECIPE(recipe_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_recipe_rating (user_id, recipe_id)
);

-- 8. USER_INGREDIENT Table
CREATE TABLE IF NOT EXISTS USER_INGREDIENT (
    input_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity VARCHAR(100),
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES INGREDIENT(ingredient_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_ingredient (user_id, ingredient_id)
);

-- 9. MEAL_PLANNER Table
CREATE TABLE IF NOT EXISTS MEAL_PLANNER (
    planner_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    week VARCHAR(50) NOT NULL, -- e.g., '2023-W42'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES USER(user_id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_week (user_id, week)
);

-- 10. RECIPE_INGREDIENT Table
CREATE TABLE IF NOT EXISTS RECIPE_INGREDIENT (
    recipe_id INT NOT NULL,
    ingredient_id INT NOT NULL,
    quantity_desc VARCHAR(100),
    PRIMARY KEY (recipe_id, ingredient_id),
    FOREIGN KEY (recipe_id) REFERENCES RECIPE(recipe_id) ON DELETE CASCADE,
    FOREIGN KEY (ingredient_id) REFERENCES INGREDIENT(ingredient_id) ON DELETE CASCADE
);

-- 11. MEAL_PLAN_RECIPE Table
CREATE TABLE IF NOT EXISTS MEAL_PLAN_RECIPE (
    planner_id INT NOT NULL,
    recipe_id INT NOT NULL,
    day_of_week ENUM('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday') NOT NULL,
    meal_type ENUM('Breakfast', 'Lunch', 'Dinner', 'Snack') NOT NULL,
    PRIMARY KEY (planner_id, recipe_id, day_of_week, meal_type),
    FOREIGN KEY (planner_id) REFERENCES MEAL_PLANNER(planner_id) ON DELETE CASCADE,
    FOREIGN KEY (recipe_id) REFERENCES RECIPE(recipe_id) ON DELETE CASCADE
);

-- Indexes for performance
CREATE INDEX idx_recipe_name ON RECIPE(name);
CREATE INDEX idx_ingredient_name ON INGREDIENT(ingredient_name);
CREATE INDEX idx_user_email ON USER(email);
CREATE INDEX idx_recipe_difficulty ON RECIPE(difficulty);

-- Insert Sample Data
INSERT IGNORE INTO CATEGORY (name) VALUES ('Breakfast'), ('Lunch'), ('Dinner'), ('Dessert'), ('Snack');
INSERT IGNORE INTO CUISINE (cuisine_name) VALUES ('Italian'), ('Mexican'), ('Indian'), ('Chinese'), ('American');
INSERT IGNORE INTO MOOD (mood_type) VALUES ('Comforting'), ('Healthy'), ('Quick & Easy'), ('Festive'), ('Romantic');

INSERT IGNORE INTO INGREDIENT (ingredient_name) VALUES 
('Tomato'), ('Onion'), ('Garlic'), ('Pasta'), ('Chicken Breast'), 
('Olive Oil'), ('Salt'), ('Pepper'), ('Basil'), ('Mozzarella Cheese'),
('Rice'), ('Black Beans'), ('Tortilla'), ('Cheddar Cheese'), ('Ground Beef');

-- Insert a test admin user (password: Admin123!)
-- Hash generated using bcrypt for 'Admin123!' -> $2b$10$wO3F/6wzZ.UvBq2wW0Kj9.g.c0c.d2y.Y/u.c2O.e/e.x/w.g.P.K (example)
INSERT IGNORE INTO USER (name, email, password, preference, role) VALUES 
('Admin User', 'admin@hungryhub.com', '$2b$10$EPJq20e2x0b04r16LftXw.gQ42168vTf4uA3y1Dq/3A3J5bQ6yKUK', 'Any', 'admin'),
('John Doe', 'john@example.com', '$2b$10$EPJq20e2x0b04r16LftXw.gQ42168vTf4uA3y1Dq/3A3J5bQ6yKUK', 'Non-Vegetarian', 'user');

INSERT IGNORE INTO RECIPE (name, cooking_time, difficulty, prep_notes, category_id, cuisine_id, mood_id, created_by) VALUES 
('Classic Tomato Basil Pasta', 25, 'Easy', 'Boil pasta, sauté garlic and tomatoes, mix with basil.', 3, 1, 1, 1),
('Chicken Burrito Bowl', 30, 'Medium', 'Cook rice, grill chicken, mix with beans and cheese.', 2, 2, 2, 1);

INSERT IGNORE INTO RECIPE_INGREDIENT (recipe_id, ingredient_id, quantity_desc) VALUES 
(1, 4, '200g'), (1, 1, '3 medium'), (1, 3, '2 cloves'), (1, 9, '1 handful'), (1, 6, '2 tbsp'),
(2, 5, '250g'), (2, 11, '1 cup'), (2, 12, '1/2 cup'), (2, 14, '50g');
