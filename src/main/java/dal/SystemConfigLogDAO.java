package dal;

import model.entity.SystemConfigLog;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

public class SystemConfigLogDAO {

    private static final String SELECT_COLUMNS = """
            SELECT l.id,
                   l.earn_rate, l.redeem_rate, l.min_redeem, l.max_redeem_per_order,
                   l.previous_earn_rate, l.previous_redeem_rate,
                   l.previous_min_redeem, l.previous_max_redeem_per_order,
                   l.updated_by, l.updated_at,
                   u.full_name AS updated_by_name
            FROM SystemConfigLog l
            LEFT JOIN Users u ON l.updated_by = u.id
            """;

    public void insert(SystemConfigLog log) {
        String sql = """
                INSERT INTO SystemConfigLog (
                    id, earn_rate, redeem_rate, min_redeem, max_redeem_per_order,
                    previous_earn_rate, previous_redeem_rate,
                    previous_min_redeem, previous_max_redeem_per_order,
                    updated_by, updated_at
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, GETDATE())
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, log.getId() != null ? log.getId() : UUID.randomUUID().toString());
            ps.setString(2, log.getEarnRate());
            ps.setString(3, log.getRedeemRate());
            ps.setString(4, log.getMinRedeem());
            ps.setString(5, log.getMaxRedeemPerOrder());
            ps.setString(6, log.getPreviousEarnRate());
            ps.setString(7, log.getPreviousRedeemRate());
            ps.setString(8, log.getPreviousMinRedeem());
            ps.setString(9, log.getPreviousMaxRedeemPerOrder());
            ps.setString(10, log.getUpdatedBy());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("insert SystemConfigLog failed", e);
        }
    }

    public List<SystemConfigLog> findLoyaltyHistory(int limit) {
        String sql = SELECT_COLUMNS + """
                ORDER BY l.updated_at DESC
                OFFSET 0 ROWS FETCH NEXT ? ROWS ONLY
                """;
        List<SystemConfigLog> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, Math.max(1, limit));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findLoyaltyHistory failed", e);
        }
        return result;
    }

    private SystemConfigLog mapRow(ResultSet rs) throws SQLException {
        SystemConfigLog log = new SystemConfigLog();
        log.setId(rs.getString("id"));
        log.setEarnRate(rs.getString("earn_rate"));
        log.setRedeemRate(rs.getString("redeem_rate"));
        log.setMinRedeem(rs.getString("min_redeem"));
        log.setMaxRedeemPerOrder(rs.getString("max_redeem_per_order"));
        log.setPreviousEarnRate(rs.getString("previous_earn_rate"));
        log.setPreviousRedeemRate(rs.getString("previous_redeem_rate"));
        log.setPreviousMinRedeem(rs.getString("previous_min_redeem"));
        log.setPreviousMaxRedeemPerOrder(rs.getString("previous_max_redeem_per_order"));
        log.setUpdatedBy(rs.getString("updated_by"));
        log.setUpdatedByName(rs.getString("updated_by_name"));
        log.setUpdatedAt(rs.getTimestamp("updated_at"));
        return log;
    }
}
