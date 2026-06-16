-- Migration: thêm cấu hình Google OAuth vào SystemConfig
-- Chạy file này 1 lần trên DB của bạn
-- ⚠ Điền Client ID và Client Secret thực vào trước khi chạy

IF NOT EXISTS (SELECT 1 FROM SystemConfig WHERE config_key = 'google_client_id')
    INSERT INTO SystemConfig (config_key, config_value, description)
    VALUES ('google_client_id',
            'YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com',
            N'Google OAuth 2.0 Client ID');

IF NOT EXISTS (SELECT 1 FROM SystemConfig WHERE config_key = 'google_client_secret')
    INSERT INTO SystemConfig (config_key, config_value, description)
    VALUES ('google_client_secret',
            'YOUR_GOOGLE_CLIENT_SECRET',
            N'Google OAuth 2.0 Client Secret');

IF NOT EXISTS (SELECT 1 FROM SystemConfig WHERE config_key = 'google_redirect_uri')
    INSERT INTO SystemConfig (config_key, config_value, description)
    VALUES ('google_redirect_uri',
            'http://localhost:8080/MovieTicketBookingSystem/auth/google/callback',
            N'Google OAuth 2.0 Redirect URI — phải khớp với URI đã đăng ký trên Google Console');
