package dal;

import model.entity.PricingRule;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class PricingRuleDAO {

    private static final String SELECT_COLUMNS = """
            SELECT id, rule_name, condition_type, day_of_week, time_from, time_to,
                   date_from, date_to, adjustment_type, adjustment_value, priority, status, created_at
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
        rule.setCreatedAt(rs.getTimestamp("created_at"));
        return rule;
    }
}
