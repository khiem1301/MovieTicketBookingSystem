package dal;

import model.entity.PricingRule;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public class PricingRuleDAO {

    private static final String SELECT_COLUMNS = """
            SELECT id, rule_name, condition_type, day_of_week, time_from, time_to,
                   date_from, date_to, adjustment_type, adjustment_value, priority, status,
                   created_by, created_at
            FROM PricingRules
            """;

    public List<PricingRule> getActiveRules() {
        String sql = SELECT_COLUMNS + """
                WHERE status = 'ACTIVE'
                ORDER BY priority DESC, created_at ASC
                """;
        List<PricingRule> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getActiveRules failed", e);
        }
        return result;
    }

    public int countFiltered(String keyword, String status) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM PricingRules WHERE 1=1 ");
        appendFilters(sql, keyword, status);
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            bindFilters(ps, 1, keyword, status);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("PricingRuleDAO.countFiltered failed", e);
        }
    }

    public List<PricingRule> findFiltered(String keyword, String status, int offset, int limit) {
        StringBuilder sql = new StringBuilder(SELECT_COLUMNS).append("WHERE 1=1 ");
        appendFilters(sql, keyword, status);
        sql.append(" ORDER BY priority DESC, created_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        List<PricingRule> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int idx = bindFilters(ps, 1, keyword, status);
            ps.setInt(idx++, offset);
            ps.setInt(idx, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("PricingRuleDAO.findFiltered failed", e);
        }
        return result;
    }

    public Optional<PricingRule> findById(String id) {
        if (id == null || id.isBlank()) {
            return Optional.empty();
        }
        String sql = SELECT_COLUMNS + "WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapRow(rs)) : Optional.empty();
            }
        } catch (SQLException e) {
            throw new RuntimeException("PricingRuleDAO.findById failed", e);
        }
    }

    public String insert(PricingRule rule) {
        String id = rule.getId() != null && !rule.getId().isBlank()
                ? rule.getId()
                : UUID.randomUUID().toString();
        String sql = """
                INSERT INTO PricingRules (
                    id, rule_name, condition_type, day_of_week, time_from, time_to,
                    date_from, date_to, adjustment_type, adjustment_value, priority, status, created_by
                ) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            bindRuleFields(ps, 2, rule);
            ps.setString(13, rule.getCreatedBy());
            ps.executeUpdate();
            rule.setId(id);
            return id;
        } catch (SQLException e) {
            throw new RuntimeException("PricingRuleDAO.insert failed", e);
        }
    }

    /** Cập nhật rule — không đổi created_by. */
    public boolean update(PricingRule rule) {
        String sql = """
                UPDATE PricingRules SET
                    rule_name = ?, condition_type = ?, day_of_week = ?,
                    time_from = ?, time_to = ?, date_from = ?, date_to = ?,
                    adjustment_type = ?, adjustment_value = ?, priority = ?, status = ?
                WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindRuleFields(ps, 1, rule);
            ps.setString(12, rule.getId());
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("PricingRuleDAO.update failed", e);
        }
    }

    public boolean updateStatus(String id, String status) {
        String sql = "UPDATE PricingRules SET status = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("PricingRuleDAO.updateStatus failed", e);
        }
    }

    public boolean delete(String id) {
        String sql = "DELETE FROM PricingRules WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            return ps.executeUpdate() > 0;
        } catch (SQLException e) {
            throw new RuntimeException("PricingRuleDAO.delete failed", e);
        }
    }

    private void appendFilters(StringBuilder sql, String keyword, String status) {
        if (status != null && !status.isBlank()) {
            sql.append("AND status = ? ");
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append("AND rule_name LIKE ? ");
        }
    }

    private int bindFilters(PreparedStatement ps, int start, String keyword, String status)
            throws SQLException {
        int i = start;
        if (status != null && !status.isBlank()) {
            ps.setString(i++, status.trim());
        }
        if (keyword != null && !keyword.isBlank()) {
            ps.setString(i++, "%" + keyword.trim() + "%");
        }
        return i;
    }

    private void bindRuleFields(PreparedStatement ps, int start, PricingRule rule) throws SQLException {
        int i = start;
        ps.setString(i++, rule.getRuleName());
        ps.setString(i++, rule.getConditionType());
        setNullableString(ps, i++, rule.getDayOfWeek());
        if (rule.getTimeFrom() != null) {
            ps.setTime(i++, rule.getTimeFrom());
        } else {
            ps.setNull(i++, Types.TIME);
        }
        if (rule.getTimeTo() != null) {
            ps.setTime(i++, rule.getTimeTo());
        } else {
            ps.setNull(i++, Types.TIME);
        }
        if (rule.getDateFrom() != null) {
            ps.setDate(i++, rule.getDateFrom());
        } else {
            ps.setNull(i++, Types.DATE);
        }
        if (rule.getDateTo() != null) {
            ps.setDate(i++, rule.getDateTo());
        } else {
            ps.setNull(i++, Types.DATE);
        }
        ps.setString(i++, rule.getAdjustmentType());
        ps.setBigDecimal(i++, rule.getAdjustmentValue());
        ps.setInt(i++, rule.getPriority());
        ps.setString(i, rule.getStatus());
    }

    private void setNullableString(PreparedStatement ps, int index, String value) throws SQLException {
        if (value == null || value.isBlank()) {
            ps.setNull(index, Types.NVARCHAR);
        } else {
            ps.setString(index, value);
        }
    }

    private PricingRule mapRow(ResultSet rs) throws SQLException {
        PricingRule rule = new PricingRule();
        rule.setId(rs.getString("id"));
        rule.setRuleName(rs.getString("rule_name"));
        rule.setConditionType(rs.getString("condition_type"));
        rule.setDayOfWeek(rs.getString("day_of_week"));
        rule.setTimeFrom(rs.getTime("time_from"));
        rule.setTimeTo(rs.getTime("time_to"));
        rule.setDateFrom(rs.getDate("date_from"));
        rule.setDateTo(rs.getDate("date_to"));
        rule.setAdjustmentType(rs.getString("adjustment_type"));
        BigDecimal value = rs.getBigDecimal("adjustment_value");
        rule.setAdjustmentValue(value != null ? value : BigDecimal.ZERO);
        rule.setPriority(rs.getInt("priority"));
        rule.setStatus(rs.getString("status"));
        rule.setCreatedBy(rs.getString("created_by"));
        rule.setCreatedAt(rs.getTimestamp("created_at"));
        return rule;
    }
}
