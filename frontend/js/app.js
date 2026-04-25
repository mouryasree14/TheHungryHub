// Global App Logic

document.addEventListener('DOMContentLoaded', () => {
    updateNavbar();
});

function updateNavbar() {
    const user = JSON.parse(localStorage.getItem('user'));
    const navLinks = document.getElementById('nav-links');
    const mobileNavLinks = document.getElementById('mobile-nav-links');

    if (!navLinks) return;

    let desktopHtml = '';
    let mobileHtml = '';

    if (user) {
        desktopHtml = `
            <a href="recipes.html" class="text-gray-700 hover:text-primary transition font-medium">Recipes</a>
            <a href="ingredient-search.html" class="text-gray-700 hover:text-primary transition font-medium">Pantry Search</a>
            <a href="dashboard.html" class="text-gray-700 hover:text-primary transition font-medium">Dashboard</a>
            ${user.role === 'admin' ? '<a href="admin.html" class="text-red-500 hover:text-red-600 transition font-medium">Admin</a>' : ''}
            <button onclick="logout()" class="px-5 py-2 rounded-full border border-gray-300 text-gray-700 hover:bg-gray-50 transition">Logout</button>
        `;
        mobileHtml = `
            <a href="recipes.html" class="block py-2 text-gray-700">Recipes</a>
            <a href="ingredient-search.html" class="block py-2 text-gray-700">Pantry Search</a>
            <a href="dashboard.html" class="block py-2 text-gray-700">Dashboard</a>
            ${user.role === 'admin' ? '<a href="admin.html" class="block py-2 text-red-500">Admin</a>' : ''}
            <button onclick="logout()" class="block w-full text-left py-2 text-gray-700">Logout</button>
        `;
    } else {
        desktopHtml = `
            <a href="recipes.html" class="text-gray-700 hover:text-primary transition font-medium">Recipes</a>
            <a href="login.html" class="px-5 py-2 rounded-full border border-primary text-primary hover:bg-primary hover:text-white transition">Login</a>
            <a href="register.html" class="px-5 py-2 rounded-full bg-primary text-white hover:bg-primary-hover shadow-md hover:shadow-lg transition">Sign Up</a>
        `;
        mobileHtml = `
            <a href="recipes.html" class="block py-2 text-gray-700">Recipes</a>
            <a href="login.html" class="block py-2 text-primary">Login</a>
            <a href="register.html" class="block py-2 text-primary font-bold">Sign Up</a>
        `;
    }

    navLinks.innerHTML = desktopHtml;
    if (mobileNavLinks) mobileNavLinks.innerHTML = mobileHtml;
}

function logout() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = 'index.html';
}

function toggleMobileMenu() {
    const menu = document.getElementById('mobile-menu');
    menu.classList.toggle('hidden');
}

// Show Toast Notification
function showToast(message, type = 'success') {
    const toast = document.createElement('div');
    toast.className = `fixed bottom-5 right-5 px-6 py-3 rounded-lg shadow-xl text-white font-medium z-50 transform transition-all duration-300 translate-y-10 opacity-0 ${type === 'success' ? 'bg-green-500' : 'bg-red-500'}`;
    toast.textContent = message;
    
    document.body.appendChild(toast);
    
    // Animate in
    setTimeout(() => {
        toast.classList.remove('translate-y-10', 'opacity-0');
    }, 10);

    // Remove after 3s
    setTimeout(() => {
        toast.classList.add('translate-y-10', 'opacity-0');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}
