package dal;

import model.entity.User;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

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

    public Optional<User> findByEmail(String email) {
        if (email == null || email.isBlank()) {
            return Optional.empty();
        }
        String sql = SELECT_WITH_ROLE + " WHERE u.email = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, email.trim().toLowerCase());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findByEmail failed", e);
        }
        return Optional.empty();
    }

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

    public Optional<User> findById(String userId) {
        String sql = SELECT_WITH_ROLE + " WHERE u.id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findById failed", e);
        }
        return Optional.empty();
    }

    public List<User> findAll(String keyword, String roleName, String status, int offset, int limit) {
        StringBuilder sql = new StringBuilder(SELECT_WITH_ROLE);
        sql.append(" WHERE 1=1");
        appendFilters(sql, keyword, roleName, status);
        sql.append(" ORDER BY u.created_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        List<User> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = bindFilters(ps, 1, keyword, roleName, status);
            ps.setInt(idx, offset);
            ps.setInt(idx + 1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findAll users failed", e);
        }
        return result;
    }

    public int countAll(String keyword, String roleName, String status) {
        StringBuilder sql = new StringBuilder("""
                SELECT COUNT(*) AS total
                FROM Users u
                INNER JOIN Roles r ON u.role_id = r.id
                WHERE 1=1
                """);
        appendFilters(sql, keyword, roleName, status);

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            bindFilters(ps, 1, keyword, roleName, status);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("countAll users failed", e);
        }
        return 0;
    }

    public boolean existsByEmail(String email) {
        return existsByColumn("email", email);
    }

    public boolean existsByUsername(String username) {
        return existsByColumn("username", username);
    }

    public boolean existsByPhone(String phone) {
        return existsByColumn("phone_number", phone);
    }

    public String insert(User user) {
        String id = UUID.randomUUID().toString();
        String sql = """
                INSERT INTO Users (
                    id, role_id, email, username, phone_number,
                    password_hash, full_name, date_of_birth, status, loyalty_points
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.setString(2, user.getRoleId());
            ps.setString(3, blankToNull(user.getEmail()));
            ps.setString(4, blankToNull(user.getUsername()));
            ps.setString(5, blankToNull(user.getPhoneNumber()));
            ps.setString(6, user.getPasswordHash());
            ps.setString(7, user.getFullName());
            ps.setDate(8, user.getDateOfBirth());
            ps.setString(9, user.getStatus() != null ? user.getStatus() : "ACTIVE");
            ps.executeUpdate();
            return id;
        } catch (SQLException e) {
            throw new RuntimeException("insert user failed", e);
        }
    }

    public void updateGoogleProfile(String userId, String fullName, String avatarUrl) {
        String sql = """
                UPDATE Users
                SET full_name = CASE WHEN ? IS NOT NULL AND LTRIM(RTRIM(?)) <> '' THEN ? ELSE full_name END,
                    avatar_url = CASE WHEN ? IS NOT NULL AND LTRIM(RTRIM(?)) <> '' THEN ? ELSE avatar_url END
                WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, fullName);
            ps.setString(2, fullName);
            ps.setString(3, fullName);
            ps.setString(4, avatarUrl);
            ps.setString(5, avatarUrl);
            ps.setString(6, avatarUrl);
            ps.setString(7, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("updateGoogleProfile failed", e);
        }
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

    public void updateStatus(String userId, String status) {
        String sql = "UPDATE Users SET status = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("updateStatus failed", e);
        }
    }

    public void updatePasswordHash(String userId, String passwordHash) {
        String sql = "UPDATE Users SET password_hash = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, passwordHash);
            ps.setString(2, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("updatePasswordHash failed", e);
        }
    }

    private boolean existsByColumn(String column, String value) {
        if (value == null || value.isBlank()) {
            return false;
        }
        String sql = "SELECT 1 FROM Users WHERE " + column + " = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, value.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            throw new RuntimeException("existsByColumn failed", e);
        }
    }

    private void appendFilters(StringBuilder sql, String keyword, String roleName, String status) {
        if (keyword != null && !keyword.isBlank()) {
            sql.append("""
                     AND (
                         u.full_name LIKE ? OR u.email LIKE ? OR
                         u.username LIKE ? OR u.phone_number LIKE ?
                     )
                    """);
        }
        if (roleName != null && !roleName.isBlank()) {
            sql.append(" AND r.role_name = ?");
        }
        if (status != null && !status.isBlank()) {
            sql.append(" AND u.status = ?");
        }
    }

    private int bindFilters(PreparedStatement ps, int startIndex,
                            String keyword, String roleName, String status) throws SQLException {
        int idx = startIndex;
        if (keyword != null && !keyword.isBlank()) {
            String pattern = "%" + keyword.trim() + "%";
            ps.setString(idx++, pattern);
            ps.setString(idx++, pattern);
            ps.setString(idx++, pattern);
            ps.setString(idx++, pattern);
        }
        if (roleName != null && !roleName.isBlank()) {
            ps.setString(idx++, roleName.trim());
        }
        if (status != null && !status.isBlank()) {
            ps.setString(idx++, status.trim());
        }
        return idx;
    }

    private String blankToNull(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
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
