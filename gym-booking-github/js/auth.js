import { supabase } from './supabase.js';
import { showToast } from './app.js';

// Xử lý Đăng nhập
const loginForm = document.getElementById('login-form');
if (loginForm) {
    loginForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const btn = loginForm.querySelector('button');

        btn.classList.add('loading');
        
        const { data, error } = await supabase.auth.signInWithPassword({ email, password });
        
        btn.classList.remove('loading');

        if (error) {
            showToast(error.message === 'Invalid login credentials' ? 'Sai email hoặc mật khẩu' : error.message, 'error');
        } else {
            showToast('Đăng nhập thành công!');
            setTimeout(() => window.location.href = 'index.html', 1000);
        }
    });
}

// Xử lý Đăng ký
const registerForm = document.getElementById('register-form');
if (registerForm) {
    registerForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        const fullname = document.getElementById('fullname').value;
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;
        const btn = registerForm.querySelector('button');

        btn.classList.add('loading');

        // Supabase Auth Register kèm metadata
        const { data, error } = await supabase.auth.signUp({
            email,
            password,
            options: {
                data: { full_name: fullname } // Sẽ được Trigger trong functions.sql sử dụng
            }
        });

        btn.classList.remove('loading');

        if (error) {
            showToast(error.message, 'error');
        } else {
            showToast('Đăng ký thành công! Vui lòng đăng nhập.');
            setTimeout(() => window.location.href = 'login.html', 1500);
        }
    });
}