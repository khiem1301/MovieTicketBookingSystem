package dal;

import model.entity.VatRule;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public class VatRuleDAO {

    private static final BigDecimal FALLBACK_RATE = new BigDecimal("8.00");

    private static final String SELECT_COLUMNS = """
            SELECT id, rule_name, vat_rate, start_date, end_date, status, created_at
            FROM VatRules
            """;

    public Optional<VatRule> findCurrentActive() {
        String sql = SELECT_COLUMNS + """
                WHERE status = 'ACTIVE'
                  AND start_date <= GETDATE()
                  AND (end_date IS NULL OR end_date >= GETDATE())
                ORDER BY start_date DESC
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return Optional.of(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findCurrentActive failed", e);
        }
        return Optional.empty();
    }

    public BigDecimal findCurrentActiveRate() {
        return findCurrentActive()
                .map(VatRule::getVatRate)
                .orElse(FALLBACK_RATE);
    }

    public List<VatRule> findHistory() {
        String sql = SELECT_COLUMNS + """
                WHERE status = 'INACTIVE'
                ORDER BY created_at DESC
                """;
        List<VatRule> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findHistory failed", e);
        }
        return result;
    }

    /**
     * Deactivates all ACTIVE rules and inserts a new ACTIVE rule.
     * Preserves history — old rules become INACTIVE with end_date set.
     */
    public void createAndActivate(String ruleName, BigDecimal vatRate, Timestamp startDate) {
        String deactivateSql = """
                UPDATE VatRules
                SET status = 'INACTIVE',
                    end_date = CASE WHEN end_date IS NULL THEN ? ELSE end_date END
                WHERE status = 'ACTIVE'
                """;
        String insertSql = """
                INSERT INTO VatRules (id, rule_name, vat_rate, start_date, end_date, status)
                VALUES (?, ?, ?, ?, NULL, 'ACTIVE')
                """;

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(deactivateSql)) {
                    ps.setTimestamp(1, startDate);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                    ps.setString(1, UUID.randomUUID().toString());
                    ps.setString(2, ruleName);
                    ps.setBigDecimal(3, vatRate);
                    ps.setTimestamp(4, startDate);
                    ps.executeUpdate();
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("createAndActivate failed", e);
        }
    }

    private VatRule mapRow(ResultSet rs) throws SQLException {
        VatRule rule = new VatRule();
        rule.setId(rs.getString("id"));
        rule.setRuleName(rs.getString("rule_name"));
        rule.setVatRate(rs.getBigDecimal("vat_rate"));
        rule.setStartDate(rs.getTimestamp("start_date"));
        rule.setEndDate(rs.getTimestamp("end_date"));
        rule.setStatus(rs.getString("status"));
        rule.setCreatedAt(rs.getTimestamp("created_at"));
        return rule;
    }
}
