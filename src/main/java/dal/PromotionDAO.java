package dal;

import model.entity.Promotion;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class PromotionDAO {

    private static final String SELECT_COLUMNS = """
            SELECT id, code, title, description, discount_type, discount_value,
                   max_discount_amount, min_order_amount,
                   start_date, end_date, usage_limit, used_count, status, created_at
            FROM Promotions
            """;

    // ── List (phân trang, lọc theo status và keyword) ────────────────────
    public List<Promotion> findAll(String statusFilter, String keyword, int offset, int limit) {
        StringBuilder sql = new StringBuilder(SELECT_COLUMNS).append("WHERE 1=1 ");
        if (statusFilter != null && !statusFilter.isBlank()) sql.append("AND status = ? ");
        if (keyword != null && !keyword.isBlank())          sql.append("AND (code LIKE ? OR title LIKE ?) ");
        sql.append("ORDER BY created_at DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        List<Promotion> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int i = 1;
            if (statusFilter != null && !statusFilter.isBlank()) ps.setString(i++, statusFilter);
            if (keyword != null && !keyword.isBlank()) {
                String like = "%" + keyword.trim() + "%";
                ps.setString(i++, like);
                ps.setString(i++, like);
            }
            ps.setInt(i++, offset);
            ps.setInt(i, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.findAll failed", e);
        }
        return list;
    }

    public int count(String statusFilter, String keyword) {
        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM Promotions WHERE 1=1 ");
        if (statusFilter != null && !statusFilter.isBlank()) sql.append("AND status = ? ");
        if (keyword != null && !keyword.isBlank())          sql.append("AND (code LIKE ? OR title LIKE ?) ");

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int i = 1;
            if (statusFilter != null && !statusFilter.isBlank()) ps.setString(i++, statusFilter);
            if (keyword != null && !keyword.isBlank()) {
                String like = "%" + keyword.trim() + "%";
                ps.setString(i++, like);
                ps.setString(i, like);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.count failed", e);
        }
    }

    // ── Tìm theo ID ───────────────────────────────────────────────────────
    public Optional<Promotion> findById(String id) {
        String sql = SELECT_COLUMNS + "WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapRow(rs)) : Optional.empty();
            }
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.findById failed", e);
        }
    }

    /** Áp dụng voucher: tìm theo code, phải ACTIVE và còn hiệu lực */
    public Optional<Promotion> findByCodeForApply(String code) {
        String sql = SELECT_COLUMNS + """
                WHERE UPPER(code) = UPPER(?)
                  AND status = 'ACTIVE'
                  AND start_date <= GETDATE()
                  AND end_date   >= GETDATE()
                  AND (usage_limit IS NULL OR used_count < usage_limit)
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapRow(rs)) : Optional.empty();
            }
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.findByCodeForApply failed", e);
        }
    }

    public boolean codeExists(String code, String excludeId) {
        String sql = "SELECT 1 FROM Promotions WHERE UPPER(code) = UPPER(?)"
                   + (excludeId != null && !excludeId.isBlank() ? " AND id <> ?" : "");
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, code.trim());
            if (excludeId != null && !excludeId.isBlank()) ps.setString(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.codeExists failed", e);
        }
    }

    // ── Tạo mới ───────────────────────────────────────────────────────────
    public void create(Promotion p) {
        String sql = """
                INSERT INTO Promotions
                  (code, title, description, discount_type, discount_value,
                   max_discount_amount, min_order_amount,
                   start_date, end_date, usage_limit, status)
                VALUES (?,?,?,?,?,?,?,?,?,?,'ACTIVE')
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, p.getCode().trim().toUpperCase());
            ps.setString(2, p.getTitle().trim());
            setNullableString(ps, 3, p.getDescription());
            ps.setString(4, p.getDiscountType());
            ps.setBigDecimal(5, p.getDiscountValue());
            setNullableDecimal(ps, 6, p.getMaxDiscountAmount());
            setNullableDecimal(ps, 7, p.getMinOrderAmount());
            ps.setTimestamp(8, p.getStartDate());
            ps.setTimestamp(9, p.getEndDate());
            setNullableInt(ps, 10, p.getUsageLimit());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.create failed", e);
        }
    }

    // ── Cập nhật ──────────────────────────────────────────────────────────
    public void update(Promotion p) {
        String sql = """
                UPDATE Promotions SET
                  code = ?, title = ?, description = ?,
                  discount_type = ?, discount_value = ?,
                  max_discount_amount = ?, min_order_amount = ?,
                  start_date = ?, end_date = ?, usage_limit = ?
                WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, p.getCode().trim().toUpperCase());
            ps.setString(2, p.getTitle().trim());
            setNullableString(ps, 3, p.getDescription());
            ps.setString(4, p.getDiscountType());
            ps.setBigDecimal(5, p.getDiscountValue());
            setNullableDecimal(ps, 6, p.getMaxDiscountAmount());
            setNullableDecimal(ps, 7, p.getMinOrderAmount());
            ps.setTimestamp(8, p.getStartDate());
            ps.setTimestamp(9, p.getEndDate());
            setNullableInt(ps, 10, p.getUsageLimit());
            ps.setString(11, p.getId());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.update failed", e);
        }
    }

    // ── Xóa (chỉ khi chưa sử dụng) ───────────────────────────────────────
    public boolean delete(String id) {
        try (Connection conn = DBContext.getConnection()) {
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT used_count FROM Promotions WHERE id = ?")) {
                ps.setString(1, id);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next() || rs.getInt("used_count") > 0) return false;
                }
            }
            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM Promotions WHERE id = ?")) {
                ps.setString(1, id);
                return ps.executeUpdate() > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.delete failed", e);
        }
    }

    // ── Đổi trạng thái ACTIVE ↔ INACTIVE ─────────────────────────────────
    public void toggleStatus(String id) {
        String sql = """
                UPDATE Promotions
                SET status = CASE WHEN status = 'ACTIVE' THEN 'INACTIVE' ELSE 'ACTIVE' END
                WHERE id = ? AND status IN ('ACTIVE','INACTIVE')
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.toggleStatus failed", e);
        }
    }

    /** Tăng used_count sau khi áp dụng voucher vào đơn đặt vé */
    public void incrementUsedCount(String id) {
        String sql = "UPDATE Promotions SET used_count = used_count + 1 WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.incrementUsedCount failed", e);
        }
    }

    // ── Thống kê ──────────────────────────────────────────────────────────
    public int sumTotalRedemptions() {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT ISNULL(SUM(used_count), 0) FROM Promotions");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.sumTotalRedemptions failed", e);
        }
    }

    public int countActive() {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM Promotions WHERE status = 'ACTIVE' AND end_date >= GETDATE()");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.countActive failed", e);
        }
    }

    public int countEndingSoon(int days) {
        String sql = "SELECT COUNT(*) FROM Promotions WHERE status = 'ACTIVE' " +
                     "AND end_date BETWEEN GETDATE() AND DATEADD(day, ?, GETDATE())";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, days);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.countEndingSoon failed", e);
        }
    }

    public BigDecimal sumRevenueImpact() {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT ISNULL(SUM(discount_applied), 0) FROM BookingPromotions");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getBigDecimal(1) : BigDecimal.ZERO;
        } catch (SQLException e) {
            throw new RuntimeException("PromotionDAO.sumRevenueImpact failed", e);
        }
    }

    // ── Mapping ───────────────────────────────────────────────────────────
    private Promotion mapRow(ResultSet rs) throws SQLException {
        Promotion p = new Promotion();
        p.setId(rs.getString("id"));
        p.setCode(rs.getString("code"));
        p.setTitle(rs.getString("title"));
        p.setDescription(rs.getString("description"));
        p.setDiscountType(rs.getString("discount_type"));
        p.setDiscountValue(rs.getBigDecimal("discount_value"));
        p.setMaxDiscountAmount(rs.getBigDecimal("max_discount_amount"));
        p.setMinOrderAmount(rs.getBigDecimal("min_order_amount"));
        p.setStartDate(rs.getTimestamp("start_date"));
        p.setEndDate(rs.getTimestamp("end_date"));
        int ul = rs.getInt("usage_limit");
        p.setUsageLimit(rs.wasNull() ? null : ul);
        p.setUsedCount(rs.getInt("used_count"));
        p.setStatus(rs.getString("status"));
        p.setCreatedAt(rs.getTimestamp("created_at"));
        return p;
    }

    private void setNullableString(PreparedStatement ps, int idx, String val) throws SQLException {
        if (val != null && !val.isBlank()) ps.setString(idx, val.trim());
        else ps.setNull(idx, Types.NVARCHAR);
    }

    private void setNullableDecimal(PreparedStatement ps, int idx, BigDecimal val) throws SQLException {
        if (val != null) ps.setBigDecimal(idx, val);
        else ps.setNull(idx, Types.DECIMAL);
    }

    private void setNullableInt(PreparedStatement ps, int idx, Integer val) throws SQLException {
        if (val != null) ps.setInt(idx, val);
        else ps.setNull(idx, Types.INTEGER);
    }
}
