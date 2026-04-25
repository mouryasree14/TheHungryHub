const API_URL = 'http://localhost:5000/api';

const api = {
    async request(endpoint, options = {}) {
        const token = localStorage.getItem('token');
        const headers = {
            'Content-Type': 'application/json',
            ...options.headers
        };

        if (token) {
            headers['Authorization'] = `Bearer ${token}`;
        }

        try {
            const response = await fetch(`${API_URL}${endpoint}`, {
                ...options,
                headers
            });
            const data = await response.json();
            
            if (!response.ok) {
                throw new Error(data.message || 'Something went wrong');
            }
            return data;
        } catch (error) {
            console.error('API Error:', error);
            throw error;
        }
    },

    auth: {
        login: (credentials) => api.request('/auth/login', { method: 'POST', body: JSON.stringify(credentials) }),
        register: (userData) => api.request('/auth/register', { method: 'POST', body: JSON.stringify(userData) })
    },

    user: {
        getProfile: () => api.request('/users/profile'),
        updateProfile: (data) => api.request('/users/profile', { method: 'PUT', body: JSON.stringify(data) })
    },

    recipes: {
        getAll: (params = '') => api.request(`/recipes${params ? '?' + params : ''}`),
        getById: (id) => api.request(`/recipes/${id}`),
        matchIngredients: (ingredients) => api.request('/recipes/match-ingredients', { method: 'POST', body: JSON.stringify({ ingredients }) }),
        create: (data) => api.request('/recipes', { method: 'POST', body: JSON.stringify(data) })
    },

    planner: {
        get: (userId, week) => api.request(`/planner/${userId}?week=${week}`),
        add: (data) => api.request('/planner', { method: 'POST', body: JSON.stringify(data) }),
        delete: (id, data) => api.request(`/planner/${id}`, { method: 'DELETE', body: JSON.stringify(data) })
    }
};
