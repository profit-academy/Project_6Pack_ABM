import { supabase, getCurrentUser } from './supabase.js';

document.addEventListener('DOMContentLoaded', async () => {
    const layout = document.getElementById('admin-layout');
    const loader = document.getElementById('admin-auth-loader');
    
    // Auth Guard: Kiểm tra phiên và Quyền
    const user = await getCurrentUser();
    
    if (!user || (user.profile.role !== 'OWNER' && user.profile.role !== 'ADMIN')) {
        // Không có quyền -> Đuổi về trang chủ
        window.location.href = 'index.html';
        return;
    }

    // Có quyền -> Ẩn Loader, Hiện giao diện Admin
    loader.style.display = 'none';
    layout.style.display = 'flex';

    loadDashboardStats();
    
    // Gắn sự kiện Đăng xuất Admin
    document.getElementById('logout-btn').onclick = async () => {
        await supabase.auth.signOut();
        window.location.href = 'index.html';
    };
});

const loadDashboardStats = async () => {
    // 1. Tổng Thành Viên
    const { count: membersCount } = await supabase.from('profiles').select('*', { count: 'exact', head: true });
    document.getElementById('stat-members').innerText = membersCount || 0;

    // 2. Lịch Sắp Tới
    const { count: schedulesCount } = await supabase.from('schedules').select('*', { count: 'exact', head: true }).in('status', ['OPEN', 'FULL']);
    document.getElementById('stat-schedules').innerText = schedulesCount || 0;

    // 3. Render danh sách lịch
    const { data: schedules } = await supabase.from('schedules').select('title, start_time, capacity, status').order('start_time', { ascending: false }).limit(5);
    
    const tbody = document.getElementById('admin-schedules-list');
    tbody.innerHTML = '';
    
    if(schedules && schedules.length > 0) {
        schedules.forEach(sc => {
            tbody.innerHTML += `
                <tr>
                    <td style="font-weight: 600;">${sc.title}</td>
                    <td>${new Date(sc.start_time).toLocaleDateString('vi-VN')}</td>
                    <td>Max: ${sc.capacity}</td>
                    <td><span class="badge ${sc.status === 'FULL' ? 'full' : 'open'}">${sc.status}</span></td>
                    <td>
                        <button class="action-btn" title="Chỉnh sửa"><i class='bx bx-edit'></i></button>
                    </td>
                </tr>
            `;
        });
    } else {
        tbody.innerHTML = `<tr><td colspan="5" class="text-center">Chưa có dữ liệu</td></tr>`;
    }
};