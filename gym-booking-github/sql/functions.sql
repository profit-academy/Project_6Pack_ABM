-- 1. Trigger Tự động tạo Profile khi User đăng ký qua Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, role)
  VALUES (
      new.id, 
      COALESCE(new.raw_user_meta_data->>'full_name', 'Gym Member'), 
      -- Nếu là user đầu tiên trong DB, cấp quyền OWNER
      CASE 
        WHEN NOT EXISTS (SELECT 1 FROM public.profiles) THEN 'OWNER'::user_role
        ELSE 'MEMBER'::user_role
      END
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 2. Hàm Xử lý Booking An Toàn (Chống Overbooking & Xử lý Waitlist)
CREATE OR REPLACE FUNCTION public.book_schedule(p_schedule_id UUID, p_note TEXT)
RETURNS json AS $$
DECLARE
    v_capacity INT;
    v_confirmed_count INT;
    v_status booking_status;
    v_booking_id UUID;
BEGIN
    -- Lấy capacity của lịch tập, lock row để tránh race condition
    SELECT capacity INTO v_capacity FROM schedules WHERE id = p_schedule_id FOR UPDATE;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Lịch tập không tồn tại';
    END IF;

    -- Đếm số người đã CONFIRMED
    SELECT COUNT(*) INTO v_confirmed_count FROM bookings 
    WHERE schedule_id = p_schedule_id AND status = 'CONFIRMED';

    -- Quyết định trạng thái
    IF v_confirmed_count < v_capacity THEN
        v_status := 'CONFIRMED';
    ELSE
        v_status := 'WAITLIST';
    END IF;

    -- Insert booking
    INSERT INTO bookings (schedule_id, user_id, status, note)
    VALUES (p_schedule_id, auth.uid(), v_status, p_note)
    RETURNING id INTO v_booking_id;

    -- Tự động cập nhật trạng thái schedule sang FULL nếu vừa đủ người
    IF v_status = 'CONFIRMED' AND (v_confirmed_count + 1) >= v_capacity THEN
        UPDATE schedules SET status = 'FULL' WHERE id = p_schedule_id AND status = 'OPEN';
    END IF;

    RETURN json_build_object('booking_id', v_booking_id, 'status', v_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Trigger Tự động đôn Waitlist lên Confirmed khi có người Hủy
CREATE OR REPLACE FUNCTION public.handle_booking_cancellation()
RETURNS trigger AS $$
DECLARE
    v_waitlist_id UUID;
    v_waitlist_user UUID;
BEGIN
    -- Nếu 1 booking CONFIRMED bị đổi thành CANCELLED
    IF OLD.status = 'CONFIRMED' AND NEW.status = 'CANCELLED' THEN
        -- Tìm người đăng ký WAITLIST sớm nhất
        SELECT id, user_id INTO v_waitlist_id, v_waitlist_user
        FROM bookings
        WHERE schedule_id = OLD.schedule_id AND status = 'WAITLIST'
        ORDER BY created_at ASC
        LIMIT 1;

        -- Nếu có người đợi, chuyển thành CONFIRMED
        IF v_waitlist_id IS NOT NULL THEN
            UPDATE bookings SET status = 'CONFIRMED', updated_at = NOW() WHERE id = v_waitlist_id;
            
            -- Bắn thông báo cho người được đẩy lên
            INSERT INTO notifications (user_id, title, message, type)
            VALUES (v_waitlist_user, 'Cập nhật Waitlist!', 'Bạn đã được chuyển từ WAITLIST sang CONFIRMED cho buổi tập sắp tới.', 'WAITLIST_SUCCESS');
        ELSE
            -- Nếu không ai đợi, mở lại lịch nếu đang FULL
            UPDATE schedules SET status = 'OPEN' WHERE id = OLD.schedule_id AND status = 'FULL';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_booking_cancelled
  AFTER UPDATE OF status ON bookings
  FOR EACH ROW EXECUTE PROCEDURE public.handle_booking_cancellation();