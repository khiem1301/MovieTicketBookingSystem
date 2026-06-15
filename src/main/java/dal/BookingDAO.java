package dal;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;

import model.dto.BookingDetailDTO;
import model.entity.Booking;

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

    /**
     * Lấy booking kèm thông tin showtime + danh sách ghế để hiển thị trang payment/print.
     */
    public BookingDetailDTO getDetailById(String bookingId) {
        String sql = """
                SELECT b.id, b.booking_code, b.customer_name, b.customer_phone,
                       b.booking_status, b.payment_status,
                       b.total_amount, b.final_amount, b.vat_rate_snapshot,
                       m.title AS movie_title, m.poster_url AS movie_poster_url,
                       cr.room_name, s.start_time
                FROM Bookings b
                JOIN Showtimes s  ON s.id = b.showtime_id
                JOIN Movies m     ON m.id = s.movie_id
                JOIN CinemaRooms cr ON cr.id = s.room_id
                WHERE b.id = ?
                """;
        String seatSql = """
                SELECT se.seat_code, st.type_name, bs.ticket_price
                FROM BookingSeats bs
                JOIN Seats se     ON se.id = bs.seat_id
                JOIN SeatTypes st ON st.id = se.seat_type_id
                WHERE bs.booking_id = ?
                ORDER BY se.seat_row, se.seat_column
                """;
        try (Connection conn = DBContext.getConnection()) {
            BookingDetailDTO dto = null;
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        dto = new BookingDetailDTO();
                        dto.setBookingId(rs.getString("id"));
                        dto.setBookingCode(rs.getString("booking_code"));
                        dto.setCustomerName(rs.getString("customer_name"));
                        dto.setCustomerPhone(rs.getString("customer_phone"));
                        dto.setBookingStatus(rs.getString("booking_status"));
                        dto.setPaymentStatus(rs.getString("payment_status"));
                        dto.setTotalAmount(rs.getBigDecimal("total_amount"));
                        dto.setFinalAmount(rs.getBigDecimal("final_amount"));
                        dto.setVatRate(rs.getBigDecimal("vat_rate_snapshot"));
                        dto.setMovieTitle(rs.getString("movie_title"));
                        dto.setMoviePosterUrl(rs.getString("movie_poster_url"));
                        dto.setRoomName(rs.getString("room_name"));
                        dto.setStartTime(rs.getTimestamp("start_time"));
                    }
                }
            }
            if (dto == null) return null;

            List<BookingDetailDTO.SeatItem> seats = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(seatSql)) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        seats.add(new BookingDetailDTO.SeatItem(
                                rs.getString("seat_code"),
                                rs.getString("type_name"),
                                rs.getBigDecimal("ticket_price")));
                    }
                }
            }
            dto.setSeats(seats);
            return dto;
        } catch (SQLException e) {
            throw new RuntimeException("getDetailById failed", e);
        }
    }

    /**
     * Xác nhận thanh toán: cập nhật booking_status → CONFIRMED, payment_status → PAID.
     */
    public void confirmPayment(String bookingId) {
        String sql = """
                UPDATE Bookings
                SET booking_status = 'CONFIRMED', payment_status = 'PAID'
                WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("confirmPayment failed", e);
        }
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
