-- The Hungry Hub Database Schema

CREATE DATABASE IF NOT EXISTS hungry_hub;
USE hungry_hub;

-- MIGRATION STATEMENTS FOR EXISTING DATABASES (Run these manually if you already have data)
-- ALTER TABLE RECIPE CHANGE created_by created_by_user_id INT;
-- ALTER TABLE RECIPE ADD COLUMN IF NOT EXISTS steps TEXT AFTER prep_notes;
-- ALTER TABLE RATING CHANGE comment review_text TEXT;

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
    steps TEXT, -- Added for preparation steps
    category_id INT,
    cuisine_id INT,
    mood_id INT,
    image_url VARCHAR(255) DEFAULT 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=800',
    created_by_user_id INT, -- Renamed from created_by
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES CATEGORY(category_id) ON DELETE SET NULL,
    FOREIGN KEY (cuisine_id) REFERENCES CUISINE(cuisine_id) ON DELETE SET NULL,
    FOREIGN KEY (mood_id) REFERENCES MOOD(mood_id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_user_id) REFERENCES USER(user_id) ON DELETE SET NULL
);

-- 7. RATING Table
CREATE TABLE IF NOT EXISTS RATING (
    rating_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    recipe_id INT NOT NULL,
    rating_value INT NOT NULL CHECK (rating_value BETWEEN 1 AND 5),
    review_text TEXT, -- Renamed from comment
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

-- =====================================================
-- VALIDATION TRIGGERS FOR INVALID RECIPE / INGREDIENTS
-- Add this section BEFORE Insert Sample Data
-- =====================================================

DROP TRIGGER IF EXISTS trg_recipe_insert;
DROP TRIGGER IF EXISTS trg_recipe_update;
DROP TRIGGER IF EXISTS trg_ingredient_insert;
DROP TRIGGER IF EXISTS trg_ingredient_update;

DELIMITER $$

-- -------------------------------------------------
-- RECIPE NAME VALIDATION BEFORE INSERT
-- -------------------------------------------------
CREATE TRIGGER trg_recipe_insert
BEFORE INSERT ON RECIPE
FOR EACH ROW
BEGIN
    IF LOWER(NEW.name) REGEXP
    'trash|garbage|waste|sewage|mud|dirt|poison|toxic|plastic|rubber|glass|stone|dust|soap|detergent|acid|battery|cement|urine|feces|stool|vomit|blood|dead|rotten|spoiled|infected'
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Recipe Name! Please enter valid food recipe.';
    END IF;
END$$

-- -------------------------------------------------
-- RECIPE NAME VALIDATION BEFORE UPDATE
-- -------------------------------------------------
CREATE TRIGGER trg_recipe_update
BEFORE UPDATE ON RECIPE
FOR EACH ROW
BEGIN
    IF LOWER(NEW.name) REGEXP
    'trash|garbage|waste|sewage|mud|dirt|poison|toxic|plastic|rubber|glass|stone|dust|soap|detergent|acid|battery|cement|urine|feces|stool|vomit|blood|dead|rotten|spoiled|infected'
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Recipe Name! Update rejected.';
    END IF;
END$$

-- -------------------------------------------------
-- INGREDIENT VALIDATION BEFORE INSERT
-- -------------------------------------------------
CREATE TRIGGER trg_ingredient_insert
BEFORE INSERT ON INGREDIENT
FOR EACH ROW
BEGIN
    IF LOWER(NEW.ingredient_name) REGEXP
    'trash|garbage|waste|sewage|mud|dirt|poison|toxic|plastic|rubber|glass|stone|dust|soap|detergent|acid|battery|cement|urine|feces|stool|vomit|blood|dead|rotten|spoiled|infected'
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Ingredient Name!';
    END IF;
END$$

-- -------------------------------------------------
-- INGREDIENT VALIDATION BEFORE UPDATE
-- -------------------------------------------------
CREATE TRIGGER trg_ingredient_update
BEFORE UPDATE ON INGREDIENT
FOR EACH ROW
BEGIN
    IF LOWER(NEW.ingredient_name) REGEXP
    'trash|garbage|waste|sewage|mud|dirt|poison|toxic|plastic|rubber|glass|stone|dust|soap|detergent|acid|battery|cement|urine|feces|stool|vomit|blood|dead|rotten|spoiled|infected'
    THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid Ingredient Name! Update rejected.';
    END IF;
END$$

DELIMITER ;

-- Indexes for performance (Commented out to prevent duplicate key errors on existing DB)
-- CREATE INDEX idx_recipe_name ON RECIPE(name);
-- CREATE INDEX idx_ingredient_name ON INGREDIENT(ingredient_name);
-- CREATE INDEX idx_user_email ON USER(email);
-- CREATE INDEX idx_recipe_difficulty ON RECIPE(difficulty);

-- Insert Sample Data
INSERT IGNORE INTO CATEGORY (name) VALUES ('Breakfast'), ('Lunch'), ('Dinner'), ('Dessert'), ('Snack');
INSERT IGNORE INTO CUISINE (cuisine_name) VALUES ('Italian'), ('Mexican'), ('Indian'), ('Chinese'), ('American'), ('Continental');
INSERT IGNORE INTO MOOD (mood_type) VALUES ('Comforting'), ('Healthy'), ('Quick & Easy'), ('Festive'), ('Romantic');

-- Insert a test admin user and normal users
INSERT IGNORE INTO USER (user_id, name, email, password, preference, role) VALUES 
(1, 'Admin User', 'admin@hungryhub.com', '$2b$10$EPJq20e2x0b04r16LftXw.gQ42168vTf4uA3y1Dq/3A3J5bQ6yKUK', 'Any', 'admin'),
(2, 'John Doe', 'john@example.com', '$2b$10$EPJq20e2x0b04r16LftXw.gQ42168vTf4uA3y1Dq/3A3J5bQ6yKUK', 'Non-Vegetarian', 'user'),
(3, 'Mouryaaa', 'mourya@example.com', '$2b$10$EPJq20e2x0b04r16LftXw.gQ42168vTf4uA3y1Dq/3A3J5bQ6yKUK', 'Vegetarian', 'user'),
(4, 'Anushka', 'anushka@example.com', '$2b$10$EPJq20e2x0b04r16LftXw.gQ42168vTf4uA3y1Dq/3A3J5bQ6yKUK', 'Vegan', 'user');

-- Insert comprehensive ingredients
-- Insert comprehensive ingredients (Updated with New Hard Recipe Ingredients)

INSERT IGNORE INTO INGREDIENT (ingredient_name) VALUES
('Tomato'),
('Onion'),
('Garlic'),
('Pasta'),
('Chicken Breast'),
('Olive Oil'),
('Salt'),
('Pepper'),
('Basil'),
('Mozzarella Cheese'),
('Rice'),
('Black Beans'),
('Tortilla'),
('Cheddar Cheese'),
('Ground Beef'),
('Eggs'),
('Milk'),
('Flour'),
('Butter'),
('Sugar'),
('Paneer'),
('Garam Masala'),
('Turmeric'),
('Ginger'),
('Cumin'),
('Soy Sauce'),
('Tofu'),
('Noodles'),
('Bell Pepper'),
('Carrot'),
('Potato'),
('Mustard Seeds'),
('Pizza Base'),
('Cream'),
('Fish'),
('Lemon'),
('Macaroni'),
('Lettuce'),
('Burger Bun'),
('Patty'),
('Beans'),
('Peas'),
('Nachos'),
('Cabbage'),
('Spring Roll Wrapper'),
('Sesame Seeds'),
('Rice Flour'),
('Custard Powder'),
('Apple'),
('Banana'),
('Coffee'),
('Biscuits'),
('Cocoa Powder'),
('Taco Shell'),
('Waffle Mix'),
('Syrup'),
('Chili Flakes'),
('Yogurt'),
('Vegetable Oil'),
('Chicken'),
('Cheese'),
('Bread'),
('Urad Dal'),
('Green Chilli'),
('Lasagna Sheets'),
('Tomato Sauce'),
('Mushroom'),
('Pastry Sheet'),
('Duck'),
('Honey'),
('Cream Cheese'),
('Moong Dal'),
('Ricotta Cheese'),
('Corn Flour'),
('Corn Husk'),
('Lotus Paste'),
('Egg Yolk'),
('Beef');


-- Insert Huge Recipe Dataset with matching images

INSERT IGNORE INTO RECIPE
(recipe_id, name, cooking_time, difficulty, prep_notes, steps, category_id, cuisine_id, mood_id, image_url, created_by_user_id)
VALUES

-- =========================
-- BREAKFAST
-- =========================

(11,'Masala Dosa',25,'Hard','South Indian crispy breakfast',
'1. Spread batter on hot tawa. 2. Add potato masala. 3. Fold and serve.',
1,3,1,'https://images.unsplash.com/photo-1589301760014-d929f39ce9b1?auto=format&fit=crop&q=80&w=800',1),

(12,'Cheese Omelette Bruschetta',15,'Easy','Italian style breakfast toast',
'1. Toast bread. 2. Make omelette. 3. Add tomato topping.',
1,1,3,'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&q=80&w=800',1),

(13,'Breakfast Burrito',20,'Easy','Quick Mexican breakfast',
'1. Scramble eggs. 2. Fill tortilla. 3. Roll and serve.',
1,2,3,'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?auto=format&fit=crop&q=80&w=800',1),

(14,'Pancakes',20,'Easy','Soft continental pancakes',
'1. Mix batter. 2. Cook on pan. 3. Serve with syrup.',
1,6,1,'https://images.unsplash.com/photo-1528207776546-365bb710ee93?auto=format&fit=crop&q=80&w=800',1),

(15,'Vegetable Noodles',20,'Easy','Chinese breakfast noodles',
'1. Boil noodles. 2. Stir fry vegetables. 3. Toss with sauce.',
1,4,3,'https://images.unsplash.com/photo-1612929633738-8fe44f7ec841?auto=format&fit=crop&q=80&w=800',1),

(16,'Waffles',25,'Medium','American classic waffles',
'1. Make batter. 2. Cook in waffle maker. 3. Serve hot.',
1,5,1,'https://images.unsplash.com/photo-1562376552-0d160a2f238d?auto=format&fit=crop&q=80&w=800',1),

(41,'Medu Vada',50,'Hard','Crispy South Indian breakfast',
'1. Soak urad dal. 2. Grind batter. 3. Shape vada. 4. Deep fry.',
1,3,1,'https://images.unsplash.com/photo-1606491956689-2ea866880c84?auto=format&fit=crop&q=80&w=800',1),

-- =========================
-- LUNCH
-- =========================

(17,'Veg Biryani',40,'Hard','Indian rice lunch',
'1. Cook vegetables. 2. Add rice. 3. Dum cook.',
2,3,4,'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?auto=format&fit=crop&q=80&w=800',1),

(18,'Pasta Arrabiata',25,'Easy','Spicy Italian pasta',
'1. Boil pasta. 2. Prepare sauce. 3. Mix together.',
2,1,3,'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?auto=format&fit=crop&q=80&w=800',1),

(19,'Veg Quesadilla',20,'Easy','Cheesy Mexican lunch',
'1. Fill tortilla. 2. Toast both sides. 3. Cut and serve.',
2,2,3,'https://images.unsplash.com/photo-1618040996337-56904b7850b9?auto=format&fit=crop&q=80&w=800',1),

(20,'Grilled Chicken Salad',30,'Medium','Healthy continental lunch',
'1. Grill chicken. 2. Chop veggies. 3. Mix and serve.',
2,6,2,'https://images.unsplash.com/photo-1546793665-c74683f339c1?auto=format&fit=crop&q=80&w=800',1),

(21,'Fried Rice',20,'Easy','Chinese classic lunch',
'1. Fry vegetables. 2. Add rice. 3. Toss with soy sauce.',
2,4,3,'https://images.unsplash.com/photo-1603133872878-684f208fb84b?auto=format&fit=crop&q=80&w=800',1),

(22,'Burger Meal',30,'Medium','American burger lunch',
'1. Cook patty. 2. Toast bun. 3. Assemble burger.',
2,5,1,'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&q=80&w=800',1),

(42,'Lasagna',60,'Hard','Classic layered Italian pasta',
'1. Prepare sauces. 2. Layer sheets. 3. Add cheese. 4. Bake.',
2,1,4,'https://images.unsplash.com/photo-1619895092538-128341789043?auto=format&fit=crop&q=80&w=800',1),

(43,'Peking Duck',120,'Hard','Traditional Chinese specialty',
'1. Marinate duck. 2. Dry skin. 3. Roast slowly. 4. Slice and serve.',
2,4,4,'https://images.unsplash.com/photo-1604908177522-4021c0bff3f0?auto=format&fit=crop&q=80&w=800',1),

-- =========================
-- DINNER
-- =========================

(23,'Paneer Butter Masala',35,'Hard','Rich Indian dinner',
'1. Prepare gravy. 2. Add paneer. 3. Simmer and serve.',
3,3,1,'https://images.unsplash.com/photo-1631452180519-c014fe946bc0?auto=format&fit=crop&q=80&w=800',1),

(24,'Margherita Pizza',30,'Hard','Italian pizza dinner',
'1. Add sauce. 2. Add cheese. 3. Bake.',
3,1,4,'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&q=80&w=800',1),

(25,'Tacos',20,'Easy','Mexican tacos dinner',
'1. Fill shells. 2. Add toppings. 3. Serve.',
3,2,3,'https://images.unsplash.com/photo-1551504734-5ee1c4a14791?auto=format&fit=crop&q=80&w=800',1),

(26,'Baked Fish',35,'Medium','Continental seafood dinner',
'1. Season fish. 2. Bake well. 3. Serve.',
3,6,2,'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?auto=format&fit=crop&q=80&w=800',1),

(27,'Manchurian Rice',30,'Hard','Chinese gravy dinner',
'1. Fry balls. 2. Prepare sauce. 3. Serve with rice.',
3,4,3,'https://images.unsplash.com/photo-1604908176997-431a4f96b6f2?auto=format&fit=crop&q=80&w=800',1),

(28,'Mac and Cheese',25,'Easy','American pasta dinner',
'1. Boil pasta. 2. Add cheese sauce. 3. Mix.',
3,5,1,'https://images.unsplash.com/photo-1543332164-6e82f355badc?auto=format&fit=crop&q=80&w=800',1),

(44,'Enchiladas',55,'Hard','Mexican baked dinner',
'1. Prepare filling. 2. Roll tortillas. 3. Add sauce. 4. Bake.',
3,2,4,'https://images.unsplash.com/photo-1534352956036-cd81e27dd615?auto=format&fit=crop&q=80&w=800',1),

(45,'Beef Wellington',90,'Hard','Premium continental dinner',
'1. Sear beef. 2. Wrap in pastry. 3. Bake till golden.',
3,6,5,'https://images.unsplash.com/photo-1600891964092-4316c288032e?auto=format&fit=crop&q=80&w=800',1),

-- =========================
-- SNACKS
-- =========================

(29,'Samosa',30,'Hard','Indian crispy snack',
'1. Fill dough. 2. Fold. 3. Fry.',
5,3,4,'https://images.unsplash.com/photo-1601050690597-df0568f70950?auto=format&fit=crop&q=80&w=800',1),

(30,'Garlic Bread',15,'Easy','Italian snack',
'1. Apply garlic butter. 2. Bake bread.',
5,1,3,'https://images.unsplash.com/photo-1573140247632-f8fd74997d5c?auto=format&fit=crop&q=80&w=800',1),

(31,'Nachos',10,'Easy','Mexican snack',
'1. Arrange nachos. 2. Add cheese. 3. Bake.',
5,2,3,'https://images.unsplash.com/photo-1513456852971-30c0b8199d4d?auto=format&fit=crop&q=80&w=800',1),

(32,'French Fries',20,'Easy','Continental snack',
'1. Cut potato. 2. Fry till crisp.',
5,6,3,'https://images.unsplash.com/photo-1576107232684-1279f390859f?auto=format&fit=crop&q=80&w=800',1),

(33,'Spring Rolls',25,'Hard','Chinese snack',
'1. Fill wrappers. 2. Roll. 3. Fry.',
5,4,3,'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?auto=format&fit=crop&q=80&w=800',1),

(34,'Popcorn Chicken',25,'Medium','American snack',
'1. Coat chicken. 2. Fry crisp.',
5,5,1,'https://images.unsplash.com/photo-1562967916-eb82221dfb92?auto=format&fit=crop&q=80&w=800',1),

(46,'Kachori',55,'Hard','Indian stuffed snack',
'1. Make dough. 2. Fill dal mix. 3. Shape. 4. Fry.',
5,3,4,'https://images.unsplash.com/photo-1626500155537-df2d6c6f216a?auto=format&fit=crop&q=80&w=800',1),

(47,'Tamales',90,'Hard','Mexican steamed snack',
'1. Prepare dough. 2. Fill husks. 3. Wrap. 4. Steam.',
5,2,4,'https://images.unsplash.com/photo-1615870216519-2f9fa57506b8?auto=format&fit=crop&q=80&w=800',1),

-- =========================
-- DESSERT
-- =========================

(35,'Gulab Jamun',30,'Hard','Indian sweet dessert',
'1. Make balls. 2. Fry. 3. Soak in syrup.',
4,3,4,'https://images.unsplash.com/photo-1605197161470-5b1d6dcb93c1?auto=format&fit=crop&q=80&w=800',1),

(36,'Tiramisu',20,'Hard','Italian layered dessert',
'1. Layer biscuits. 2. Add cream. 3. Chill.',
4,1,4,'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?auto=format&fit=crop&q=80&w=800',1),

(37,'Churros',25,'Hard','Mexican dessert',
'1. Pipe dough. 2. Fry. 3. Coat sugar.',
4,2,4,'https://images.unsplash.com/photo-1624378439575-d8705ad7ae80?auto=format&fit=crop&q=80&w=800',1),

(38,'Fruit Custard',20,'Easy','Continental dessert',
'1. Prepare custard. 2. Add fruits. 3. Chill.',
4,6,2,'https://images.unsplash.com/photo-1563805042-7684c019e1cb?auto=format&fit=crop&q=80&w=800',1),

(39,'Sesame Balls',30,'Hard','Chinese sweet dessert',
'1. Make dough balls. 2. Fry. 3. Serve.',
4,4,4,'https://images.unsplash.com/photo-1608039755401-742074f0548d?auto=format&fit=crop&q=80&w=800',1),

(40,'Brownie',30,'Easy','American chocolate dessert',
'1. Make batter. 2. Bake. 3. Cut pieces.',
4,5,1,'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&q=80&w=800',1),

(48,'Cannoli',60,'Hard','Italian crispy dessert',
'1. Make shells. 2. Fry crisp. 3. Fill cream.',
4,1,5,'https://images.unsplash.com/photo-1612198790700-0ff08cb726e5?auto=format&fit=crop&q=80&w=800',1),

(49,'Baked Cheesecake',70,'Hard','Rich American dessert',
'1. Prepare base. 2. Add batter. 3. Bake. 4. Chill.',
4,5,5,'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&q=80&w=800',1),

(50,'Mooncake',80,'Hard','Traditional Chinese dessert',
'1. Prepare dough. 2. Fill paste. 3. Mold. 4. Bake.',
4,4,4,'https://images.unsplash.com/photo-1604909052743-94e838986d24?auto=format&fit=crop&q=80&w=800',1);

-- Link Ingredients to Recipes

INSERT IGNORE INTO RECIPE_INGREDIENT (recipe_id, ingredient_id, quantity_desc) VALUES

-- BREAKFAST
(11,11,'2 cups'),
(11,31,'200g'),
(11,32,'1 tsp'),

(12,16,'2'),
(12,61,'50g'),
(12,62,'2 slices'),
(12,1,'100g'),

(13,13,'2'),
(13,16,'2'),
(13,41,'100g'),
(13,61,'50g'),

(14,18,'200g'),
(14,17,'250ml'),
(14,16,'1'),
(14,20,'30g'),

(15,28,'200g'),
(15,29,'1'),
(15,30,'1'),
(15,26,'1 tbsp'),

(16,18,'200g'),
(16,17,'200ml'),
(16,16,'1'),
(16,19,'40g'),
(16,56,'2 tbsp'),

(41,63,'250g'),      -- Urad Dal
(41,2,'100g'),
(41,59,'400ml'),

-- LUNCH
(17,11,'300g'),
(17,29,'1'),
(17,30,'1'),
(17,58,'100g'),

(18,4,'250g'),
(18,1,'200g'),
(18,3,'2 cloves'),
(18,57,'1 tsp'),

(19,13,'2'),
(19,61,'100g'),
(19,29,'1'),
(19,2,'1'),

(20,60,'250g'),
(20,38,'100g'),
(20,1,'1'),
(20,6,'1 tbsp'),

(21,11,'250g'),
(21,29,'1'),
(21,30,'1'),
(21,26,'2 tbsp'),

(22,39,'2'),
(22,40,'2'),
(22,61,'50g'),
(22,38,'50g'),

(42,64,'250g'),      -- Lasagna Sheets
(42,1,'200g'),
(42,61,'200g'),
(42,60,'250g'),

(43,65,'1 whole'),   -- Duck
(43,26,'30ml'),
(43,66,'20g'),       -- Honey
(43,3,'20g'),

-- DINNER
(23,21,'200g'),
(23,1,'200g'),
(23,34,'50ml'),
(23,19,'20g'),

(24,33,'1'),
(24,10,'150g'),
(24,1,'100g'),
(24,9,'10g'),

(25,54,'4'),
(25,41,'150g'),
(25,38,'50g'),
(25,61,'50g'),

(26,35,'300g'),
(26,36,'1'),
(26,19,'30g'),
(26,3,'2 cloves'),

(27,11,'250g'),
(27,26,'2 tbsp'),
(27,29,'1'),

(28,37,'250g'),
(28,61,'150g'),
(28,17,'200ml'),
(28,19,'20g'),

(44,13,'6'),
(44,60,'250g'),
(44,61,'150g'),
(44,67,'150g'),      -- Tomato Sauce

(45,15,'400g'),
(45,68,'150g'),      -- Mushroom
(45,69,'1'),         -- Pastry Sheet
(45,19,'40g'),

-- SNACKS
(29,18,'200g'),
(29,31,'200g'),
(29,42,'50g'),
(29,59,'300ml'),

(30,62,'4 slices'),
(30,19,'40g'),
(30,3,'20g'),

(31,43,'200g'),
(31,61,'100g'),
(31,1,'50g'),

(32,31,'300g'),
(32,59,'300ml'),
(32,7,'5g'),

(33,45,'6'),
(33,44,'100g'),
(33,30,'50g'),
(33,59,'300ml'),

(34,60,'250g'),
(34,18,'100g'),
(34,59,'300ml'),

(46,18,'250g'),
(46,70,'150g'),      -- Moong Dal
(46,59,'400ml'),

(47,71,'300g'),      -- Corn Flour
(47,60,'200g'),
(47,72,'10'),        -- Corn Husk
(47,19,'50g'),

-- DESSERT
(35,17,'100ml'),
(35,20,'250g'),
(35,59,'300ml'),

(36,52,'150g'),
(36,51,'100ml'),
(36,34,'200ml'),

(37,18,'200g'),
(37,20,'100g'),
(37,59,'300ml'),

(38,17,'500ml'),
(38,48,'50g'),
(38,49,'100g'),
(38,50,'100g'),

(39,47,'200g'),
(39,46,'50g'),
(39,20,'100g'),

(40,18,'150g'),
(40,53,'50g'),
(40,20,'150g'),
(40,19,'100g'),

(48,18,'250g'),
(48,73,'200g'),      -- Ricotta Cheese
(48,20,'100g'),
(48,59,'300ml'),

(49,74,'300g'),      -- Cream Cheese
(49,52,'200g'),
(49,19,'80g'),
(49,20,'120g'),

(50,18,'250g'),
(50,75,'200g'),      -- Lotus Paste
(50,16,'2'),
(50,20,'80g');

-- Insert Sample Ratings/Reviews
INSERT IGNORE INTO RATING (recipe_id, user_id, rating_value, review_text) VALUES

-- BREAKFAST
(11,3,5,'Crispy dosa and tasty filling.'),
(12,2,4,'Simple breakfast and very tasty.'),
(13,4,5,'Perfect quick breakfast option.'),
(14,2,5,'Soft pancakes came out great.'),
(15,4,4,'Light and flavorful noodles.'),
(16,1,5,'Best waffles I made at home.'),
(41,2,5,'Medu vada was crispy outside and soft inside.'),

-- LUNCH
(17,3,5,'Excellent biryani aroma and taste.'),
(18,2,4,'Spicy pasta was enjoyable.'),
(19,4,5,'Cheesy quesadilla was amazing.'),
(20,1,4,'Fresh salad and healthy meal.'),
(21,2,5,'Classic fried rice taste.'),
(22,4,4,'Burger was juicy and filling.'),
(42,1,5,'Lasagna layers were rich and delicious.'),
(43,3,5,'Peking duck was perfectly roasted and tasty.'),

-- DINNER
(23,3,5,'Rich gravy and soft paneer cubes.'),
(24,1,5,'Pizza was cheesy and fresh.'),
(25,2,4,'Crunchy tacos tasted great.'),
(26,4,5,'Fish was juicy and perfectly baked.'),
(27,1,4,'Good combo with rice.'),
(28,2,5,'Creamy mac and cheese loved by all.'),
(44,4,5,'Enchiladas were cheesy and flavorful.'),
(45,1,5,'Beef Wellington looked premium and tasted amazing.'),

-- SNACKS
(29,3,5,'Crispy samosa with tasty filling.'),
(30,1,4,'Garlic bread was buttery and crisp.'),
(31,2,5,'Perfect snack for movie night.'),
(32,4,4,'French fries were crispy.'),
(33,1,5,'Spring rolls were crunchy and tasty.'),
(34,2,4,'Chicken bites were delicious.'),
(46,3,5,'Kachori was flaky and spicy.'),
(47,2,5,'Tamales were soft and flavorful.'),

-- DESSERT
(35,3,5,'Soft gulab jamun melted in mouth.'),
(36,1,5,'Tiramisu tasted premium.'),
(37,2,4,'Churros were sweet and crunchy.'),
(38,4,5,'Fruit custard was refreshing.'),
(39,1,4,'Sesame balls were unique and tasty.'),
(40,2,5,'Brownie was rich and fudgy.'),
(48,4,5,'Cannoli shell was crispy and creamy inside.'),
(49,1,5,'Cheesecake was rich and smooth.'),
(50,3,5,'Mooncake had authentic flavor and texture.');
