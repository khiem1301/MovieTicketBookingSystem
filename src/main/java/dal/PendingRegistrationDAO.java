package dal;

import model.entity.PendingRegistration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Lưu đăng ký chờ xác thực email — chưa tạo bản ghi {@code Users}.
 */
public class PendingRegistrationDAO {

    /**
     * Thay thế pending theo email (nếu đã đăng ký lại), trả về token thô để gửi mail.
     */
    public String upsert(PendingRegistration pending, int expiryMinutes) {
        deleteByEmail(pending.getEmail());
        deleteExpired();

        String id = UUID.randomUUID().toString();
        String token = UUID.randomUUID().toString().replace("-", "")
                + UUID.randomUUID().toString().replace("-", "");

        String sql = """
                INSERT INTO PendingRegistrations (
                    id, email, phone_number, password_hash, full_name, date_of_birth,
                    token, expired_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, DATEADD(MINUTE, ?, GETDATE()))
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.setString(2, pending.getEmail());
            ps.setString(3, pending.getPhoneNumber());
            ps.setString(4, pending.getPasswordHash());
            ps.setString(5, pending.getFullName());
            ps.setDate(6, pending.getDateOfBirth());
            ps.setString(7, token);
            ps.setInt(8, expiryMinutes);
            ps.executeUpdate();
            return token;
        } catch (SQLException e) {
            throw new RuntimeException("upsert pending registration failed", e);
        }
    }

    public Optional<PendingRegistration> findValidByToken(String token) {
        String sql = """
                SELECT id, email, phone_number, password_hash, full_name, date_of_birth,
                       token, expired_at, used_at, created_at
                FROM PendingRegistrations
                WHERE token = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                PendingRegistration row = mapRow(rs);
                if (row.getUsedAt() != null) {
                    return Optional.empty();
                }
                if (row.getExpiredAt() == null || row.getExpiredAt().isBefore(LocalDateTime.now())) {
                    return Optional.empty();
                }
                return Optional.of(row);
            }
        } catch (SQLException e) {
            throw new RuntimeException("findValidByToken pending registration failed", e);
        }
    }

    public void markUsed(String id) {
        String sql = "UPDATE PendingRegistrations SET used_at = GETDATE() WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("markUsed pending registration failed", e);
        }
    }

    public void deleteByEmail(String email) {
        if (email == null || email.isBlank()) {
            return;
        }
        String sql = "DELETE FROM PendingRegistrations WHERE email = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email.trim().toLowerCase());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("deleteByEmail pending registration failed", e);
        }
    }

    public void deleteById(String id) {
        String sql = "DELETE FROM PendingRegistrations WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("deleteById pending registration failed", e);
        }
    }

    /** Dọn pending hết hạn / đã dùng để tránh rác. */
    public void deleteExpired() {
        String sql = """
                DELETE FROM PendingRegistrations
                WHERE used_at IS NOT NULL
                   OR expired_at < GETDATE()
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("deleteExpired pending registration failed", e);
        }
    }

    private PendingRegistration mapRow(ResultSet rs) throws SQLException {
        PendingRegistration p = new PendingRegistration();
        p.setId(rs.getString("id"));
        p.setEmail(rs.getString("email"));
        p.setPhoneNumber(rs.getString("phone_number"));
        p.setPasswordHash(rs.getString("password_hash"));
        p.setFullName(rs.getString("full_name"));
        p.setDateOfBirth(rs.getDate("date_of_birth"));
        p.setToken(rs.getString("token"));
        if (rs.getTimestamp("expired_at") != null) {
            p.setExpiredAt(rs.getTimestamp("expired_at").toLocalDateTime());
        }
        if (rs.getTimestamp("used_at") != null) {
            p.setUsedAt(rs.getTimestamp("used_at").toLocalDateTime());
        }
        if (rs.getTimestamp("created_at") != null) {
            p.setCreatedAt(rs.getTimestamp("created_at").toLocalDateTime());
        }
        return p;
    }
}
