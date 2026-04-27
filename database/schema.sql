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

-- BREAKFAST

(1,'Masala Dosa',25,'Hard','South Indian crispy breakfast',
'1. Heat a flat pan (tawa) and lightly grease it with oil.
2. Pour a ladle of dosa batter and spread it thin in a circular motion.
3. Cook until the base turns golden and crisp.
4. Place prepared potato masala in the center.
5. Fold the dosa carefully into a roll or triangle.
6. Remove from pan and serve hot.
7. Serve with coconut chutney and sambar.',
1,3,1,'https://vismaifood.com/storage/app/uploads/public/45a/29b/a17/thumb__700_0_0_0_auto.jpg',1),

(2,'Cheese Omelette Bruschetta',15,'Easy','Italian style breakfast toast',
'1. Toast bread slices until crisp and golden.
2. Beat eggs with salt and pepper in a bowl.
3. Heat a pan and cook the egg mixture into a soft omelette.
4. Place the omelette over toasted bread.
5. Add chopped tomatoes and sprinkle cheese on top.
6. Let cheese melt slightly.
7. Serve immediately while warm.',
1,1,3,'https://www.theomeletteguys.com/wp-content/uploads/2025/04/omelette.webp',1),

(3,'Breakfast Burrito',20,'Easy','Quick Mexican breakfast',
'1. Heat a pan and scramble eggs until fully cooked.
2. Warm the tortilla lightly on another pan.
3. Place scrambled eggs, beans, and cheese in the center.
4. Add optional sauces or vegetables if desired.
5. Fold the sides and roll the tortilla tightly.
6. Cut into halves for easy serving.
7. Serve hot.',
1,2,3,'https://tse2.mm.bing.net/th/id/OIP.spszPLufYFCLBKgVT12e5AHaHa?w=750&h=750&rs=1&pid=ImgDetMain&o=7&rm=3',1),

(4,'Pancakes',20,'Easy','Soft continental pancakes',
'1. Mix flour, milk, eggs, and sugar into a smooth batter.
2. Heat a non-stick pan and lightly grease it.
3. Pour a ladle of batter onto the pan.
4. Cook until bubbles appear on the surface.
5. Flip and cook the other side until golden.
6. Stack pancakes on a plate.
7. Serve with syrup or fruits.',
1,6,1,'https://recipe.sfo3.digitaloceanspaces.com/images/delicious-oat-flour-pancakes-easy-recipe-for-heal-99286-featured_1_0.jpg',1),

(5,'Vegetable Noodles',20,'Easy','Chinese breakfast noodles',
'1. Boil noodles in water until soft and drain.
2. Heat oil in a pan and add chopped vegetables.
3. Stir-fry vegetables on high heat.
4. Add boiled noodles to the pan.
5. Pour soy sauce and mix well.
6. Toss everything evenly.
7. Serve hot.',
1,4,3,'https://th.bing.com/th/id/R.42e85ae999118d0fe3f98977fb5bb36b?rik=jMszyoimwAUo4w&riu=http%3a%2f%2fwww.blog.sagmart.com%2fwp-content%2fuploads%2f2015%2f07%2fHakka-Noodles.jpg&ehk=L1Ig4QMkVnMXKfzXYc4dtkYUVpxg8T8kuDBKxbTkQCw%3d&risl=&pid=ImgRaw&r=0',1),

(6,'Waffles',25,'Medium','American classic waffles',
'1. Prepare waffle batter using flour, milk, eggs, and butter.
2. Preheat the waffle maker.
3. Pour batter into the waffle mold.
4. Close the lid and cook until golden brown.
5. Carefully remove the waffle.
6. Place on serving plate.
7. Serve hot with syrup or honey.',
1,5,1,'https://img.freepik.com/premium-photo/delicious-waffle-breakfast_974732-34316.jpg',1),

(7,'Medu Vada',50,'Hard','Crispy South Indian breakfast',
'1. Soak urad dal in water for several hours.
2. Grind into a smooth thick batter.
3. Add salt and mix well.
4. Heat oil in a deep pan.
5. Shape batter into vadas with a hole in center.
6. Deep fry until golden and crispy.
7. Drain excess oil and serve hot with chutney.',
1,3,1,'https://i0.wp.com/passion2cook.com/wp-content/uploads/2022/10/medu-vada-1.jpg?w=1628&ssl=1',1),

(8,'Veg Biryani',40,'Hard','Indian rice lunch',
'1. Heat oil in a pot and sauté spices and vegetables.
2. Add soaked rice and mix gently.
3. Pour water and add salt.
4. Cover and cook on low flame (dum method).
5. Allow rice to absorb flavors completely.
6. Turn off heat and let it rest.
7. Serve hot with raita.',
2,3,4,'https://tse4.mm.bing.net/th/id/OIP.KSx3IaljuNAW9k62MUip5wHaHa?rs=1&pid=ImgDetMain&o=7&rm=3',1),

(9,'Pasta Arrabiata',25,'Easy','Spicy Italian pasta',
'1. Boil pasta in salted water until al dente.
2. Heat olive oil in a pan and sauté garlic.
3. Add tomato sauce and chili flakes.
4. Cook sauce until slightly thick.
5. Add boiled pasta and mix well.
6. Toss until pasta is evenly coated.
7. Serve hot with herbs.',
2,1,3,'https://cdn.mygingergarlickitchen.com/images/800px/800px-pasta-arrabiata-recipe-my-ginger-garlic-kitchen-7.jpg',1),

(10,'Veg Quesadilla',20,'Easy','Cheesy Mexican lunch',
'1. Place tortilla on a pan.
2. Add vegetables and cheese on one half.
3. Fold tortilla over the filling.
4. Cook on both sides until crisp.
5. Remove from pan.
6. Cut into wedges.
7. Serve hot with dip.',
2,2,3,'https://img.pikbest.com/photo/20240718/realistic-image-of-golden-brown-cheesy-chicken-quesadillas-cut-into-triangles_10673645.jpg!bw700',1),

(11,'Grilled Chicken Salad',30,'Medium','Healthy continental lunch',
'1. Season chicken with salt, pepper, and oil.
2. Grill the chicken until fully cooked and slightly charred.
3. Chop fresh vegetables like lettuce, tomato, and cucumber.
4. Slice grilled chicken into strips.
5. Combine vegetables and chicken in a bowl.
6. Add dressing and toss gently.
7. Serve fresh.',
2,6,2,'https://cookingsteps.com/wp-content/uploads/2025/04/Image_3-65.png',1),

(12,'Fried Rice',20,'Easy','Chinese classic lunch',
'1. Heat oil in a wok on high flame.
2. Add chopped vegetables and stir-fry.
3. Add cooked rice to the wok.
4. Pour soy sauce and seasonings.
5. Mix everything thoroughly.
6. Stir-fry for 3–4 minutes.
7. Serve hot.',
2,4,3,'https://cookcue.com/wp-content/uploads/2025/08/0_2-1754845048884.webp',1),

(13,'Burger Meal',30,'Medium','American burger lunch',
'1. Cook the patty on a pan until done.
2. Toast burger buns lightly.
3. Place patty on bottom bun.
4. Add lettuce, tomato, and cheese.
5. Spread sauces as desired.
6. Cover with top bun.
7. Serve with fries or sides.',
2,5,1,'https://png.pngtree.com/thumb_back/fh260/background/20240609/pngtree-complete-hamburger-with-two-meats-sauces-french-fries-and-cola-soda-image_15745383.jpg',1),

(14,'Lasagna',60,'Hard','Classic layered Italian pasta',
'1. Prepare tomato sauce and white sauce separately.
2. Boil lasagna sheets until soft.
3. Layer sheets, sauce, and cheese in a baking dish.
4. Repeat layers evenly.
5. Top with extra cheese.
6. Bake in preheated oven until golden.
7. Serve hot.',
2,1,4,'https://i.pinimg.com/originals/f4/d1/af/f4d1afa4ff731fdddff4fee320e2bdc5.jpg',1),

(15,'Peking Duck',120,'Hard','Traditional Chinese specialty',
'1. Clean and marinate the duck thoroughly.
2. Allow skin to dry for crisp texture.
3. Roast in oven at controlled temperature.
4. Baste occasionally for flavor.
5. Cook until skin becomes crispy.
6. Rest before slicing.
7. Serve with accompaniments.',
2,4,4,'https://www.imperialtreasure.com/uk/resources/album/Imperial%20Treasure%20Fine%20Chinese%20Cuisine/Peking%20Duck.jpg',1),

-- DINNER

(16,'Paneer Butter Masala',35,'Hard','Rich Indian dinner',
'1. Heat butter in a pan and sauté spices.
2. Add tomato puree and cook until thick.
3. Add cream and mix well.
4. Add paneer cubes gently.
5. Simmer for a few minutes.
6. Adjust seasoning.
7. Serve hot.',
3,3,1,'https://industhanfood.ie/wp-content/uploads/2024/08/Paneer-Butter-Masala.png',1),

(17,'Margherita Pizza',30,'Hard','Italian pizza dinner',
'1. Spread tomato sauce evenly on pizza base.
2. Add mozzarella cheese generously.
3. Sprinkle fresh basil leaves.
4. Place in preheated oven.
5. Bake until cheese melts and base is crisp.
6. Remove and slice.
7. Serve hot.',
3,1,4,'https://elianarecipes.com/wp-content/uploads/2024/08/Margherita-Pizza-Recipe.png',1),

(18,'Tacos',20,'Easy','Mexican tacos dinner',
'1. Warm taco shells lightly.
2. Prepare filling using meat or vegetables.
3. Add filling into shells.
4. Top with lettuce, cheese, and sauces.
5. Arrange on plate.
6. Garnish if needed.
7. Serve immediately.',
3,2,3,'https://tse2.mm.bing.net/th/id/OIP.nV8lfmJPcISxitmssn_iwwHaEs?rs=1&pid=ImgDetMain&o=7&rm=3',1),

(19,'Baked Fish',35,'Medium','Continental seafood dinner',
'1. Clean fish and pat dry.
2. Season with salt, pepper, and lemon juice.
3. Place fish on baking tray.
4. Add butter or oil on top.
5. Bake until cooked through.
6. Garnish with herbs.
7. Serve hot.',
3,6,2,'https://insanelygoodrecipes.com/wp-content/uploads/2024/11/Garlic-Butter-Oven-Baked-Tilapia-4-500x500.jpg',1),

(20,'Manchurian Rice',30,'Hard','Chinese gravy dinner',
'1. Prepare vegetable balls and deep fry them.
2. Make Manchurian gravy in a pan.
3. Cook rice separately.
4. Add fried balls into gravy.
5. Mix well and simmer briefly.
6. Serve with hot rice.
7. Enjoy immediately.',
3,4,3,'https://img-cdn.thepublive.com/fit-in/1280x960/filters:format(webp)/sanjeev-kapoor/media/media_files/x10HBwyIRGJLbyExjRtR.JPG',1),

(21,'Mac and Cheese',25,'Easy','American pasta dinner',
'1. Boil macaroni in salted water.
2. Prepare cheese sauce using milk and cheese.
3. Add boiled pasta to the sauce.
4. Mix thoroughly.
5. Cook for 2–3 minutes.
6. Adjust seasoning.
7. Serve warm.',
3,5,1,'https://www.allrecipes.com/thmb/a2ffdg8KWS41BjvLePGemKb_yZw=/750x0/filters:no_upscale():max_bytes(150000):strip_icc()/238691-Simple-Macaroni-And-Cheese-mfs_008-b32db5aa505041acbe958aedb81d29e9.jpg',1),

(22,'Enchiladas',55,'Hard','Mexican baked dinner',
'1. Prepare filling using vegetables or meat.
2. Fill tortillas and roll tightly.
3. Place in baking dish.
4. Pour sauce over rolls.
5. Add cheese on top.
6. Bake until golden.
7. Serve hot.',
3,2,4,'https://succulentrecipes.com/wp-content/uploads/2024/09/pinteresto_43490_High_Protein_Chicken_Enchiladas_Amateur_photo__66e9b0e6-1ad6-4d32-aefa-c349e6cd8a63.png',1),

(23,'Beef Wellington',90,'Hard','Premium continental dinner',
'1. Sear beef on all sides.
2. Prepare mushroom mixture.
3. Wrap beef with mixture and pastry.
4. Seal edges properly.
5. Bake until golden brown.
6. Let it rest before cutting.
7. Serve hot.',
3,6,5,'https://ritzyrecipes.com/wp-content/uploads/2025/10/cd-dvfdg-1024x683.png',1),

-- SNACKS

(24,'Samosa',30,'Hard','Indian crispy snack',
'1. Prepare dough and let it rest.
2. Make spiced potato filling.
3. Roll dough and shape into cones.
4. Fill with mixture and seal edges.
5. Deep fry until golden.
6. Drain oil.
7. Serve hot.',
5,3,4,'https://vegecravings.com/wp-content/uploads/2017/03/Aloo-Samosa-Recipe-Step-By-Step-Instructions.jpg',1),

(25,'Garlic Bread',15,'Easy','Italian snack',
'1. Mix butter with garlic and herbs.
2. Spread mixture on bread slices.
3. Place on baking tray.
4. Bake until crisp.
5. Remove from oven.
6. Slice if needed.
7. Serve warm.',
5,1,3,'https://quickrecipesideas.com/wp-content/uploads/2025/02/Image_2-379.png',1),

(26,'Nachos',10,'Easy','Mexican snack',
'1. Arrange nachos on a tray.
2. Sprinkle cheese evenly.
3. Add toppings if desired.
4. Bake until cheese melts.
5. Remove from oven.
6. Add sauces.
7. Serve immediately.',
5,2,3,'https://i.pinimg.com/originals/e5/c5/7b/e5c57b4babfada4a6a1bbcf8ae10c275.jpg',1),

(27,'French Fries',20,'Easy','Continental snack',
'1. Peel and cut potatoes into strips.
2. Soak briefly in water.
3. Heat oil for frying.
4. Deep fry until golden and crispy.
5. Drain excess oil.
6. Sprinkle salt.
7. Serve hot.',
5,6,3,'https://img.freepik.com/premium-photo/yummy-french-fries_693425-7978.jpg',1),

(28,'Spring Rolls',25,'Hard','Chinese snack',
'1. Prepare vegetable filling.
2. Place filling on wrapper.
3. Roll tightly and seal edges.
4. Heat oil in pan.
5. Deep fry until crispy.
6. Drain oil.
7. Serve hot.',
5,4,3,'https://s.lightorangebean.com/media/20240914144947/Thai-Veggie-Spring-Rolls_done.png',1),

(29,'Popcorn Chicken',25,'Medium','American snack',
'1. Cut chicken into small pieces.
2. Marinate with spices.
3. Coat with flour mixture.
4. Heat oil for frying.
5. Fry until crispy and golden.
6. Drain oil.
7. Serve hot.',
5,5,1,'https://tse3.mm.bing.net/th/id/OIP.jZmSFik7dRZ0J7GcYGyfDAHaHa?rs=1&pid=ImgDetMain&o=7&rm=3',1),

(30,'Kachori',55,'Hard','Indian stuffed snack',
'1. Prepare dough and filling separately.
2. Stuff filling into dough balls.
3. Shape carefully.
4. Heat oil on low flame.
5. Fry slowly until crisp.
6. Drain oil.
7. Serve hot.',
5,3,4,'https://images.herzindagi.info/image/2023/Jun/how-to-make-dal-kachori.jpg',1),

(31,'Tamales',90,'Hard','Mexican steamed snack',
'1. Prepare dough using corn flour.
2. Place dough on corn husks.
3. Add filling in center.
4. Wrap tightly.
5. Steam until cooked.
6. Cool slightly.
7. Serve warm.',
5,2,4,'https://www.isabeleats.com/wp-content/uploads/2019/12/pork-tamales-small-15b-650x650.jpg',1),

-- DESSERT

(32,'Gulab Jamun',30,'Hard','Indian sweet dessert',
'1. Prepare dough and shape into balls.
2. Heat oil and fry until golden.
3. Prepare sugar syrup separately.
4. Add fried balls to syrup.
5. Let them soak well.
6. Rest for a few minutes.
7. Serve warm.',
4,3,4,'https://indianstyle.sg/wp-content/uploads/2024/10/01-Gulab-Jamun-600x600.png',1),

(33,'Tiramisu',20,'Hard','Italian layered dessert',
'1. Prepare coffee mixture.
2. Dip biscuits in coffee.
3. Layer biscuits in dish.
4. Add cream mixture on top.
5. Repeat layers.
6. Chill for several hours.
7. Serve cold.',
4,1,4,'https://grandmarecipes.com/wp-content/uploads/2024/09/Classic-Tiramisu-with-Coffee.webp',1),

(34,'Churros',25,'Hard','Mexican dessert',
'1. Prepare dough.
2. Heat oil in pan.
3. Pipe dough into hot oil.
4. Fry until golden.
5. Remove and drain oil.
6. Coat with sugar.
7. Serve warm.',
4,2,4,'https://img.freepik.com/premium-photo/churros-dusted-with-cinnamon-sugar-served-wallpaper_987764-58268.jpg',1),

(35,'Fruit Custard',20,'Easy','Continental dessert',
'1. Prepare custard using milk.
2. Let it cool slightly.
3. Chop fresh fruits.
4. Add fruits to custard.
5. Mix gently.
6. Refrigerate for some time.
7. Serve chilled.',
4,6,2,'https://www.sophiarecipe.com/wp-content/uploads/2025/04/chini1_39852_Fruit_Custard_is_a_classic_Indian_dessert_made_by__35b9bcba-c9f3-4b13-9308-2ac19c4bba57-819x1024.jpg',1),

(36,'Sesame Balls',30,'Hard','Chinese sweet dessert',
'1. Prepare dough using rice flour.
2. Shape into small balls.
3. Coat with sesame seeds.
4. Heat oil for frying.
5. Fry until golden.
6. Drain oil.
7. Serve warm.',
4,4,4,'https://i.pinimg.com/originals/61/65/ad/6165ad2e5186a45f274c8c977a58f59f.png',1),

(37,'Brownie',30,'Easy','American chocolate dessert',
'1. Prepare chocolate batter.
2. Grease baking tray.
3. Pour batter into tray.
4. Bake in preheated oven.
5. Check with toothpick.
6. Cool before cutting.
7. Serve pieces.',
4,5,1,'https://png.pngtree.com/thumb_back/fw800/background/20240706/pngtree-stack-of-moist-fudgy-brownies-image_15862023.jpg',1),

(38,'Cannoli',60,'Hard','Italian crispy dessert',
'1. Prepare dough for shells.
2. Shape into tubes.
3. Fry until crisp.
4. Prepare ricotta filling.
5. Fill shells carefully.
6. Dust with sugar.
7. Serve fresh.',
4,1,5,'https://img.freepik.com/premium-photo/delicious-cannoli-with-ricotta-filling_1036998-199837.jpg',1),

(39,'Baked Cheesecake',70,'Hard','Rich American dessert',
'1. Prepare biscuit base.
2. Press into baking pan.
3. Prepare cream cheese mixture.
4. Pour over base.
5. Bake slowly.
6. Cool completely.
7. Chill before serving.',
4,5,5,'https://masonrecipes.com/wp-content/uploads/2025/02/Image_3-109.png',1),

(40,'Mooncake',80,'Hard','Traditional Chinese dessert',
'1. Prepare dough and filling.
2. Shape into round portions.
3. Place in mold.
4. Press to form design.
5. Bake until golden.
6. Cool completely.
7. Serve.',
4,4,4,'https://mooncakecosplay.com/wp-content/uploads/2019/09/mooncakecosplay-237202019.jpg',1);

-- Link Ingredients to Recipes

INSERT IGNORE INTO RECIPE_INGREDIENT (recipe_id, ingredient_id, quantity_desc) VALUES

(1,11,'2 cups'),
(1,31,'200g'),
(1,32,'1 tsp'),

(2,16,'2'),
(2,61,'50g'),
(2,62,'2 slices'),
(2,1,'100g'),

(3,13,'2'),
(3,16,'2'),
(3,41,'100g'),
(3,61,'50g'),

(4,18,'200g'),
(4,17,'250ml'),
(4,16,'1'),
(4,20,'30g'),

(5,28,'200g'),
(5,29,'1'),
(5,30,'1'),
(5,26,'1 tbsp'),

(6,18,'200g'),
(6,17,'200ml'),
(6,16,'1'),
(6,19,'40g'),
(6,56,'2 tbsp'),

(7,63,'250g'),
(7,2,'100g'),
(7,59,'400ml'),

(8,11,'300g'),
(8,29,'1'),
(8,30,'1'),
(8,58,'100g'),

(9,4,'250g'),
(9,1,'200g'),
(9,3,'2 cloves'),
(9,57,'1 tsp'),

(10,13,'2'),
(10,61,'100g'),
(10,29,'1'),
(10,2,'1'),

(11,60,'250g'),
(11,38,'100g'),
(11,1,'1'),
(11,6,'1 tbsp'),

(12,11,'250g'),
(12,29,'1'),
(12,30,'1'),
(12,26,'2 tbsp'),

(13,39,'2'),
(13,40,'2'),
(13,61,'50g'),
(13,38,'50g'),

(14,64,'250g'),
(14,1,'200g'),
(14,61,'200g'),
(14,60,'250g'),

(15,65,'1 whole'),
(15,26,'30ml'),
(15,66,'20g'),
(15,3,'20g'),

(16,21,'200g'),
(16,1,'200g'),
(16,34,'50ml'),
(16,19,'20g'),

(17,33,'1'),
(17,10,'150g'),
(17,1,'100g'),
(17,9,'10g'),

(18,54,'4'),
(18,41,'150g'),
(18,38,'50g'),
(18,61,'50g'),

(19,35,'300g'),
(19,36,'1'),
(19,19,'30g'),
(19,3,'2 cloves'),

(20,11,'250g'),
(20,26,'2 tbsp'),
(20,29,'1'),

(21,37,'250g'),
(21,61,'150g'),
(21,17,'200ml'),
(21,19,'20g'),

(22,13,'6'),
(22,60,'250g'),
(22,61,'150g'),
(22,67,'150g'),

(23,15,'400g'),
(23,68,'150g'),
(23,69,'1'),
(23,19,'40g'),

(24,18,'200g'),
(24,31,'200g'),
(24,42,'50g'),
(24,59,'300ml'),

(25,62,'4 slices'),
(25,19,'40g'),
(25,3,'20g'),

(26,43,'200g'),
(26,61,'100g'),
(26,1,'50g'),

(27,31,'300g'),
(27,59,'300ml'),
(27,7,'5g'),

(28,45,'6'),
(28,44,'100g'),
(28,30,'50g'),
(28,59,'300ml'),

(29,60,'250g'),
(29,18,'100g'),
(29,59,'300ml'),

(30,18,'250g'),
(30,70,'150g'),
(30,59,'400ml'),

(31,71,'300g'),
(31,60,'200g'),
(31,72,'10'),
(31,19,'50g'),

(32,17,'100ml'),
(32,20,'250g'),
(32,59,'300ml'),

(33,52,'150g'),
(33,51,'100ml'),
(33,34,'200ml'),

(34,18,'200g'),
(34,20,'100g'),
(34,59,'300ml'),

(35,17,'500ml'),
(35,48,'50g'),
(35,49,'100g'),
(35,50,'100g'),

(36,47,'200g'),
(36,46,'50g'),
(36,20,'100g'),

(37,18,'150g'),
(37,53,'50g'),
(37,20,'150g'),
(37,19,'100g'),

(38,18,'250g'),
(38,73,'200g'),
(38,20,'100g'),
(38,59,'300ml'),

(39,74,'300g'),
(39,52,'200g'),
(39,19,'80g'),
(39,20,'120g'),

(40,18,'250g'),
(40,75,'200g'),
(40,16,'2'),
(40,20,'80g');

-- Insert Sample Ratings/Reviews
INSERT IGNORE INTO RATING (recipe_id, user_id, rating_value, review_text) VALUES

(1,3,5,'Crispy dosa and tasty filling.'),
(2,2,4,'Simple breakfast and very tasty.'),
(3,4,5,'Perfect quick breakfast option.'),
(4,2,5,'Soft pancakes came out great.'),
(5,4,4,'Light and flavorful noodles.'),
(6,1,5,'Best waffles I made at home.'),
(7,2,5,'Medu vada was crispy outside and soft inside.'),

(8,3,5,'Excellent biryani aroma and taste.'),
(9,2,4,'Spicy pasta was enjoyable.'),
(10,4,5,'Cheesy quesadilla was amazing.'),
(11,1,4,'Fresh salad and healthy meal.'),
(12,2,5,'Classic fried rice taste.'),
(13,4,4,'Burger was juicy and filling.'),
(14,1,5,'Lasagna layers were rich and delicious.'),
(15,3,5,'Peking duck was perfectly roasted and tasty.'),

(16,3,5,'Rich gravy and soft paneer cubes.'),
(17,1,5,'Pizza was cheesy and fresh.'),
(18,2,4,'Crunchy tacos tasted great.'),
(19,4,5,'Fish was juicy and perfectly baked.'),
(20,1,4,'Good combo with rice.'),
(21,2,5,'Creamy mac and cheese loved by all.'),
(22,4,5,'Enchiladas were cheesy and flavorful.'),
(23,1,5,'Beef Wellington looked premium and tasted amazing.'),

(24,3,5,'Crispy samosa with tasty filling.'),
(25,1,4,'Garlic bread was buttery and crisp.'),
(26,2,5,'Perfect snack for movie night.'),
(27,4,4,'French fries were crispy.'),
(28,1,5,'Spring rolls were crunchy and tasty.'),
(29,2,4,'Chicken bites were delicious.'),
(30,3,5,'Kachori was flaky and spicy.'),
(31,2,5,'Tamales were soft and flavorful.'),

(32,3,5,'Soft gulab jamun melted in mouth.'),
(33,1,5,'Tiramisu tasted premium.'),
(34,2,4,'Churros were sweet and crunchy.'),
(35,4,5,'Fruit custard was refreshing.'),
(36,1,4,'Sesame balls were unique and tasty.'),
(37,2,5,'Brownie was rich and fudgy.'),
(38,4,5,'Cannoli shell was crispy and creamy inside.'),
(39,1,5,'Cheesecake was rich and smooth.'),
(40,3,5,'Mooncake had authentic flavor and texture.');
