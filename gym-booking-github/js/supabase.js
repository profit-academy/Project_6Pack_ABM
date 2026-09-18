import { createClient } from 'https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.39.3/+esm';
import { CONFIG } from './config.js';

// Khởi tạo Supabase Client
export const supabase = createClient(CONFIG.SUPABASE_URL, CONFIG.SUPABASE_ANON_KEY);

// Helper function để lấy user hiện tại
export const getCurrentUser = async () => {
    const { data: { session }, error } = await supabase.auth.getSession();
    if (error || !session) return null;
    
    // Lấy thêm profile data (Role, Fullname)
    const { data: profile } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', session.user.id)
        .single();
        
    return { ...session.user, profile };
};