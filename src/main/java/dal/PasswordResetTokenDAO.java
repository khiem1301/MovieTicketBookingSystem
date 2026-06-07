package dal;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.Optional;
import java.util.UUID;

/**
 * Shared token store for email verification (FR-01) and password reset (FR-04).
 */
public class PasswordResetTokenDAO {

    public record TokenRecord(String id, String userId, String token,
                              LocalDateTime expiredAt, LocalDateTime usedAt) {}

    public String insert(String userId, int expiryMinutes) {
        String id = UUID.randomUUID().toString();
        String token = UUID.randomUUID().toString().replace("-", "")
                + UUID.randomUUID().toString().replace("-", "");
        String sql = """
                INSERT INTO PasswordResetTokens (id, user_id, token, expired_at)
                VALUES (?, ?, ?, DATEADD(MINUTE, ?, GETDATE()))
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.setString(2, userId);
            ps.setString(3, token);
            ps.setInt(4, expiryMinutes);
            ps.executeUpdate();
            return token;
        } catch (SQLException e) {
            throw new RuntimeException("insert token failed", e);
        }
    }

    public Optional<TokenRecord> findValidByToken(String token) {
        String sql = """
                SELECT id, user_id, token, expired_at, used_at
                FROM PasswordResetTokens
                WHERE token = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return Optional.empty();
                }
                TokenRecord record = new TokenRecord(
                        rs.getString("id"),
                        rs.getString("user_id"),
                        rs.getString("token"),
                        rs.getTimestamp("expired_at").toLocalDateTime(),
                        rs.getTimestamp("used_at") != null
                                ? rs.getTimestamp("used_at").toLocalDateTime()
                                : null
                );
                if (record.usedAt() != null) {
                    return Optional.empty();
                }
                if (record.expiredAt().isBefore(LocalDateTime.now())) {
                    return Optional.empty();
                }
                return Optional.of(record);
            }
        } catch (SQLException e) {
            throw new RuntimeException("findValidByToken failed", e);
        }
    }

    public void markUsed(String tokenId) {
        String sql = "UPDATE PasswordResetTokens SET used_at = GETDATE() WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, tokenId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("markUsed token failed", e);
        }
    }

    public void invalidateUnusedForUser(String userId) {
        String sql = """
                UPDATE PasswordResetTokens
                SET used_at = GETDATE()
                WHERE user_id = ? AND used_at IS NULL
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("invalidateUnusedForUser failed", e);
        }
    }
}
