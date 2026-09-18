-- Kích hoạt extension uuid
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. ENUMS
CREATE TYPE user_role AS ENUM ('OWNER', 'ADMIN', 'MEMBER');
CREATE TYPE schedule_status AS ENUM ('OPEN', 'FULL', 'CLOSED', 'COMPLETED', 'CANCELLED');
CREATE TYPE booking_status AS ENUM ('CONFIRMED', 'WAITLIST', 'CANCELLED', 'ATTENDED', 'NO_SHOW');

-- 2. TABLES

-- Bảng Profiles (Liên kết 1-1 với auth.users của Supabase)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    phone TEXT,
    avatar_url TEXT,
    gender TEXT,
    date_of_birth DATE,
    height NUMERIC,
    weight NUMERIC,
    goal TEXT,
    role user_role DEFAULT 'MEMBER'::user_role NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng Địa điểm tập (Gym Locations)
CREATE TABLE gym_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    map_url TEXT,
    description TEXT,
    image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng Loại bài tập (Workout Types)
CREATE TABLE workout_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    icon TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng Lịch tập (Schedules)
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT,
    location_id UUID REFERENCES gym_locations(id) ON DELETE SET NULL,
    workout_type_id UUID REFERENCES workout_types(id) ON DELETE SET NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    capacity INTEGER NOT NULL CHECK (capacity > 0),
    status schedule_status DEFAULT 'OPEN'::schedule_status NOT NULL,
    created_by UUID REFERENCES profiles(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng Đăng ký (Bookings)
CREATE TABLE bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id UUID REFERENCES schedules(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    status booking_status DEFAULT 'CONFIRMED'::booking_status NOT NULL,
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    -- Đảm bảo 1 user không thể đăng ký 1 buổi tập nhiều lần
    UNIQUE(schedule_id, user_id)
);

-- Bảng Thông báo (Notifications)
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng Cài đặt Website (Chỉ Owner sửa)
CREATE TABLE website_settings (
    id INT PRIMARY KEY DEFAULT 1,
    group_name TEXT DEFAULT 'GYM TOGETHER',
    slogan TEXT DEFAULT 'Train Together. Get Stronger.',
    hero_image_url TEXT,
    logo_url TEXT,
    rules_text TEXT,
    primary_color TEXT DEFAULT '#00ff88',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (id = 1) -- Chỉ cho phép 1 dòng cài đặt
);