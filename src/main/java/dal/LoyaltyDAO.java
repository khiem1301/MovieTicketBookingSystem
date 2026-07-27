package dal;

import model.dto.LoyaltyHistoryItem;
import utils.ConfigKeys;
import utils.ConfigUtil;
import utils.PromotionCalculator;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * FR-41 / FR-43 / FR-44 — Loyalty Points: tích điểm, đổi điểm, lịch sử.
 */
public class LoyaltyDAO {

    // ── Số dư điểm hiện tại ────────────────────────────────────────────────

    /** Số dư thật trên Users.loyalty_points (khớp trang cá nhân / thanh toán). */
    public int getLoyaltyBalance(String userId) {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COALESCE(loyalty_points, 0) FROM Users WHERE id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("getLoyaltyBalance failed", e);
        }
    }

    // ── FR-44: Lịch sử giao dịch điểm ─────────────────────────────────────

    public List<LoyaltyHistoryItem> getHistory(String userId, int offset, int limit) {
        String sql = """
                SELECT lpl.id, lpl.booking_id, lpl.points_delta, lpl.transaction_type,
                       lpl.note, lpl.created_at, b.booking_code
                FROM LoyaltyPointsLog lpl
                LEFT JOIN Bookings b ON b.id = lpl.booking_id
                WHERE lpl.user_id = ?
                ORDER BY lpl.created_at DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;
        List<LoyaltyHistoryItem> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setInt(2, offset);
            ps.setInt(3, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(new LoyaltyHistoryItem(
                            rs.getString("id"),
                            rs.getString("booking_id"),
                            rs.getString("booking_code"),
                            rs.getInt("points_delta"),
                            rs.getString("transaction_type"),
                            rs.getString("note"),
                            rs.getTimestamp("created_at")));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("LoyaltyDAO.getHistory failed", e);
        }
        return list;
    }

    public int countHistory(String userId) {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM LoyaltyPointsLog WHERE user_id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("LoyaltyDAO.countHistory failed", e);
        }
    }

    // ── FR-43: Đổi điểm trên trang Payment ────────────────────────────────

    /**
     * Áp dụng điểm tích luỹ vào đơn PENDING.
     * Tính discount từ points, cộng với promo discount (nếu có), cập nhật Bookings.
     */
    public void applyPointsToBooking(String bookingId, String userId, int pointsToUse) {
        int redeemRate = ConfigUtil.getInt(ConfigKeys.LOYALTY_REDEEM_RATE, 100);
        int minRedeem  = ConfigUtil.getInt(ConfigKeys.LOYALTY_MIN_REDEEM, 100);
        int maxRedeem  = ConfigUtil.getInt(ConfigKeys.LOYALTY_MAX_REDEEM_PER_ORDER, 5000);

        if (pointsToUse < minRedeem) {
            throw new IllegalArgumentException(
                    "Điểm tối thiểu để đổi là " + minRedeem + " điểm.");
        }
        int effective = Math.min(pointsToUse, maxRedeem);
        effective = (effective / redeemRate) * redeemRate;
        if (effective <= 0) {
            throw new IllegalArgumentException(
                    "Số điểm không đủ để quy đổi (tối thiểu " + redeemRate + " điểm / lần).");
        }
        // 100 điểm = 10.000đ giảm giá
        BigDecimal pointsDiscount = BigDecimal.valueOf((long) (effective / redeemRate) * 10_000);

        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            // Kiểm tra số điểm thực tế của user
            int currentPoints;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT loyalty_points FROM Users WHERE id = ?")) {
                ps.setString(1, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new IllegalStateException("Không tìm thấy tài khoản.");
                    currentPoints = rs.getInt("loyalty_points");
                }
            }
            if (currentPoints < effective) {
                conn.rollback();
                throw new IllegalArgumentException(
                        "Số dư điểm hiện tại (" + currentPoints + ") không đủ để đổi " + effective + " điểm.");
            }

            // Lấy thông tin booking
            BigDecimal totalAmount, vatRate;
            try (PreparedStatement ps = conn.prepareStatement("""
                    SELECT total_amount, vat_rate_snapshot
                    FROM Bookings
                    WHERE id = ? AND user_id = ?
                      AND booking_source = 'ONLINE'
                      AND booking_status = 'PENDING'
                      AND payment_status = 'UNPAID'
                      AND expired_at > GETDATE()
                    """)) {
                ps.setString(1, bookingId);
                ps.setString(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        throw new IllegalStateException("Đơn không còn ở trạng thái chờ thanh toán.");
                    }
                    totalAmount = rs.getBigDecimal("total_amount");
                    vatRate     = rs.getBigDecimal("vat_rate_snapshot");
                }
            }

            // Lấy discount từ voucher (nếu có)
            BigDecimal promoDiscount = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COALESCE(discount_applied, 0) FROM BookingPromotions WHERE booking_id = ?")) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) promoDiscount = rs.getBigDecimal(1);
                }
            }

            BigDecimal totalDiscount = promoDiscount.add(pointsDiscount);
            BigDecimal newFinal = PromotionCalculator.recalculateFinalAmount(totalAmount, totalDiscount, vatRate);

            try (PreparedStatement ps = conn.prepareStatement("""
                    UPDATE Bookings
                    SET discount_amount = ?, final_amount = ?, points_redeemed = ?
                    WHERE id = ? AND user_id = ?
                      AND booking_source = 'ONLINE'
                      AND booking_status = 'PENDING'
                      AND payment_status = 'UNPAID'
                      AND expired_at > GETDATE()
                    """)) {
                ps.setBigDecimal(1, totalDiscount);
                ps.setBigDecimal(2, newFinal);
                ps.setInt(3, effective);
                ps.setString(4, bookingId);
                ps.setString(5, userId);
                if (ps.executeUpdate() == 0) {
                    conn.rollback();
                    throw new IllegalStateException("Không thể cập nhật đơn đặt vé.");
                }
            }

            conn.commit();
        } catch (SQLException e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException ig) {}
            throw new RuntimeException("applyPointsToBooking failed", e);
        } finally {
            if (conn != null) try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ig) {}
        }
    }

    /** Gỡ điểm tích luỹ khỏi đơn PENDING, trả lại giá gốc (hoặc giá sau promo). */
    public void removePointsFromBooking(String bookingId, String userId) {
        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            BigDecimal totalAmount, vatRate;
            int pointsRedeemed;
            try (PreparedStatement ps = conn.prepareStatement("""
                    SELECT total_amount, vat_rate_snapshot, points_redeemed
                    FROM Bookings
                    WHERE id = ? AND user_id = ?
                      AND booking_source = 'ONLINE'
                      AND booking_status = 'PENDING'
                      AND payment_status = 'UNPAID'
                      AND expired_at > GETDATE()
                    """)) {
                ps.setString(1, bookingId);
                ps.setString(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) { conn.rollback(); return; }
                    totalAmount    = rs.getBigDecimal("total_amount");
                    vatRate        = rs.getBigDecimal("vat_rate_snapshot");
                    pointsRedeemed = rs.getInt("points_redeemed");
                }
            }
            if (pointsRedeemed <= 0) { conn.rollback(); return; }

            BigDecimal promoDiscount = BigDecimal.ZERO;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COALESCE(discount_applied, 0) FROM BookingPromotions WHERE booking_id = ?")) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) promoDiscount = rs.getBigDecimal(1);
                }
            }

            BigDecimal newFinal = PromotionCalculator.recalculateFinalAmount(totalAmount, promoDiscount, vatRate);

            try (PreparedStatement ps = conn.prepareStatement("""
                    UPDATE Bookings
                    SET discount_amount = ?, final_amount = ?, points_redeemed = 0
                    WHERE id = ? AND user_id = ?
                    """)) {
                ps.setBigDecimal(1, promoDiscount);
                ps.setBigDecimal(2, newFinal);
                ps.setString(3, bookingId);
                ps.setString(4, userId);
                ps.executeUpdate();
            }

            conn.commit();
        } catch (SQLException e) {
            if (conn != null) try { conn.rollback(); } catch (SQLException ig) {}
            throw new RuntimeException("removePointsFromBooking failed", e);
        } finally {
            if (conn != null) try { conn.setAutoCommit(true); conn.close(); } catch (SQLException ig) {}
        }
    }

    // ── FR-41: Tích điểm sau khi thanh toán ───────────────────────────────

    public static void earnPoints(Connection conn, String userId, String bookingId,
                                  BigDecimal finalAmount, String note) throws SQLException {
        int earnRate = ConfigUtil.getInt(ConfigKeys.LOYALTY_EARN_RATE, 1);
        if (earnRate <= 0) return;

        int pts = finalAmount
                .divide(new BigDecimal("1000"), 0, RoundingMode.DOWN)
                .multiply(BigDecimal.valueOf(earnRate))
                .intValue();
        if (pts <= 0) return;

        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE Users SET loyalty_points = loyalty_points + ? WHERE id = ?")) {
            ps.setInt(1, pts);
            ps.setString(2, userId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = conn.prepareStatement("""
                INSERT INTO LoyaltyPointsLog (user_id, booking_id, points_delta, transaction_type, note)
                VALUES (?, ?, ?, 'EARN', ?)
                """)) {
            ps.setString(1, userId);
            ps.setString(2, bookingId);
            ps.setInt(3, pts);
            ps.setString(4, note);
            ps.executeUpdate();
        }
    }

    /** FR-43: trừ điểm khi thanh toán online thành công. */
    public static void redeemPoints(Connection conn, String userId, String bookingId,
                                    int points) throws SQLException {
        if (points <= 0) return;

        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE Users SET loyalty_points = loyalty_points - ? WHERE id = ? AND loyalty_points >= ?")) {
            ps.setInt(1, points);
            ps.setString(2, userId);
            ps.setInt(3, points);
            if (ps.executeUpdate() == 0) {
                throw new SQLException("Không đủ điểm để trừ (bookingId=" + bookingId + ").");
            }
        }
        try (PreparedStatement ps = conn.prepareStatement("""
                INSERT INTO LoyaltyPointsLog (user_id, booking_id, points_delta, transaction_type, note)
                VALUES (?, ?, ?, 'REDEEM', N'Đổi điểm giảm giá đặt vé online')
                """)) {
            ps.setString(1, userId);
            ps.setString(2, bookingId);
            ps.setInt(3, -points);
            ps.executeUpdate();
        }
    }

    /** Quy đổi redeem cố định trong hệ thống: {@code loyalty_redeem_rate} điểm = 10.000đ. */
    private static final BigDecimal REDEEM_UNIT_VND = new BigDecimal("10000");

    /**
     * Số điểm cần để đổi được ít nhất {@code amountVnd} khi thanh toán.
     * <pre>
     *   loyalty_redeem_rate điểm = 10.000đ
     *   points = ceil(amountVnd / 10.000) × loyalty_redeem_rate
     * </pre>
     * Làm tròn lên theo đơn vị 10.000đ để khi redeem không bị thiếu tiền vé.
     */
    public static int pointsNeededForAmount(BigDecimal amountVnd) {
        if (amountVnd == null || amountVnd.compareTo(BigDecimal.ZERO) <= 0) {
            return 0;
        }
        int redeemRate = ConfigUtil.getInt(ConfigKeys.LOYALTY_REDEEM_RATE, 100);
        if (redeemRate <= 0) {
            return 0;
        }
        int units = amountVnd
                .divide(REDEEM_UNIT_VND, 0, RoundingMode.CEILING)
                .intValue();
        return units * redeemRate;
    }

    /**
     * FR-47 — Hoàn điểm khi hủy suất chiếu.
     * <p>
     * Tích điểm (earn) và đổi điểm (redeem) dùng rate khác nhau — khi hoàn phải quy
     * theo redeem để điểm nhận được đủ đổi lại ≥ giá trị vé đã trả
     * ({@code finalAmount × refundRate}):
     * <pre>
     *   compensated = finalAmount × refundRate
     *   points = ceil(compensated / 10.000) × loyalty_redeem_rate
     * </pre>
     *
     * @return số điểm đã cộng
     */
    public static int creditRefundPoints(Connection conn, String userId, String bookingId,
                                         BigDecimal finalAmount, BigDecimal refundRate, String note)
            throws SQLException {
        if (userId == null || userId.isBlank() || finalAmount == null) return 0;
        BigDecimal rate = refundRate != null ? refundRate : BigDecimal.ONE;
        if (rate.compareTo(BigDecimal.ZERO) <= 0) return 0;

        BigDecimal compensated = finalAmount.multiply(rate);
        int pts = pointsNeededForAmount(compensated);
        if (pts <= 0) return 0;

        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE Users SET loyalty_points = loyalty_points + ? WHERE id = ?")) {
            ps.setInt(1, pts);
            ps.setString(2, userId);
            ps.executeUpdate();
        }
        try (PreparedStatement ps = conn.prepareStatement("""
                INSERT INTO LoyaltyPointsLog (user_id, booking_id, points_delta, transaction_type, note)
                VALUES (?, ?, ?, 'REFUND_POINTS', ?)
                """)) {
            ps.setString(1, userId);
            ps.setString(2, bookingId);
            ps.setInt(3, pts);
            ps.setString(4, note != null ? note : "Hoàn điểm do hủy suất chiếu");
            ps.executeUpdate();
        }
        return pts;
    }
}
