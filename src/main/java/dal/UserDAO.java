package dal;

import model.entity.User;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;
import java.util.UUID;

public class UserDAO {

    private static final String SELECT_WITH_ROLE =
            "SELECT u.id, u.role_id, r.role_name, u.email, u.username, u.phone_number, "
                    + "u.password_hash, u.full_name, u.date_of_birth, u.avatar_url, u.status, "
                    + "u.loyalty_points, u.last_login_at, u.created_at "
                    + "FROM Users u "
                    + "INNER JOIN Roles r ON u.role_id = r.id "
                    + "WHERE u.email = ? OR u.username = ?";

    private static final String UPDATE_LAST_LOGIN =
            "UPDATE Users SET last_login_at = GETDATE() WHERE id = ?";

    public Optional<User> findByEmailOrUsername(String identifier) {
        if (identifier == null || identifier.isBlank()) {
            return Optional.empty();
        }

        String trimmed = identifier.trim();

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(SELECT_WITH_ROLE)) {

            ps.setString(1, trimmed);
            ps.setString(2, trimmed);

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("Failed to find user by identifier", e);
        }

        return Optional.empty();
    }

    public void updateLastLoginAt(UUID userId) {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(UPDATE_LAST_LOGIN)) {

            ps.setString(1, userId.toString());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("Failed to update last login time", e);
        }
    }

    private User mapRow(ResultSet rs) throws SQLException {
        User user = new User();
        user.setId(DaoUtil.getUuid(rs, "id"));
        user.setRoleId(DaoUtil.getUuid(rs, "role_id"));
        user.setRoleName(rs.getString("role_name"));
        user.setEmail(rs.getString("email"));
        user.setUsername(rs.getString("username"));
        user.setPhoneNumber(rs.getString("phone_number"));
        String passwordHash = rs.getString("password_hash");
        user.setPasswordHash(passwordHash != null ? passwordHash.trim() : null);
        user.setFullName(rs.getString("full_name"));
        user.setDateOfBirth(DaoUtil.getLocalDate(rs, "date_of_birth"));
        user.setAvatarUrl(rs.getString("avatar_url"));
        user.setStatus(rs.getString("status"));
        user.setLoyaltyPoints(rs.getInt("loyalty_points"));
        user.setLastLoginAt(DaoUtil.getLocalDateTime(rs, "last_login_at"));
        user.setCreatedAt(DaoUtil.getLocalDateTime(rs, "created_at"));
        return user;
    }
}
