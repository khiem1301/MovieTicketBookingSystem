package dal;

import model.entity.SystemConfig;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class SystemConfigDAO {

    private static final String SELECT_WITH_UPDATER = """
            SELECT c.config_key, c.config_value, c.description,
                   c.updated_by, c.updated_at,
                   u.full_name AS updated_by_name
            FROM SystemConfig c
            LEFT JOIN Users u ON c.updated_by = u.id
            """;

    public List<SystemConfig> findAll() {
        String sql = SELECT_WITH_UPDATER + " ORDER BY c.config_key";
        List<SystemConfig> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findAll SystemConfig failed", e);
        }
        return result;
    }

    public List<SystemConfig> findByKeys(List<String> keys) {
        if (keys == null || keys.isEmpty()) {
            return List.of();
        }
        String placeholders = String.join(",", keys.stream().map(k -> "?").toList());
        String sql = SELECT_WITH_UPDATER + " WHERE c.config_key IN (" + placeholders + ") ORDER BY c.config_key";
        List<SystemConfig> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < keys.size(); i++) {
                ps.setString(i + 1, keys.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findByKeys SystemConfig failed", e);
        }
        return result;
    }

    public Optional<SystemConfig> findByKey(String key) {
        String sql = SELECT_WITH_UPDATER + " WHERE c.config_key = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, key);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findByKey SystemConfig failed", e);
        }
        return Optional.empty();
    }

    public void updateValue(String key, String value, String updatedByUserId) {
        String sql = """
                UPDATE SystemConfig
                SET config_value = ?, updated_by = ?, updated_at = GETDATE()
                WHERE config_key = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, value);
            ps.setString(2, updatedByUserId);
            ps.setString(3, key);
            int rows = ps.executeUpdate();
            if (rows == 0) {
                throw new RuntimeException("SystemConfig key not found: " + key);
            }
        } catch (SQLException e) {
            throw new RuntimeException("updateValue SystemConfig failed", e);
        }
    }

    private SystemConfig mapRow(ResultSet rs) throws SQLException {
        SystemConfig config = new SystemConfig();
        config.setConfigKey(rs.getString("config_key"));
        config.setConfigValue(rs.getString("config_value"));
        config.setDescription(rs.getString("description"));
        config.setUpdatedBy(rs.getString("updated_by"));
        config.setUpdatedByName(rs.getString("updated_by_name"));
        config.setUpdatedAt(rs.getTimestamp("updated_at"));
        return config;
    }
}
