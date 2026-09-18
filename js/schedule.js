import { supabase, getCurrentUser } from './supabase.js';
import { showToast } from './app.js';

const schedulesContainer = document.getElementById('schedules-container');
let currentUser = null;

// Lấy danh sách lịch tập và số lượng booking hiện tại
const loadSchedules = async () => {
    if (!schedulesContainer) return;
    
    // Fetch user để kiểm tra quyền đăng ký
    currentUser = await getCurrentUser();

    // Query join các bảng liên quan
    const { data: schedules, error } = await supabase
        .from('schedules')
        .select(`
            id, title, start_time, end_time, capacity, status,
            gym_locations (name, map_url),
            workout_types (name),
            bookings (id, status, user_id)
        `)
        .in('status', ['OPEN', 'FULL'])
        .order('start_time', { ascending: true });

    if (error) {
        schedulesContainer.innerHTML = `<p class="text-center" style="color: var(--danger-color);">Lỗi tải dữ liệu: ${error.message}</p>`;
        return;
    }

    if (schedules.length === 0) {
        schedulesContainer.innerHTML = `<div class="text-center" style="padding: 40px; color: var(--text-muted);">Chưa có buổi tập nào sắp tới.</div>`;
        return;
    }

    renderSchedules(schedules);
};

// Hiển thị Card Lịch Tập
const renderSchedules = (schedules) => {
    schedulesContainer.innerHTML = '';

    schedules.forEach(schedule => {
        // Đếm số người đã Confirmed
        const confirmedCount = schedule.bookings.filter(b => b.status === 'CONFIRMED').length;
        const slotsLeft = schedule.capacity - confirmedCount;
        const capacityPercent = (confirmedCount / schedule.capacity) * 100;
        
        // Kiểm tra user hiện tại đã đăng ký chưa
        const isBooked = currentUser && schedule.bookings.some(b => b.user_id === currentUser.id && b.status !== 'CANCELLED');
        
        // Render Badge trạng thái
        let badgeHTML = '';
        if (schedule.status === 'FULL') {
            badgeHTML = `<span class="badge full"><i class='bx bx-x-circle'></i> FULL</span>`;
        } else if (slotsLeft <= 2) {
            badgeHTML = `<span class="badge waitlist"><i class='bx bx-error'></i> Gần đầy</span>`;
        } else {
            badgeHTML = `<span class="badge open"><i class='bx bx-check-circle'></i> Còn ${slotsLeft} slot</span>`;
        }

        // Render Nút bấm
        let buttonHTML = '';
        if (!currentUser) {
            buttonHTML = `<button class="btn btn-outline" onclick="window.location.href='login.html'">ĐĂNG NHẬP ĐỂ ĐĂNG KÝ</button>`;
        } else if (isBooked) {
            buttonHTML = `<button class="btn btn-outline" disabled>ĐÃ ĐĂNG KÝ</button>`;
        } else {
            buttonHTML = `<button class="btn btn-primary" onclick="window.bookSession('${schedule.id}')">ĐĂNG KÝ NGAY</button>`;
        }

        // Định dạng thời gian
        const date = new Date(schedule.start_time).toLocaleDateString('vi-VN');
        const timeStart = new Date(schedule.start_time).toLocaleTimeString('vi-VN', {hour: '2-digit', minute:'2-digit'});
        
        const card = document.createElement('div');
        card.className = 'schedule-card';
        card.innerHTML = `
            <div class="card-header">
                <div>
                    <div class="card-title">${schedule.workout_types?.name || ''} - ${schedule.title}</div>
                    <div class="card-meta"><i class='bx bx-calendar'></i> ${date}</div>
                    <div class="card-meta"><i class='bx bx-time'></i> ${timeStart}</div>
                    <div class="card-meta"><i class='bx bx-map'></i> 
                        <a href="${schedule.gym_locations?.map_url || '#'}" target="_blank" style="text-decoration:underline">${schedule.gym_locations?.name}</a>
                    </div>
                </div>
                ${badgeHTML}
            </div>
            <div class="capacity-bar">
                <div class="capacity-fill" style="width: ${capacityPercent}%; background: ${schedule.status === 'FULL' ? 'var(--danger-color)' : 'var(--primary-color)'}"></div>
            </div>
            <div style="display: flex; justify-content: space-between; font-size: 13px; color: var(--text-muted); margin-bottom: 16px;">
                <span>Đã đăng ký: ${confirmedCount}/${schedule.capacity}</span>
            </div>
            ${buttonHTML}
        `;
        schedulesContainer.appendChild(card);
    });
};

// Gọi Function book_schedule (RPC) trong Postgres
window.bookSession = async (scheduleId) => {
    if (!confirm('Bạn có chắc chắn muốn đăng ký tham gia buổi tập này?')) return;
    
    // Hiển thị loading overlay hoặc toast
    showToast('Đang xử lý đăng ký...', 'success');

    const { data, error } = await supabase.rpc('book_schedule', {
        p_schedule_id: scheduleId,
        p_note: 'Đăng ký qua Website'
    });

    if (error) {
        showToast(error.message, 'error');
    } else {
        showToast(data.status === 'WAITLIST' ? 'Bạn đã được đưa vào danh sách chờ (Waitlist)' : '✓ Đăng ký thành công!');
        loadSchedules(); // Khuyến khích: Mặc dù có Realtime, ta gọi lại luôn để UI cập nhật ngay cho người dùng
    }
};

// THIẾT LẬP SUPABASE REALTIME
// Lắng nghe mọi thay đổi trên bảng 'bookings' và 'schedules' để cập nhật số Slot trực tiếp cho tất cả mọi người
if (schedulesContainer) {
    loadSchedules();

    supabase.channel('public:any_changes')
        .on('postgres_changes', { event: '*', schema: 'public', table: 'bookings' }, payload => {
            loadSchedules(); // Reload data ngầm khi có người đăng ký/hủy
        })
        .on('postgres_changes', { event: '*', schema: 'public', table: 'schedules' }, payload => {
            loadSchedules();
        })
        .subscribe();
}