# The Hungry Hub

A complete full-stack web application for recipe management, pantry searching, and meal planning.

## Tech Stack
- **Frontend**: HTML5, Vanilla JavaScript, Tailwind CSS (via CDN)
- **Backend**: Node.js, Express.js
- **Database**: MySQL
- **Security**: JWT Authentication, bcrypt password hashing

## Folder Structure
```
TheHungryHub/
├── backend/
│   ├── config/          # Database connection
│   ├── controllers/     # Business logic
│   ├── middleware/      # Auth middlewares
│   ├── routes/          # Express routes
│   ├── .env             # Environment variables
│   ├── package.json     # Node dependencies
│   └── server.js        # Main entry point
├── database/
│   └── schema.sql       # MySQL Database schema & seed data
└── frontend/
    ├── css/             # Custom styles
    ├── js/              # App logic and API wrapper
    ├── assets/          # Images (if any)
    ├── index.html       # Home Page
    ├── login.html       # Auth Pages
    ├── register.html
    ├── recipes.html     # Recipe Listing
    ├── recipe-details.html
    ├── dashboard.html   # User Profile & Meal Planner
    ├── ingredient-search.html # Pantry Search
    └── admin.html       # Admin Control Panel
```

## Setup Instructions

### 1. Database Setup
1. Open your MySQL client (e.g., MySQL Workbench, XAMPP, or CLI).
2. Execute the entire `database/schema.sql` script.
3. This will create the `hungry_hub` database, all 11 tables, and insert sample categories, cuisines, moods, ingredients, and an admin user.

### 2. Backend Setup
1. Open a terminal and navigate to the `backend` folder:
   ```bash
   cd backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure Environment Variables:
   Open `backend/.env` and ensure `DB_USER` and `DB_PASSWORD` match your local MySQL credentials.
   ```
   PORT=5000
   DB_HOST=localhost
   DB_USER=root
   DB_PASSWORD=
   DB_NAME=hungry_hub
   JWT_SECRET=super_secret_jwt_key_for_hungry_hub
   ```
4. Start the server:
   ```bash
   npm run dev
   ```
   *The server should run on http://localhost:5000*

### 3. Frontend Setup
1. The frontend uses Vanilla JS and Tailwind via CDN. It does not require Node.js compilation.
2. To avoid CORS or local file restrictions, serve the `frontend` folder using a simple static server.
   If using VS Code, install the **Live Server** extension.
   Right-click `frontend/index.html` and select "Open with Live Server".

## How to Test
1. **Admin Access**: 
   - Login with: `admin@hungryhub.com` / `Admin123!`
   - You will see the Admin button in the navbar to add recipes and manage users.
2. **Normal User**: 
   - Register a new user via the Sign Up page.
   - Login and browse recipes, add ratings, and use the meal planner.
3. **Pantry Search**:
   - Go to "Pantry Search".
   - Type "Tomato, Pasta, Garlic" to find matching recipes from the database.

## API Endpoints Overview
- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/users/profile`
- `GET /api/recipes`
- `POST /api/recipes/match-ingredients`
- `POST /api/planner`
- `GET /api/admin/users`
