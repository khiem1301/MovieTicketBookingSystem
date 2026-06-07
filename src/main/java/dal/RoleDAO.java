package dal;

import model.entity.Role;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class RoleDAO {

    public List<Role> findAll() {
        String sql = "SELECT id, role_name, description, created_at FROM Roles ORDER BY role_name";
        List<Role> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findAll roles failed", e);
        }
        return result;
    }

    public Optional<Role> findByName(String roleName) {
        String sql = "SELECT id, role_name, description, created_at FROM Roles WHERE role_name = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roleName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findByName role failed", e);
        }
        return Optional.empty();
    }

    public List<Role> findAssignableByAdmin() {
        String sql = """
                SELECT id, role_name, description, created_at
                FROM Roles
                WHERE role_name IN ('STAFF', 'MANAGER')
                ORDER BY role_name
                """;
        List<Role> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findAssignableByAdmin failed", e);
        }
        return result;
    }

    private Role mapRow(ResultSet rs) throws SQLException {
        Role role = new Role();
        role.setId(rs.getString("id"));
        role.setRoleName(rs.getString("role_name"));
        role.setDescription(rs.getString("description"));
        role.setCreatedAt(rs.getTimestamp("created_at"));
        return role;
    }
}
