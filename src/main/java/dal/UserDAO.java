package dal;

import model.entity.User;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;

public class UserDAO {

    private static final String SELECT_WITH_ROLE = """
            SELECT u.id, u.role_id, r.role_name,
                   u.email, u.username, u.phone_number,
                   u.password_hash, u.full_name, u.date_of_birth,
                   u.avatar_url, u.status, u.loyalty_points,
                   u.last_login_at, u.created_at
            FROM Users u
            INNER JOIN Roles r ON u.role_id = r.id
            """;

    public Optional<User> findByEmailOrUsername(String identifier) {
        String sql = SELECT_WITH_ROLE + " WHERE u.email = ? OR u.username = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, identifier);
            ps.setString(2, identifier);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findByEmailOrUsername failed", e);
        }
        return Optional.empty();
    }

    public void updateLastLoginAt(String userId) {
        String sql = "UPDATE Users SET last_login_at = GETDATE() WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("updateLastLoginAt failed", e);
        }
    }

    private User mapRow(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(rs.getString("id"));
        user.setRoleId(rs.getString("role_id"));
        user.setRoleName(rs.getString("role_name"));
        user.setEmail(rs.getString("email"));
        user.setUsername(rs.getString("username"));
        user.setPhoneNumber(rs.getString("phone_number"));
        user.setPasswordHash(rs.getString("password_hash"));
        user.setFullName(rs.getString("full_name"));
        user.setDateOfBirth(rs.getDate("date_of_birth"));
        user.setAvatarUrl(rs.getString("avatar_url"));
        user.setStatus(rs.getString("status"));
        user.setLoyaltyPoints(rs.getInt("loyalty_points"));
        user.setLastLoginAt(rs.getTimestamp("last_login_at"));
        user.setCreatedAt(rs.getTimestamp("created_at"));
        return user;
    }
}
