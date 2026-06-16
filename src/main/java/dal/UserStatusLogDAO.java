package dal;

import model.entity.UserStatusLog;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;
import java.util.UUID;

public class UserStatusLogDAO {

    private static final String SELECT_COLUMNS = """
            SELECT l.id, l.user_id, l.action, l.previous_status, l.new_status,
                   l.reason, l.email_sent, l.email_error, l.performed_by, l.performed_at,
                   u.full_name AS performed_by_name
            FROM UserStatusLog l
            LEFT JOIN Users u ON l.performed_by = u.id
            """;

    public void insert(UserStatusLog log) {
        String sql = """
                INSERT INTO UserStatusLog (
                    id, user_id, action, previous_status, new_status,
                    reason, email_sent, email_error, performed_by, performed_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, log.getId() != null ? log.getId() : UUID.randomUUID().toString());
            ps.setString(2, log.getUserId());
            ps.setString(3, log.getAction());
            ps.setString(4, log.getPreviousStatus());
            ps.setString(5, log.getNewStatus());
            ps.setString(6, log.getReason());
            ps.setBoolean(7, log.isEmailSent());
            ps.setString(8, log.getEmailError());
            ps.setString(9, log.getPerformedBy());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("insert UserStatusLog failed", e);
        }
    }

    public Optional<UserStatusLog> findLatestLockByUserId(String userId) {
        if (userId == null || userId.isBlank()) {
            return Optional.empty();
        }
        String sql = SELECT_COLUMNS + """
                WHERE l.user_id = ? AND l.action = 'LOCK'
                ORDER BY l.performed_at DESC
                OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findLatestLockByUserId failed", e);
        }
        return Optional.empty();
    }

    private UserStatusLog mapRow(ResultSet rs) throws SQLException {
        UserStatusLog log = new UserStatusLog();
        log.setId(rs.getString("id"));
        log.setUserId(rs.getString("user_id"));
        log.setAction(rs.getString("action"));
        log.setPreviousStatus(rs.getString("previous_status"));
        log.setNewStatus(rs.getString("new_status"));
        log.setReason(rs.getString("reason"));
        log.setEmailSent(rs.getBoolean("email_sent"));
        log.setEmailError(rs.getString("email_error"));
        log.setPerformedBy(rs.getString("performed_by"));
        log.setPerformedByName(rs.getString("performed_by_name"));
        log.setPerformedAt(rs.getTimestamp("performed_at"));
        return log;
    }
}
