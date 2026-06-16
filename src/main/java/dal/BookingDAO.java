package dal;

import model.dto.BookingDetailDTO;
import model.entity.Booking;
import utils.ConfigKeys;
import utils.ConfigUtil;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class BookingDAO {

    /**
     * FR-35 / FR-38 — Tạo booking tại quầy (OFFLINE).
     * Hỗ trợ khách vãng lai (userId = null) và khách có tài khoản.
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
     * Lấy booking kèm showtime + ghế + vé (nếu đã tạo) để hiển thị trang payment/print.
     */
    public BookingDetailDTO getDetailById(String bookingId) {
        String sql = """
                SELECT b.id, b.booking_code, b.customer_name, b.customer_phone,
                       b.booking_status, b.payment_status,
                       b.total_amount, b.final_amount, b.vat_rate_snapshot,
                       b.user_id,
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
        String ticketSql = """
                SELECT t.ticket_code, t.qr_code, se.seat_code
                FROM Tickets t
                JOIN BookingSeats bs ON bs.id = t.booking_seat_id
                JOIN Seats se        ON se.id = bs.seat_id
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
                        dto.setLinkedUserId(rs.getString("user_id"));
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

            // Tickets (chỉ có sau khi thanh toán)
            List<BookingDetailDTO.TicketItem> tickets = new ArrayList<>();
            try (PreparedStatement ps = conn.prepareStatement(ticketSql)) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        tickets.add(new BookingDetailDTO.TicketItem(
                                rs.getString("ticket_code"),
                                rs.getString("qr_code"),
                                rs.getString("seat_code")));
                    }
                }
            }
            dto.setTickets(tickets);

            return dto;
        } catch (SQLException e) {
            throw new RuntimeException("getDetailById failed", e);
        }
    }

    /**
     * FR-36 — Xác nhận thanh toán tại quầy: lưu Payment record, tạo vé, tích điểm.
     *
     * @param bookingId     ID booking
     * @param paymentMethod "CASH" hoặc "CARD"
     * @param cashReceived  Tiền nhận (chỉ có khi CASH)
     * @param changeAmount  Tiền thừa (chỉ có khi CASH)
     */
    public void confirmPaymentWithDetails(String bookingId, String paymentMethod,
                                          BigDecimal cashReceived, BigDecimal changeAmount) {
        String method = "CARD".equalsIgnoreCase(paymentMethod) ? "CARD" : "CASH";

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);

            // Lấy finalAmount và userId
            BigDecimal finalAmount = BigDecimal.ZERO;
            String userId = null;
            String bookingCode = "";
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT final_amount, user_id, booking_code FROM Bookings WHERE id = ?")) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {
                        finalAmount = rs.getBigDecimal("final_amount");
                        userId = rs.getString("user_id");
                        bookingCode = rs.getString("booking_code");
                    }
                }
            }

            // 1. Cập nhật Bookings
            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE Bookings SET booking_status='CONFIRMED', payment_status='PAID' WHERE id=?")) {
                ps.setString(1, bookingId);
                ps.executeUpdate();
            }

            // 2. Tạo Payment record (idempotent)
            boolean paymentExists = false;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(1) FROM Payments WHERE booking_id = ?")) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) paymentExists = rs.getInt(1) > 0;
                }
            }
            if (!paymentExists) {
                String paymentSql = """
                        INSERT INTO Payments
                            (booking_id, payment_method, payment_source, amount,
                             cash_received, change_amount, payment_status, paid_at)
                        VALUES (?, ?, 'OFFLINE', ?, ?, ?, 'SUCCESS', GETDATE())
                        """;
                try (PreparedStatement ps = conn.prepareStatement(paymentSql)) {
                    ps.setString(1, bookingId);
                    ps.setString(2, method);
                    ps.setBigDecimal(3, finalAmount);
                    if ("CASH".equals(method) && cashReceived != null) {
                        ps.setBigDecimal(4, cashReceived);
                    } else {
                        ps.setNull(4, Types.DECIMAL);
                    }
                    if ("CASH".equals(method) && changeAmount != null) {
                        ps.setBigDecimal(5, changeAmount);
                    } else {
                        ps.setNull(5, Types.DECIMAL);
                    }
                    ps.executeUpdate();
                }
            }

            // 3. FR-18 — Tạo Tickets (idempotent — chỉ tạo cho ghế chưa có vé)
            generateTicketsInTransaction(conn, bookingId, bookingCode);

            // 4. FR-42 — Tích điểm loyalty nếu khách là thành viên
            if (userId != null) {
                addLoyaltyPoints(conn, userId, bookingId, finalAmount);
            }

            conn.commit();
        } catch (SQLException e) {
            throw new RuntimeException("confirmPaymentWithDetails failed", e);
        }
    }

    /**
     * FR-37 — Đánh dấu tất cả vé của booking đã được in.
     */
    public void markTicketsPrinted(String bookingId) {
        String sql = """
                UPDATE t SET t.is_printed = 1
                FROM Tickets t
                JOIN BookingSeats bs ON bs.id = t.booking_seat_id
                WHERE bs.booking_id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("markTicketsPrinted failed", e);
        }
    }

    public BigDecimal getCurrentVatRate() {
        return new VatRuleDAO().findCurrentActiveRate();
    }

    // ── Private helpers ───────────────────────────────────────────

    /**
     * FR-18 — Tạo Ticket record cho từng ghế chưa có vé.
     * ticket_code = "{bookingCode}-{seatCode}", lưu vào qr_code để JS render QR.
     */
    private void generateTicketsInTransaction(Connection conn, String bookingId,
                                              String bookingCode) throws SQLException {
        String seatsSql = """
                SELECT bs.id, se.seat_code
                FROM BookingSeats bs
                JOIN Seats se ON se.id = bs.seat_id
                WHERE bs.booking_id = ?
                  AND NOT EXISTS (SELECT 1 FROM Tickets t WHERE t.booking_seat_id = bs.id)
                """;
        List<String[]> pending = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(seatsSql)) {
            ps.setString(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    pending.add(new String[]{rs.getString(1), rs.getString(2)});
                }
            }
        }
        if (pending.isEmpty()) return;

        String insertSql = "INSERT INTO Tickets (booking_seat_id, ticket_code, qr_code) VALUES (?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            for (String[] row : pending) {
                String code = bookingCode + "-" + row[1];
                ps.setString(1, row[0]);
                ps.setString(2, code);
                ps.setString(3, code);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    /**
     * FR-42 — Cộng điểm loyalty và ghi log.
     * Công thức: points = floor(finalAmount / 1000) * loyaltyEarnRate.
     */
    private void addLoyaltyPoints(Connection conn, String userId, String bookingId,
                                   BigDecimal finalAmount) throws SQLException {
        int earnRate = ConfigUtil.getInt(ConfigKeys.LOYALTY_EARN_RATE, 1);
        if (earnRate <= 0) return;

        int pointsEarned = finalAmount
                .divide(new BigDecimal("1000"), 0, RoundingMode.DOWN)
                .multiply(BigDecimal.valueOf(earnRate))
                .intValue();
        if (pointsEarned <= 0) return;

        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE Users SET loyalty_points = loyalty_points + ? WHERE id = ?")) {
            ps.setInt(1, pointsEarned);
            ps.setString(2, userId);
            ps.executeUpdate();
        }

        String logSql = """
                INSERT INTO LoyaltyPointsLog (user_id, booking_id, points_change, reason)
                VALUES (?, ?, ?, N'Tích điểm từ đặt vé tại quầy')
                """;
        try (PreparedStatement ps = conn.prepareStatement(logSql)) {
            ps.setString(1, userId);
            ps.setString(2, bookingId);
            ps.setInt(3, pointsEarned);
            ps.executeUpdate();
        }
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
