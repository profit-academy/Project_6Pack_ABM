INSERT INTO website_settings (id, group_name) VALUES (1, 'GYM TOGETHER') ON CONFLICT DO NOTHING;

INSERT INTO workout_types (name, description, icon) VALUES 
('Push Day', 'Tập trung ngực, vai, tay sau', '💪'),
('Pull Day', 'Tập trung lưng, xô, tay trước', '🏋️'),
('Leg Day', 'Tập trung đùi, mông, bắp chân', '🦵'),
('Full Body', 'Tập toàn thân', '🔥'),
('Cardio / HIIT', 'Tập thể lực, tim mạch', '❤️');

INSERT INTO gym_locations (name, address, map_url) VALUES 
('California Fitness', '123 Nguyễn Văn Linh, Q7, HCM', 'https://maps.google.com'),
('City Gym', '456 Lê Lợi, Q1, HCM', 'https://maps.google.com');