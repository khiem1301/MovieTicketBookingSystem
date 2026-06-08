package dal;

import model.entity.Booking;

import java.math.BigDecimal;
import java.sql.*;
import java.util.List;

/**
 * FR-39 — Booking Source Management
 * DAO xử lý tạo và truy vấn booking, gắn flag ONLINE/OFFLINE vào mỗi đơn.
 */
public class BookingDAO {

    /**
     * FR-35 / FR-38 — Tạo booking tại quầy (OFFLINE).
     * Hỗ trợ cả khách vãng lai (userId = null) và khách có tài khoản.
     *
     * @param showtimeId      ID suất chiếu
     * @param staffId         ID nhân viên tạo đơn
     * @param userId          ID tài khoản khách (null nếu khách vãng lai — FR-38)
     * @param customerName    Tên khách (bắt buộc cho OFFLINE)
     * @param customerPhone   SĐT khách (bắt buộc cho OFFLINE)
     * @param seatIds         Danh sách seat ID đã chọn
     * @param seatPrices      Giá tương ứng từng ghế (cùng thứ tự với seatIds)
     * @return bookingId vừa tạo
     */
    public String createOfflineBooking(String showtimeId, String staffId,
                                       String userId, String customerName, String customerPhone,
                                       List<String> seatIds, List<BigDecimal> seatPrices) {
        BigDecimal vatRate = getCurrentVatRate();
        BigDecimal totalAmount = seatPrices.stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal finalAmount = totalAmount.multiply(
                BigDecimal.ONE.add(vatRate.divide(new BigDecimal("100"))));

        String bookingCode = generateBookingCode();

        String insertBooking = """
                INSERT INTO Bookings
                    (booking_code, user_id, showtime_id, booking_source,
                     created_by_staff_id, customer_name, customer_phone,
                     vat_rate_snapshot, total_amount, discount_amount, final_amount,
                     booking_status, payment_status)
                VALUES (?, ?, ?, 'OFFLINE', ?, ?, ?, ?, ?, 0, ?, 'PENDING', 'UNPAID')
                """;

        String insertSeat = """
                INSERT INTO BookingSeats (booking_id, seat_id, ticket_price)
                VALUES (?, ?, ?)
                """;

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            String bookingId;

            try (PreparedStatement ps = conn.prepareStatement(
                    insertBooking, Statement.RETURN_GENERATED_KEYS)) {
                ps.setString(1, bookingCode);
                if (userId != null) ps.setString(2, userId);
                else ps.setNull(2, Types.VARCHAR);
                ps.setString(3, showtimeId);
                ps.setString(4, staffId);
                ps.setString(5, customerName);
                ps.setString(6, customerPhone);
                ps.setBigDecimal(7, vatRate);
                ps.setBigDecimal(8, totalAmount);
                ps.setBigDecimal(9, finalAmount);
                ps.executeUpdate();

                // SQL Server: lấy ID vừa insert qua SELECT SCOPE_IDENTITY()
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (!rs.next()) throw new SQLException("Không lấy được booking ID");
                    bookingId = rs.getString(1);
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(insertSeat)) {
                for (int i = 0; i < seatIds.size(); i++) {
                    ps.setString(1, bookingId);
                    ps.setString(2, seatIds.get(i));
                    ps.setBigDecimal(3, seatPrices.get(i));
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            conn.commit();
            return bookingId;

        } catch (SQLException e) {
            throw new RuntimeException("createOfflineBooking failed", e);
        }
    }

    public Booking getById(String bookingId) {
        String sql = """
                SELECT id, booking_code, user_id, showtime_id, booking_source,
                       created_by_staff_id, customer_name, customer_phone,
                       vat_rate_snapshot, total_amount, discount_amount, final_amount,
                       booking_status, payment_status, booked_at, expired_at
                FROM Bookings WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("getById failed", e);
        }
        return null;
    }

    /** Lấy VAT rate hiện hành từ VatRules; fallback 8% nếu chưa cấu hình. */
    public BigDecimal getCurrentVatRate() {
        return new VatRuleDAO().findCurrentActiveRate();
    }

    private String generateBookingCode() {
        return "CTR" + System.currentTimeMillis();
    }

    private Booking mapRow(ResultSet rs) throws SQLException {
        Booking b = new Booking();
        b.setId(rs.getString("id"));
        b.setBookingCode(rs.getString("booking_code"));
        b.setUserId(rs.getString("user_id"));
        b.setShowtimeId(rs.getString("showtime_id"));
        b.setBookingSource(rs.getString("booking_source"));
        b.setCreatedByStaffId(rs.getString("created_by_staff_id"));
        b.setCustomerName(rs.getString("customer_name"));
        b.setCustomerPhone(rs.getString("customer_phone"));
        b.setVatRateSnapshot(rs.getBigDecimal("vat_rate_snapshot"));
        b.setTotalAmount(rs.getBigDecimal("total_amount"));
        b.setDiscountAmount(rs.getBigDecimal("discount_amount"));
        b.setFinalAmount(rs.getBigDecimal("final_amount"));
        b.setBookingStatus(rs.getString("booking_status"));
        b.setPaymentStatus(rs.getString("payment_status"));
        b.setBookedAt(rs.getTimestamp("booked_at"));
        b.setExpiredAt(rs.getTimestamp("expired_at"));
        return b;
    }
}
