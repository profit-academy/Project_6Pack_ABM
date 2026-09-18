# GYM TOGETHER - Hệ thống Booking Lịch Tập

## 1. Công nghệ sử dụng
- **Frontend:** HTML5, CSS3, JavaScript ES6 (Thuần, không build tool).
- **Backend/Database:** Supabase (PostgreSQL, Auth, Realtime).
- **Hosting:** GitHub Pages.

## 2. Triển khai Database (Supabase)
1. Truy cập [Supabase.com](https://supabase.com/) và tạo Project mới.
2. Mở mục **SQL Editor** trong menu bên trái.
3. Chạy lần lượt các file SQL theo đúng thứ tự:
   - Chạy `sql/schema.sql` (Tạo bảng).
   - Chạy `sql/functions.sql` (Tạo Trigger, RPC Bookings, Waitlist).
   - Chạy `sql/policies.sql` (Bật Row Level Security).
   - Chạy `sql/seed.sql` (Tạo dữ liệu mẫu Location, Workout Type).
4. Vào **Authentication > Providers** bật `Email` đăng nhập.
5. Tạo user ADMIN đầu tiên: Vào trang Đăng ký (`register.html`) tạo tài khoản đầu tiên. Trigger trong DB sẽ tự động gán tài khoản tạo đầu tiên vào Role là `OWNER`.

## 3. Bật Realtime trên Supabase
1. Truy cập **Database > Publications**.
2. Tìm `supabase_realtime` và click biểu tượng Bánh răng (Settings).
3. Bật Toggle cho bảng `schedules` và `bookings`. Điều này cho phép Frontend nhận Push thay đổi số Slot ngay lập tức mà không cần reload trang.

## 4. Cấu hình Frontend
1. Vào Supabase **Project Settings > API**.
2. Copy `Project URL` và `anon/public key`.
3. Mở file `js/config.js` trong source code và thay thế:
   ```javascript
   export const CONFIG = {
       SUPABASE_URL: "https://<PROJECT-ID>.supabase.co",
       SUPABASE_ANON_KEY: "eyJhbG..."
   };