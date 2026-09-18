-- Bật RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE website_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Hàm kiểm tra Role (Dùng trong Policies)
CREATE OR REPLACE FUNCTION public.is_admin_or_owner()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role IN ('ADMIN', 'OWNER')
  );
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.is_owner()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() AND role = 'OWNER'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- POLICIES CHO PROFILES
CREATE POLICY "Public profiles are viewable by everyone" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Owners can update any profile" ON profiles FOR UPDATE USING (is_owner());

-- POLICIES CHO SCHEDULES
CREATE POLICY "Schedules are viewable by everyone" ON schedules FOR SELECT USING (true);
CREATE POLICY "Admins can insert schedules" ON schedules FOR INSERT WITH CHECK (is_admin_or_owner());
CREATE POLICY "Admins can update schedules" ON schedules FOR UPDATE USING (is_admin_or_owner());
CREATE POLICY "Admins can delete schedules" ON schedules FOR DELETE USING (is_admin_or_owner());

-- POLICIES CHO BOOKINGS
CREATE POLICY "Users view own bookings, Admins view all" ON bookings FOR SELECT 
  USING (auth.uid() = user_id OR is_admin_or_owner());
-- Insert được xử lý qua Function (book_schedule) SECURITY DEFINER, nhưng nếu dùng API trực tiếp:
CREATE POLICY "Users can insert own bookings" ON bookings FOR INSERT WITH CHECK (auth.uid() = user_id);
-- Chỉ cho phép user TỰ HỦY (update status -> CANCELLED), không cho phép đổi của người khác
CREATE POLICY "Users can cancel own bookings" ON bookings FOR UPDATE 
  USING (auth.uid() = user_id) 
  WITH CHECK (auth.uid() = user_id AND status = 'CANCELLED');
CREATE POLICY "Admins can update any booking" ON bookings FOR UPDATE USING (is_admin_or_owner());

-- POLICIES CHO GYM LOCATIONS & WORKOUT TYPES
CREATE POLICY "Public read locations" ON gym_locations FOR SELECT USING (true);
CREATE POLICY "Admins manage locations" ON gym_locations FOR ALL USING (is_admin_or_owner());

CREATE POLICY "Public read workout types" ON workout_types FOR SELECT USING (true);
CREATE POLICY "Admins manage workout types" ON workout_types FOR ALL USING (is_admin_or_owner());

-- POLICIES CHO NOTIFICATIONS
CREATE POLICY "Users view own notifications" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can update own notifications (read)" ON notifications FOR UPDATE USING (auth.uid() = user_id);

-- POLICIES CHO WEBSITE SETTINGS
CREATE POLICY "Public read settings" ON website_settings FOR SELECT USING (true);
CREATE POLICY "Only Owners update settings" ON website_settings FOR UPDATE USING (is_owner());