import { supabase, getCurrentUser } from './supabase.js';

// Hệ thống hiển thị thông báo góc trên màn hình
export const showToast = (message, type = 'success') => {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast ${type === 'error' ? 'error' : ''}`;
    toast.innerHTML = `
        <i class='bx ${type === 'error' ? 'bx-error-circle' : 'bx-check-circle'}'></i>
        <span>${message}</span>
    `;

    container.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(-20px)';
        setTimeout(() => toast.remove(), 300);
    }, 3000);
};

// Cập nhật giao diện thanh điều hướng dựa trên trạng thái đăng nhập
const updateNavigation = async () => {
    const user = await getCurrentUser();
    const navLogin = document.getElementById('nav-login');
    const navAdmin = document.getElementById('nav-admin');
    const mobileNavAdmin = document.getElementById('mobile-nav-admin');

    if (user) {
        // Đã đăng nhập: Đổi nút Đăng nhập thành Đăng xuất
        if (navLogin) {
            navLogin.innerHTML = 'Đăng xuất';
            navLogin.href = '#';
            navLogin.onclick = async (e) => {
                e.preventDefault();
                await supabase.auth.signOut();
                window.location.href = 'index.html';
            };
        }

        // Hiện nút Admin nếu có quyền
        if (user.profile && (user.profile.role === 'ADMIN' || user.profile.role === 'OWNER')) {
            if (navAdmin) navAdmin.classList.remove('hidden');
            if (mobileNavAdmin) mobileNavAdmin.classList.remove('hidden');
        }
    }
};

// Chạy khi trang web vừa tải xong
document.addEventListener('DOMContentLoaded', () => {
    updateNavigation();
});