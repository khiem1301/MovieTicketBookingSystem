package dal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;

import model.dto.BookingDetailDTO;
import model.entity.Booking;
import model.entity.PricingRule;
import model.entity.Seat;
import model.entity.Showtime;
import utils.PricingCalculator;
import utils.PromotionCalculator;
import utils.SeatHoldException;

/**
 * FR-39 — Booking Source Management
 * DAO xử lý tạo và truy vấn booking, gắn flag ONLINE/OFFLINE vào mỗi đơn.
 */
public class BookingDAO {

    public static final int ONLINE_EXPIRE_MINUTES = 10;

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
        BigDecimal vatRate = scaleMoney(getCurrentVatRate());
        BigDecimal totalAmount = scaleMoney(seatPrices.stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add));
        BigDecimal finalAmount = scaleMoney(totalAmount.multiply(
                BigDecimal.ONE.add(vatRate.divide(new BigDecimal("100")))));

        String bookingCode = generateOfflineBookingCode();

        String insertBooking = """
                INSERT INTO Bookings
                    (booking_code, user_id, showtime_id, booking_source,
                     created_by_staff_id, customer_name, customer_phone,
                     vat_rate_snapshot, total_amount, discount_amount, final_amount,
                     booking_status, payment_status)
                OUTPUT INSERTED.id
                VALUES (?, ?, ?, 'OFFLINE', ?, ?, ?, ?, ?, 0, ?, 'PENDING', 'UNPAID')
                """;

        String insertSeat = """
                INSERT INTO BookingSeats (booking_id, seat_id, ticket_price)
                VALUES (?, ?, ?)
                """;

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            String bookingId;

            try (PreparedStatement ps = conn.prepareStatement(insertBooking)) {
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
                try (ResultSet rs = ps.executeQuery()) {
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

    /**
     * FR-14 — Tạo đơn đặt vé online: validate ghế, tính giá server-side, INSERT Bookings + BookingSeats.
     * Idempotent khi user đã có booking PENDING/UNPAID cùng suất và chưa hết hạn.
     */
    public String createOnlineBooking(String showtimeId, String userId, List<String> seatIds) {
        if (seatIds == null || seatIds.isEmpty()) {
            throw new IllegalArgumentException("seatIds must not be empty");
        }

        List<String> distinctSeatIds = SeatHoldDAO.distinctSeatIds(seatIds);

        String existingId = findActiveOnlinePendingBookingId(showtimeId, userId);
        if (existingId != null) {
            return existingId;
        }

        SeatHoldDAO holdDAO = new SeatHoldDAO();
        List<String> blocked = holdDAO.findBlockingSeatCodes(showtimeId, distinctSeatIds, userId);
        if (!blocked.isEmpty()) {
            throw new SeatHoldException("Ghế không còn trống: " + String.join(", ", blocked));
        }
        if (holdDAO.countValidSeatsForShowtime(showtimeId, distinctSeatIds) != distinctSeatIds.size()) {
            throw new SeatHoldException("Danh sách ghế không hợp lệ cho suất chiếu này.");
        }

        Showtime showtime = new ShowtimeDAO().getShowtimeById(showtimeId);
        if (showtime == null) {
            throw new SeatHoldException("Suất chiếu không tồn tại.");
        }

        List<PricingRule> pricingRules = new PricingRuleDAO().getActiveRules();
        BigDecimal effectivePrice = PricingCalculator.calculateEffectivePrice(showtime, pricingRules);
        List<BigDecimal> seatPrices = computeSeatPrices(showtimeId, distinctSeatIds, effectivePrice);

        BigDecimal vatRate = scaleMoney(getCurrentVatRate());
        BigDecimal totalAmount = scaleMoney(seatPrices.stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add));
        BigDecimal finalAmount = scaleMoney(totalAmount.multiply(
                BigDecimal.ONE.add(vatRate.divide(new BigDecimal("100")))));

        String bookingCode = generateOnlineBookingCode();

        String insertBooking = """
                INSERT INTO Bookings
                    (booking_code, user_id, showtime_id, booking_source,
                     created_by_staff_id, customer_name, customer_phone,
                     vat_rate_snapshot, total_amount, discount_amount, final_amount,
                     booking_status, payment_status, expired_at)
                OUTPUT INSERTED.id
                VALUES (?, ?, ?, 'ONLINE', NULL, NULL, NULL,
                        ?, ?, 0, ?, 'PENDING', 'UNPAID',
                        DATEADD(MINUTE, ?, GETDATE()))
                """;

        String insertSeat = """
                INSERT INTO BookingSeats (booking_id, seat_id, ticket_price)
                VALUES (?, ?, ?)
                """;

        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);
            holdDAO.deleteExpiredHolds();

            String bookingId;
            try (PreparedStatement ps = conn.prepareStatement(insertBooking)) {
                ps.setString(1, bookingCode);
                ps.setString(2, userId);
                ps.setString(3, showtimeId);
                ps.setBigDecimal(4, vatRate);
                ps.setBigDecimal(5, totalAmount);
                ps.setBigDecimal(6, finalAmount);
                ps.setInt(7, ONLINE_EXPIRE_MINUTES);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) throw new SQLException("Không lấy được booking ID");
                    bookingId = rs.getString(1);
                }
            }

            try (PreparedStatement ps = conn.prepareStatement(insertSeat)) {
                for (int i = 0; i < distinctSeatIds.size(); i++) {
                    ps.setString(1, bookingId);
                    ps.setString(2, distinctSeatIds.get(i));
                    ps.setBigDecimal(3, seatPrices.get(i));
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            conn.commit();
            new SeatHoldDAO().releaseHolds(showtimeId, userId);
            return bookingId;

        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            if (isUniqueViolation(e)) {
                String retryId = findActiveOnlinePendingBookingId(showtimeId, userId);
                if (retryId != null) return retryId;
                throw new SeatHoldException(
                        "Một hoặc nhiều ghế vừa bị người khác chọn. Vui lòng chọn lại.");
            }
            throw new RuntimeException("createOnlineBooking failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    /** Booking ONLINE PENDING/UNPAID còn hiệu lực của user trên suất (idempotency FR-14). */
    public String findActiveOnlinePendingBookingId(String showtimeId, String userId) {
        String sql = """
                SELECT TOP 1 id
                FROM Bookings
                WHERE user_id = ?
                  AND showtime_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                  AND expired_at > GETDATE()
                ORDER BY booked_at DESC
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setString(2, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString("id");
            }
        } catch (SQLException e) {
            throw new RuntimeException("findActiveOnlinePendingBookingId failed", e);
        }
        return null;
    }

    private List<BigDecimal> computeSeatPrices(String showtimeId, List<String> seatIds,
                                               BigDecimal effectivePrice) {
        if (effectivePrice == null) {
            throw new SeatHoldException("Không tính được giá vé cho suất chiếu.");
        }

        List<Seat> seats = new SeatDAO().getSeatsForShowtime(showtimeId);
        Map<String, Seat> seatById = new HashMap<>();
        for (Seat seat : seats) {
            seatById.put(seat.getId(), seat);
        }

        List<BigDecimal> prices = new ArrayList<>(seatIds.size());
        for (String seatId : seatIds) {
            Seat seat = seatById.get(seatId);
            if (seat == null) {
                throw new SeatHoldException("Danh sách ghế không hợp lệ cho suất chiếu này.");
            }
            BigDecimal multiplier = seat.getPriceMultiplier() != null
                    ? seat.getPriceMultiplier() : BigDecimal.ONE;
            prices.add(scaleMoney(effectivePrice.multiply(multiplier).setScale(0, RoundingMode.HALF_UP)));
        }
        return prices;
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
                SELECT b.id, b.booking_code, b.user_id, b.showtime_id, b.booking_source,
                       b.customer_name, b.customer_phone,
                       b.booking_status, b.payment_status,
                       b.total_amount, b.discount_amount, b.final_amount, b.vat_rate_snapshot,
                       b.expired_at,
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
                        dto.setUserId(rs.getString("user_id"));
                        dto.setShowtimeId(rs.getString("showtime_id"));
                        dto.setBookingSource(rs.getString("booking_source"));
                        dto.setExpiredAt(rs.getTimestamp("expired_at"));
                        dto.setCustomerName(rs.getString("customer_name"));
                        dto.setCustomerPhone(rs.getString("customer_phone"));
                        dto.setBookingStatus(rs.getString("booking_status"));
                        dto.setPaymentStatus(rs.getString("payment_status"));
                        dto.setTotalAmount(rs.getBigDecimal("total_amount"));
                        dto.setDiscountAmount(rs.getBigDecimal("discount_amount"));
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
            enrichAmounts(dto);
            var appliedPromo = new BookingPromotionDAO().findByBookingId(bookingId);
            if (appliedPromo.isPresent()) {
                var ap = appliedPromo.get();
                dto.setAppliedPromoCode(ap.code());
                dto.setAppliedPromoTitle(ap.title());
                if (dto.getDiscountAmount() == null || dto.getDiscountAmount().compareTo(BigDecimal.ZERO) == 0) {
                    dto.setDiscountAmount(ap.discountApplied());
                    enrichAmounts(dto);
                }
            }
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

    /**
     * FR-16/17 — Hoàn tất thanh toán online (VietQR): cập nhật Payment + Booking + phát hành Tickets.
     * Idempotent — nếu đơn đã PAID thì trả true.
     */
    public boolean completeOnlinePayment(String bookingId, String paymentId, String externalTransId) {
        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            String statusSql = """
                    SELECT booking_code, booking_status, payment_status, user_id, showtime_id
                    FROM Bookings WHERE id = ?
                    """;
            String bookingCode;
            String bookingStatus;
            String paymentStatus;
            String userId;
            String showtimeId;
            try (PreparedStatement ps = conn.prepareStatement(statusSql)) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        return false;
                    }
                    bookingCode = rs.getString("booking_code");
                    bookingStatus = rs.getString("booking_status");
                    paymentStatus = rs.getString("payment_status");
                    userId = rs.getString("user_id");
                    showtimeId = rs.getString("showtime_id");
                }
            }

            if ("PAID".equals(paymentStatus) && "CONFIRMED".equals(bookingStatus)) {
                conn.commit();
                return true;
            }
            if (!"PENDING".equals(bookingStatus) || !"UNPAID".equals(paymentStatus)) {
                conn.rollback();
                return false;
            }

            PaymentDAO paymentDAO = new PaymentDAO();
            paymentDAO.markSuccess(conn, paymentId, externalTransId);

            String updateBookingSql = """
                    UPDATE Bookings
                    SET booking_status = 'CONFIRMED', payment_status = 'PAID'
                    WHERE id = ? AND booking_status = 'PENDING' AND payment_status = 'UNPAID'
                    """;
            try (PreparedStatement ps = conn.prepareStatement(updateBookingSql)) {
                ps.setString(1, bookingId);
                if (ps.executeUpdate() == 0) {
                    conn.rollback();
                    return false;
                }
            }

            new TicketDAO().issueTicketsForBooking(conn, bookingId, bookingCode);

            if (showtimeId != null && userId != null) {
                String deleteHoldsSql = """
                        DELETE FROM SeatHolds WHERE showtime_id = ? AND user_id = ?
                        """;
                try (PreparedStatement ps = conn.prepareStatement(deleteHoldsSql)) {
                    ps.setString(1, showtimeId);
                    ps.setString(2, userId);
                    ps.executeUpdate();
                }
            }

            conn.commit();
            return true;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            throw new RuntimeException("completeOnlinePayment failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    /** Đánh dấu payment online thất bại (không đụng booking PENDING). */
    public void failOnlinePayment(String paymentId) {
        try (Connection conn = DBContext.getConnection()) {
            new PaymentDAO().markFailed(conn, paymentId);
        } catch (SQLException e) {
            throw new RuntimeException("failOnlinePayment failed", e);
        }
    }

    /**
     * FR-22 — Áp mã voucher vào đơn ONLINE PENDING (thay mã cũ nếu có).
     */
    public void applyPromotionToBooking(String bookingId, String userId, String promotionId,
                                        BigDecimal discountAmount, BigDecimal finalAmount) {
        BookingPromotionDAO bpDao = new BookingPromotionDAO();
        PromotionDAO promoDao = new PromotionDAO();

        String updateBookingSql = """
                UPDATE Bookings
                SET discount_amount = ?, final_amount = ?
                WHERE id = ?
                  AND user_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                  AND expired_at > GETDATE()
                """;

        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            if (!existsPendingOnlineBooking(conn, bookingId, userId)) {
                conn.rollback();
                throw new IllegalStateException("Đơn đặt vé không còn ở trạng thái chờ thanh toán.");
            }

            var existing = bpDao.findByBookingId(conn, bookingId);
            if (existing.isPresent()) {
                if (existing.get().promotionId().equals(promotionId)) {
                    conn.commit();
                    return;
                }
                promoDao.decrementUsedCount(conn, existing.get().promotionId());
                bpDao.deleteByBookingId(conn, bookingId);
            }

            if (!promoDao.incrementUsedCountIfAvailable(conn, promotionId)) {
                conn.rollback();
                throw new IllegalStateException("Mã voucher đã hết lượt sử dụng hoặc không còn hiệu lực.");
            }

            bpDao.insert(conn, bookingId, promotionId, discountAmount);

            try (PreparedStatement ps = conn.prepareStatement(updateBookingSql)) {
                ps.setBigDecimal(1, discountAmount);
                ps.setBigDecimal(2, finalAmount);
                ps.setString(3, bookingId);
                ps.setString(4, userId);
                if (ps.executeUpdate() == 0) {
                    conn.rollback();
                    throw new IllegalStateException("Không thể cập nhật đơn đặt vé.");
                }
            }

            conn.commit();
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            throw new RuntimeException("applyPromotionToBooking failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    /**
     * FR-22 — Gỡ mã voucher khỏi đơn PENDING và hoàn lượt sử dụng.
     */
    public void removePromotionFromBooking(String bookingId, String userId) {
        BookingPromotionDAO bpDao = new BookingPromotionDAO();
        PromotionDAO promoDao = new PromotionDAO();

        String selectAmountsSql = """
                SELECT total_amount, vat_rate_snapshot
                FROM Bookings
                WHERE id = ?
                  AND user_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                  AND expired_at > GETDATE()
                """;
        String updateBookingSql = """
                UPDATE Bookings
                SET discount_amount = 0, final_amount = ?
                WHERE id = ?
                  AND user_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                  AND expired_at > GETDATE()
                """;

        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            var existing = bpDao.findByBookingId(conn, bookingId);
            if (existing.isEmpty()) {
                conn.rollback();
                return;
            }

            BigDecimal totalAmount;
            BigDecimal vatRate;
            try (PreparedStatement ps = conn.prepareStatement(selectAmountsSql)) {
                ps.setString(1, bookingId);
                ps.setString(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        throw new IllegalStateException("Đơn đặt vé không còn ở trạng thái chờ thanh toán.");
                    }
                    totalAmount = rs.getBigDecimal("total_amount");
                    vatRate = rs.getBigDecimal("vat_rate_snapshot");
                }
            }

            promoDao.decrementUsedCount(conn, existing.get().promotionId());
            bpDao.deleteByBookingId(conn, bookingId);

            BigDecimal finalAmount = PromotionCalculator.recalculateFinalAmount(
                    totalAmount, BigDecimal.ZERO, vatRate);

            try (PreparedStatement ps = conn.prepareStatement(updateBookingSql)) {
                ps.setBigDecimal(1, finalAmount);
                ps.setString(2, bookingId);
                ps.setString(3, userId);
                ps.executeUpdate();
            }

            conn.commit();
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            throw new RuntimeException("removePromotionFromBooking failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    private void enrichAmounts(BookingDetailDTO dto) {
        BigDecimal total = dto.getTotalAmount() != null ? dto.getTotalAmount() : BigDecimal.ZERO;
        BigDecimal discount = dto.getDiscountAmount() != null ? dto.getDiscountAmount() : BigDecimal.ZERO;
        dto.setDiscountAmount(discount);
        dto.setVatAmount(PromotionCalculator.calculateVatAmount(total, discount, dto.getVatRate()));
    }

    private boolean existsPendingOnlineBooking(Connection conn, String bookingId, String userId)
            throws SQLException {
        String sql = """
                SELECT 1 FROM Bookings
                WHERE id = ?
                  AND user_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                  AND expired_at > GETDATE()
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            ps.setString(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    /**
     * Hủy đơn ONLINE đang chờ thanh toán — giải phóng ghế ngay (booking_status → CANCELLED).
     * Đồng thời xóa SeatHolds còn sót và hoàn lượt voucher nếu có (FR-22).
     *
     * @return true nếu hủy thành công
     */
    public boolean cancelOnlinePendingBooking(String bookingId, String userId) {
        String selectSql = """
                SELECT showtime_id
                FROM Bookings
                WHERE id = ?
                  AND user_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                """;
        String updateSql = """
                UPDATE Bookings
                SET booking_status = 'CANCELLED'
                WHERE id = ?
                  AND user_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                """;
        String deleteHoldsSql = """
                DELETE FROM SeatHolds
                WHERE showtime_id = ?
                  AND user_id = ?
                """;

        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            String showtimeId;
            try (PreparedStatement ps = conn.prepareStatement(selectSql)) {
                ps.setString(1, bookingId);
                ps.setString(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (!rs.next()) {
                        conn.rollback();
                        return false;
                    }
                    showtimeId = rs.getString("showtime_id");
                }
            }

            int updated;
            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, bookingId);
                ps.setString(2, userId);
                updated = ps.executeUpdate();
            }
            if (updated == 0) {
                conn.rollback();
                return false;
            }

            BookingPromotionDAO bpDao = new BookingPromotionDAO();
            PromotionDAO promoDao = new PromotionDAO();
            var appliedPromo = bpDao.findByBookingId(conn, bookingId);
            if (appliedPromo.isPresent()) {
                bpDao.deleteByBookingId(conn, bookingId);
                promoDao.decrementUsedCount(conn, appliedPromo.get().promotionId());
            }

            try (PreparedStatement ps = conn.prepareStatement(deleteHoldsSql)) {
                ps.setString(1, showtimeId);
                ps.setString(2, userId);
                ps.executeUpdate();
            }

            conn.commit();
            return true;

        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            throw new RuntimeException("cancelOnlinePendingBooking failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    /** Lấy VAT rate hiện hành từ VatRules; fallback 8% nếu chưa cấu hình. */
    public BigDecimal getCurrentVatRate() {
        return new VatRuleDAO().findCurrentActiveRate();
    }

    private BigDecimal scaleMoney(BigDecimal value) {
        if (value == null) return BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP);
        return value.setScale(2, RoundingMode.HALF_UP);
    }

    private String generateOfflineBookingCode() {
        return "CTR" + System.currentTimeMillis();
    }

    private String generateOnlineBookingCode() {
        String date = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);
        int suffix = ThreadLocalRandom.current().nextInt(1000, 10000);
        return "BK-" + date + "-" + suffix;
    }

    private boolean isUniqueViolation(SQLException e) {
        int code = e.getErrorCode();
        return code == 2627 || code == 2601;
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
