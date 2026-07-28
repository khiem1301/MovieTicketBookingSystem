package dal;

import model.entity.VatRule;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
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

    /**
     * Rule đang có hiệu lực tại thời điểm hiện tại — theo khoảng ngày, không chỉ status ACTIVE.
     * Rule cũ chuyển INACTIVE vẫn hiệu lực cho đến end_date.
     */
    public Optional<VatRule> findEffectiveNow() {
        String sql = SELECT_COLUMNS + """
                WHERE start_date <= GETDATE()
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
            throw new RuntimeException("findEffectiveNow failed", e);
        }
        return Optional.empty();
    }

    /** Rule có status ACTIVE nhưng start_date chưa tới — đã lên lịch, chưa áp dụng. */
    public Optional<VatRule> findScheduledActive() {
        List<VatRule> list = findScheduledList();
        return list.isEmpty() ? Optional.empty() : Optional.of(list.get(0));
    }

    /** Tất cả quy tắc ACTIVE chưa đến ngày áp dụng — hiển thị trong bảng lịch sử. */
    public List<VatRule> findScheduledList() {
        String sql = SELECT_COLUMNS + """
                WHERE status = 'ACTIVE'
                  AND start_date > GETDATE()
                ORDER BY start_date ASC
                """;
        List<VatRule> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findScheduledList failed", e);
        }
        return result;
    }

    /** @deprecated use {@link #findEffectiveNow()} */
    public Optional<VatRule> findCurrentActive() {
        return findEffectiveNow();
    }

    public BigDecimal findCurrentActiveRate() {
        return findEffectiveNow()
                .map(VatRule::getVatRate)
                .orElse(FALLBACK_RATE);
    }

    private static final String HISTORY_WHERE = """
            status = 'INACTIVE'
            AND start_date <= GETDATE()
            AND end_date IS NOT NULL
            AND end_date <= GETDATE()
            """;

    /** Quy tắc đã hết hiệu lực — loại rule vẫn còn trong khoảng ngày (dù status INACTIVE). */
    public List<VatRule> findHistory() {
        return findHistory(0, Integer.MAX_VALUE);
    }

    public int countHistory() {
        String sql = "SELECT COUNT(*) AS total FROM VatRules WHERE " + HISTORY_WHERE;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return rs.getInt("total");
            }
        } catch (SQLException e) {
            throw new RuntimeException("countHistory failed", e);
        }
        return 0;
    }

    public List<VatRule> findHistory(int offset, int limit) {
        if (limit <= 0) {
            return List.of();
        }
        String sql = SELECT_COLUMNS + """
                WHERE %s
                ORDER BY created_at DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """.formatted(HISTORY_WHERE);
        List<VatRule> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, Math.max(0, offset));
            ps.setInt(2, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    result.add(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findHistory failed", e);
        }
        return result;
    }

    public Optional<VatRule> findById(String id) {
        if (id == null || id.isBlank()) {
            return Optional.empty();
        }
        String sql = SELECT_COLUMNS + " WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
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

    /**
     * Đã có quy tắc ACTIVE hoặc đang hiệu lực bắt đầu đúng ngày {@code date}.
     * Quy tắc đã hủy ({@code CANCELLED} / INACTIVE chưa tới ngày) không tính.
     */
    public boolean existsByStartDate(LocalDate date, String excludeId) {
        if (date == null) {
            return false;
        }
        String sql = """
                SELECT 1 FROM VatRules
                WHERE CAST(start_date AS DATE) = ?
                  AND status <> 'CANCELLED'
                  AND NOT (status = 'INACTIVE' AND start_date > GETDATE())
                  AND (
                    status = 'ACTIVE'
                    OR (
                      start_date <= GETDATE()
                      AND (end_date IS NULL OR end_date >= GETDATE())
                    )
                  )
                  AND (? IS NULL OR id <> ?)
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(date));
            ps.setString(2, blankToNull(excludeId));
            ps.setString(3, blankToNull(excludeId));
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            throw new RuntimeException("existsByStartDate failed", e);
        }
    }

    public boolean isScheduledEditable(VatRule rule) {
        return rule != null
                && "ACTIVE".equals(rule.getStatus())
                && rule.getStartDate() != null
                && rule.getStartDate().after(new Timestamp(System.currentTimeMillis()));
    }

    /**
     * Sửa quy tắc đã lên lịch (ACTIVE, start_date chưa tới). Không sửa rule đang/đã áp dụng.
     */
    public void updateScheduled(String id, String ruleName, BigDecimal vatRate, Timestamp newStartDate) {
        VatRule existing = findById(id)
                .orElseThrow(() -> new RuntimeException("VatRule not found: " + id));
        if (!isScheduledEditable(existing)) {
            throw new RuntimeException("Rule is not editable: " + id);
        }

        LocalDate newDay = newStartDate.toLocalDateTime().toLocalDate();
        // Trùng ngày chỉ cấm với lịch tương lai; chuyển về hôm nay = áp dụng ngay (giống create)
        if (newDay.isAfter(LocalDate.now()) && existsByStartDate(newDay, id)) {
            throw new DuplicateStartDateException(newDay);
        }

        String updateRuleSql = """
                UPDATE VatRules
                SET rule_name = ?, vat_rate = ?, start_date = ?
                WHERE id = ? AND status = 'ACTIVE' AND start_date > GETDATE()
                """;

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(updateRuleSql)) {
                    ps.setString(1, ruleName);
                    ps.setBigDecimal(2, vatRate);
                    ps.setTimestamp(3, newStartDate);
                    ps.setString(4, id);
                    if (ps.executeUpdate() == 0) {
                        throw new SQLException("Scheduled rule no longer editable: " + id);
                    }
                }
                rechainTimeline(conn);
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (DuplicateStartDateException e) {
            throw e;
        } catch (SQLException e) {
            throw new RuntimeException("updateScheduled failed", e);
        }
    }

    /**
     * Hủy quy tắc đã lên lịch — nối lại end_date của các quy tắc còn lại.
     */
    public void cancelScheduled(String id) {
        VatRule existing = findById(id)
                .orElseThrow(() -> new RuntimeException("VatRule not found: " + id));
        if (!isScheduledEditable(existing)) {
            throw new RuntimeException("Rule is not cancellable: " + id);
        }

        String cancelSql = """
                UPDATE VatRules
                SET status = 'CANCELLED'
                WHERE id = ? AND status = 'ACTIVE' AND start_date > GETDATE()
                """;

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(cancelSql)) {
                    ps.setString(1, id);
                    if (ps.executeUpdate() == 0) {
                        throw new SQLException("Scheduled rule no longer cancellable: " + id);
                    }
                }
                rechainTimeline(conn);
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("cancelScheduled failed", e);
        }
    }

    /**
     * Tạo quy tắc mới (áp dụng ngay hoặc lên lịch). Cho phép đổi VAT nhiều lần trong
     * cùng ngày hôm nay (áp dụng ngay lập tức, thay thế quy tắc đang hiệu lực); với
     * lịch trong tương lai thì mỗi ngày bắt đầu chỉ một quy tắc.
     */
    public void createAndActivate(String ruleName, BigDecimal vatRate, Timestamp startDate) {
        LocalDate startDay = startDate.toLocalDateTime().toLocalDate();
        if (startDay.isAfter(LocalDate.now()) && existsByStartDate(startDay, null)) {
            throw new DuplicateStartDateException(startDay);
        }

        String insertSql = """
                INSERT INTO VatRules (id, rule_name, vat_rate, start_date, end_date, status)
                VALUES (?, ?, ?, ?, NULL, 'ACTIVE')
                """;

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                    ps.setString(1, UUID.randomUUID().toString());
                    ps.setString(2, ruleName);
                    ps.setBigDecimal(3, vatRate);
                    ps.setTimestamp(4, startDate);
                    ps.executeUpdate();
                }
                rechainTimeline(conn);
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (DuplicateStartDateException e) {
            throw e;
        } catch (SQLException e) {
            throw new RuntimeException("createAndActivate failed", e);
        }
    }

    /**
     * Nối chuỗi theo {@code start_date} tăng dần.
     * {@code end_date} của rule i = {@code start_date} của rule i+1 (mốc kết thúc, exclusive).
     * Status:
     * <ul>
     *   <li>ACTIVE — chưa tới ngày bắt đầu (lịch), hoặc đang trong khoảng hiệu lực</li>
     *   <li>INACTIVE — đã qua {@code end_date} (bị rule sau thay thế)</li>
     * </ul>
     * Lưu ý: rule đang hiệu lực nhưng đã có lịch sau vẫn ACTIVE đến đúng mốc end
     * (tránh “vừa thêm hôm nay đã INACTIVE” khi chỉ mới gán end_date tương lai).
     */
    private void rechainTimeline(Connection conn) throws SQLException {
        List<VatRule> chain = loadChainRules(conn);
        Timestamp now = new Timestamp(System.currentTimeMillis());

        String updateSql = """
                UPDATE VatRules
                SET end_date = ?, status = ?
                WHERE id = ?
                """;

        try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
            for (int i = 0; i < chain.size(); i++) {
                VatRule cur = chain.get(i);
                Timestamp end = null;
                if (i < chain.size() - 1) {
                    // Bỏ qua mốc start trùng (tránh end_date = start_date → CK_VatRules_Dates)
                    Timestamp curStart = cur.getStartDate();
                    for (int j = i + 1; j < chain.size(); j++) {
                        Timestamp nextStart = chain.get(j).getStartDate();
                        if (nextStart.after(curStart)) {
                            end = nextStart;
                            break;
                        }
                    }
                }
                boolean startsInFuture = cur.getStartDate().after(now);
                // end <= now → khoảng đã kết thúc (mốc end = start của rule kế)
                boolean periodEnded = end != null && !end.after(now);
                String status;
                if (startsInFuture || !periodEnded) {
                    status = "ACTIVE";
                } else {
                    status = "INACTIVE";
                }

                if (end != null) {
                    ps.setTimestamp(1, end);
                } else {
                    ps.setNull(1, java.sql.Types.TIMESTAMP);
                }
                ps.setString(2, status);
                ps.setString(3, cur.getId());
                ps.executeUpdate();
            }
        }
    }

    /**
     * Timeline hiệu lực: bỏ rule đã hủy ({@code CANCELLED} hoặc INACTIVE + start tương lai).
     * Nếu đưa canceled vào chain, nhiều bản ghi cùng start_date → end = start → lỗi CK_VatRules_Dates.
     */
    private List<VatRule> loadChainRules(Connection conn) throws SQLException {
        String sql = SELECT_COLUMNS + """
                WHERE status <> 'CANCELLED'
                  AND NOT (
                    status = 'INACTIVE'
                    AND start_date > GETDATE()
                  )
                ORDER BY start_date ASC, created_at ASC
                """;
        List<VatRule> result = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                result.add(mapRow(rs));
            }
        }
        return result;
    }

    /**
     * Sửa lại end_date/status sau bug cũ (rule đang hiệu lực bị gắn INACTIVE sớm).
     * An toàn gọi khi mở trang quản lý VAT.
     */
    public void repairTimeline() {
        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                rechainTimeline(conn);
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("repairTimeline failed", e);
        }
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
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

    public static final class DuplicateStartDateException extends RuntimeException {
        private final LocalDate startDate;

        public DuplicateStartDateException(LocalDate startDate) {
            super("Duplicate VAT start date: " + startDate);
            this.startDate = startDate;
        }

        public LocalDate getStartDate() {
            return startDate;
        }
    }
}
