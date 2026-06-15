package dal;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Optional;

/**
 * FR-22 — Junction Bookings ↔ Promotions.
 */
public class BookingPromotionDAO {

    public record AppliedPromotion(
            String promotionId,
            String code,
            String title,
            BigDecimal discountApplied) {}

    public Optional<AppliedPromotion> findByBookingId(String bookingId) {
        String sql = """
                SELECT bp.promotion_id, bp.discount_applied,
                       p.code, p.title
                FROM BookingPromotions bp
                JOIN Promotions p ON p.id = bp.promotion_id
                WHERE bp.booking_id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(new AppliedPromotion(
                            rs.getString("promotion_id"),
                            rs.getString("code"),
                            rs.getString("title"),
                            rs.getBigDecimal("discount_applied")));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("BookingPromotionDAO.findByBookingId failed", e);
        }
        return Optional.empty();
    }

    public Optional<AppliedPromotion> findByBookingId(Connection conn, String bookingId) throws SQLException {
        String sql = """
                SELECT bp.promotion_id, bp.discount_applied,
                       p.code, p.title
                FROM BookingPromotions bp
                JOIN Promotions p ON p.id = bp.promotion_id
                WHERE bp.booking_id = ?
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(new AppliedPromotion(
                            rs.getString("promotion_id"),
                            rs.getString("code"),
                            rs.getString("title"),
                            rs.getBigDecimal("discount_applied")));
                }
            }
        }
        return Optional.empty();
    }

    public void insert(Connection conn, String bookingId, String promotionId, BigDecimal discountApplied)
            throws SQLException {
        String sql = """
                INSERT INTO BookingPromotions (booking_id, promotion_id, discount_applied)
                VALUES (?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            ps.setString(2, promotionId);
            ps.setBigDecimal(3, discountApplied);
            ps.executeUpdate();
        }
    }

    public void deleteByBookingId(Connection conn, String bookingId) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM BookingPromotions WHERE booking_id = ?")) {
            ps.setString(1, bookingId);
            ps.executeUpdate();
        }
    }
}
