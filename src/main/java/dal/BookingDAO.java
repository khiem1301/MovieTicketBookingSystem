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
import model.dto.BookingHistoryItemDTO;
import model.entity.Booking;
import model.entity.Movie;
import model.entity.PricingRule;
import model.entity.Seat;
import model.entity.Showtime;
import utils.ConfigKeys;
import utils.ConfigUtil;
import utils.PricingCalculator;
import utils.PromotionCalculator;
import utils.SeatHoldException;

public class BookingDAO {

    /** Thời gian thanh toán online (Customer) — countdown trên /payment. */
    public static final int ONLINE_EXPIRE_MINUTES = 5;

    /**
     * FR-35 / FR-38 — Tạo booking tại quầy (OFFLINE).
     * Hỗ trợ khách vãng lai (userId = null) và khách có tài khoản.
     */
    public String createOfflineBooking(String showtimeId, String staffId,
                                       String userId, String customerName, String customerPhone,
                                       List<String> seatIds, List<BigDecimal> seatPrices) {
        return createOfflineBooking(showtimeId, staffId, userId, customerName, customerPhone,
                                    seatIds, seatPrices, 0);
    }

    /** Overload hỗ trợ đổi điểm thưởng tại quầy (FR-43 offline). */
    public String createOfflineBooking(String showtimeId, String staffId,
                                       String userId, String customerName, String customerPhone,
                                       List<String> seatIds, List<BigDecimal> seatPrices,
                                       int pointsToRedeem) {
        return createOfflineBooking(showtimeId, staffId, userId, customerName, customerPhone,
                                    seatIds, seatPrices, pointsToRedeem, null);
    }

    /** Overload hỗ trợ cả đổi điểm lẫn mã voucher tại quầy. */
    public String createOfflineBooking(String showtimeId, String staffId,
                                       String userId, String customerName, String customerPhone,
                                       List<String> seatIds, List<BigDecimal> seatPrices,
                                       int pointsToRedeem, String voucherCode) {
        BigDecimal vatRate    = scaleMoney(getCurrentVatRate());
        BigDecimal totalAmount = scaleMoney(seatPrices.stream()
                .reduce(BigDecimal.ZERO, BigDecimal::add));

        // Tính giảm giá từ mã voucher (áp trên subtotal trước VAT)
        PromotionDAO promoDAO = new PromotionDAO();
        model.entity.Promotion promo = null;
        BigDecimal promoDiscount = BigDecimal.ZERO;
        if (voucherCode != null && !voucherCode.isBlank()) {
            var promoOpt = promoDAO.findByCode(voucherCode.trim());
            if (promoOpt.isPresent() && promoDAO.validateForApply(promoOpt.get()) == null) {
                model.entity.Promotion candidate = promoOpt.get();
                if (utils.PromotionCalculator.validateMinOrder(candidate, totalAmount) == null) {
                    promo = candidate;
                    promoDiscount = utils.PromotionCalculator.calculateDiscount(promo, totalAmount);
                }
            }
        }

        // finalAmount áp dụng sau khi trừ promo discount trên subtotal
        BigDecimal discountedSubtotal = totalAmount.subtract(promoDiscount).max(BigDecimal.ZERO);
        BigDecimal finalAmount = scaleMoney(discountedSubtotal.multiply(
                BigDecimal.ONE.add(vatRate.divide(new BigDecimal("100")))));

        // Tính giảm giá từ điểm thưởng (áp sau VAT, sau promo)
        int redeemRate = ConfigUtil.getInt(ConfigKeys.LOYALTY_REDEEM_RATE, 100);
        int minRedeem  = ConfigUtil.getInt(ConfigKeys.LOYALTY_MIN_REDEEM,  100);
        int maxRedeem  = ConfigUtil.getInt(ConfigKeys.LOYALTY_MAX_REDEEM_PER_ORDER, 5000);
        int effectivePoints = 0;
        BigDecimal pointsDiscount = BigDecimal.ZERO;
        if (pointsToRedeem > 0 && userId != null) {
            int capped  = Math.min(pointsToRedeem, maxRedeem);
            int floored = (capped / redeemRate) * redeemRate;
            if (floored >= minRedeem) {
                effectivePoints = floored;
                pointsDiscount  = BigDecimal.valueOf((long)(effectivePoints / redeemRate) * 10_000);
                if (pointsDiscount.compareTo(finalAmount) > 0) pointsDiscount = finalAmount;
            }
        }
        BigDecimal discountedFinal = finalAmount.subtract(pointsDiscount).max(BigDecimal.ZERO);

        String bookingCode = generateOfflineBookingCode();

        String insertBooking = """
                INSERT INTO Bookings
                    (booking_code, user_id, showtime_id, booking_source,
                     created_by_staff_id, customer_name, customer_phone,
                     vat_rate_snapshot, total_amount, discount_amount, final_amount, points_redeemed,
                     booking_status, payment_status)
                OUTPUT INSERTED.id
                VALUES (?, ?, ?, 'OFFLINE', ?, ?, ?, ?, ?, ?, ?, ?, 'PENDING', 'UNPAID')
                """;

        String insertSeat = """
                INSERT INTO BookingSeats (booking_id, seat_id, ticket_price)
                VALUES (?, ?, ?)
                """;

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            String bookingId;

            // Kiểm tra số dư điểm trước khi tạo booking
            if (effectivePoints > 0) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "SELECT loyalty_points FROM Users WHERE id = ?")) {
                    ps.setString(1, userId);
                    try (ResultSet rs = ps.executeQuery()) {
                        if (!rs.next() || rs.getInt("loyalty_points") < effectivePoints) {
                            conn.rollback();
                            throw new IllegalArgumentException("Số dư điểm không đủ để đổi.");
                        }
                    }
                }
            }

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
                ps.setBigDecimal(9, pointsDiscount);
                ps.setBigDecimal(10, discountedFinal);
                ps.setInt(11, effectivePoints);
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

            // Áp dụng voucher: INSERT BookingPromotions + tăng used_count
            if (promo != null && promoDiscount.compareTo(BigDecimal.ZERO) > 0) {
                boolean applied = promoDAO.incrementUsedCountIfAvailable(conn, promo.getId());
                if (applied) {
                    new BookingPromotionDAO().insert(conn, bookingId, promo.getId(), promoDiscount);
                }
            }

            // Trừ điểm và ghi log
            if (effectivePoints > 0) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE Users SET loyalty_points = loyalty_points - ? WHERE id = ? AND loyalty_points >= ?")) {
                    ps.setInt(1, effectivePoints);
                    ps.setString(2, userId);
                    ps.setInt(3, effectivePoints);
                    if (ps.executeUpdate() == 0) {
                        conn.rollback();
                        throw new IllegalArgumentException("Không đủ điểm để trừ.");
                    }
                }
                try (PreparedStatement ps = conn.prepareStatement("""
                        INSERT INTO LoyaltyPointsLog (user_id, booking_id, points_delta, transaction_type, note)
                        VALUES (?, ?, ?, 'REDEEM', N'Đổi điểm giảm giá đặt vé tại quầy')
                        """)) {
                    ps.setString(1, userId);
                    ps.setString(2, bookingId);
                    ps.setInt(3, -effectivePoints);
                    ps.executeUpdate();
                }
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
     * Lấy booking kèm showtime + ghế + vé (nếu đã tạo) để hiển thị trang payment/print.
     */
    public BookingDetailDTO getDetailById(String bookingId) {
        String sql = """
                SELECT b.id, b.booking_code, b.user_id, b.showtime_id, b.booking_source,
                       b.customer_name, b.customer_phone,
                       b.booking_status, b.payment_status,
                       b.total_amount, b.discount_amount, b.final_amount, b.vat_rate_snapshot,
                       b.expired_at, b.points_redeemed,
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
                        dto.setPointsRedeemed(rs.getInt("points_redeemed"));
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
                dto.setPromoDiscountAmount(ap.discountApplied());
                if (dto.getDiscountAmount() == null || dto.getDiscountAmount().compareTo(BigDecimal.ZERO) == 0) {
                    dto.setDiscountAmount(ap.discountApplied());
                    enrichAmounts(dto);
                }
            }

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
        String method = "VIETQR".equalsIgnoreCase(paymentMethod) ? "VIETQR" : "CASH";

        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);

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

            try (PreparedStatement ps = conn.prepareStatement(
                    "UPDATE Bookings SET booking_status='CONFIRMED', payment_status='PAID' WHERE id=?")) {
                ps.setString(1, bookingId);
                ps.executeUpdate();
            }

            boolean paymentExists = false;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT COUNT(1) FROM Payments WHERE booking_id = ?")) {
                ps.setString(1, bookingId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) paymentExists = rs.getInt(1) > 0;
                }
            }
            // Bỏ qua Payments INSERT khi final_amount = 0 (đơn miễn phí do điểm thưởng)
            if (!paymentExists && finalAmount.compareTo(BigDecimal.ZERO) > 0) {
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

            // FR-18 — Tạo Tickets (idempotent)
            generateTicketsInTransaction(conn, bookingId, bookingCode);

            // FR-42 — Tích điểm loyalty nếu khách là thành viên
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
                    SELECT booking_code, booking_status, payment_status, user_id, showtime_id,
                           final_amount, points_redeemed
                    FROM Bookings WHERE id = ?
                    """;
            String bookingCode;
            String bookingStatus;
            String paymentStatus;
            String userId;
            String showtimeId;
            BigDecimal finalAmount;
            int pointsRedeemed;
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
                    finalAmount = rs.getBigDecimal("final_amount");
                    pointsRedeemed = rs.getInt("points_redeemed");
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

            // FR-43: trừ điểm đã dùng (nếu có)
            if (userId != null && pointsRedeemed > 0) {
                LoyaltyDAO.redeemPoints(conn, userId, bookingId, pointsRedeemed);
            }
            // FR-41: cộng điểm tích luỹ từ đơn online
            if (userId != null && finalAmount != null) {
                LoyaltyDAO.earnPoints(conn, userId, bookingId, finalAmount,
                        "Tích điểm từ đặt vé online");
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

    /** Gia hạn thêm phút cho đơn PENDING khi bắt đầu redirect cổng thanh toán. */
    public void extendPendingExpiry(String bookingId, int extraMinutes) {
        if (bookingId == null || bookingId.isBlank() || extraMinutes <= 0) {
            return;
        }
        String sql = """
                UPDATE Bookings
                SET expired_at = CASE
                    WHEN expired_at > GETDATE() THEN DATEADD(minute, ?, expired_at)
                    ELSE DATEADD(minute, ?, GETDATE())
                END
                WHERE id = ? AND booking_status = 'PENDING' AND payment_status = 'UNPAID'
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, extraMinutes);
            ps.setInt(2, extraMinutes);
            ps.setString(3, bookingId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("extendPendingExpiry failed", e);
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

            if (bpDao.existsForUserExcludingBooking(conn, userId, promotionId, bookingId)) {
                conn.rollback();
                throw new IllegalStateException("Bạn đã sử dụng voucher này rồi.");
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
        return releaseOnlinePendingBooking(bookingId, userId, "CANCELLED");
    }

    /**
     * Hết hạn đơn ONLINE PENDING — giải phóng ghế (booking_status → EXPIRED).
     *
     * @return true nếu cập nhật thành công
     */
    public boolean expireOnlinePendingBooking(String bookingId, String userId) {
        return releaseOnlinePendingBooking(bookingId, userId, "EXPIRED");
    }

    /**
     * Đánh EXPIRED mọi đơn ONLINE PENDING đã quá {@code expired_at} trên suất chiếu.
     * Gọi khi mở sơ đồ ghế để ghế không bị khóa “ma”.
     */
    public int expireStaleOnlinePendingForShowtime(String showtimeId) {
        if (showtimeId == null || showtimeId.isBlank()) {
            return 0;
        }
        String selectSql = """
                SELECT id, user_id
                FROM Bookings
                WHERE showtime_id = ?
                  AND booking_source = 'ONLINE'
                  AND booking_status = 'PENDING'
                  AND payment_status = 'UNPAID'
                  AND expired_at IS NOT NULL
                  AND expired_at <= GETDATE()
                """;
        int count = 0;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(selectSql)) {
            ps.setString(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String bookingId = rs.getString("id");
                    String userId = rs.getString("user_id");
                    if (userId != null && expireOnlinePendingBooking(bookingId, userId)) {
                        count++;
                    }
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("expireStaleOnlinePendingForShowtime failed", e);
        }
        return count;
    }

    private boolean releaseOnlinePendingBooking(String bookingId, String userId, String newStatus) {
        if (!"CANCELLED".equals(newStatus) && !"EXPIRED".equals(newStatus)) {
            throw new IllegalArgumentException("newStatus must be CANCELLED or EXPIRED");
        }
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
                SET booking_status = ?
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
                ps.setString(1, newStatus);
                ps.setString(2, bookingId);
                ps.setString(3, userId);
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
            throw new RuntimeException("releaseOnlinePendingBooking failed", e);
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

    // ── Private helpers ───────────────────────────────────────────

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
                INSERT INTO LoyaltyPointsLog (user_id, booking_id, points_delta, transaction_type, note)
                VALUES (?, ?, ?, 'EARN', N'Tích điểm từ đặt vé tại quầy (offline)')
                """;
        try (PreparedStatement ps = conn.prepareStatement(logSql)) {
            ps.setString(1, userId);
            ps.setString(2, bookingId);
            ps.setInt(3, pointsEarned);
            ps.executeUpdate();
        }
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

    /**
     * FR-20 — true nếu user đã mua vé (CONFIRMED + PAID) cho một suất chiếu của phim này
     * và suất chiếu đó đã bắt đầu. Điều kiện để được viết đánh giá.
     */
    public boolean hasWatchedMovie(String userId, String movieId) {
        String sql = """
                SELECT 1
                FROM Bookings b
                JOIN Showtimes st ON st.id = b.showtime_id
                WHERE b.user_id = ?
                  AND st.movie_id = ?
                  AND b.booking_status = 'CONFIRMED'
                  AND b.payment_status = 'PAID'
                  AND st.start_time <= GETDATE()
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setString(2, movieId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        } catch (SQLException e) {
            throw new RuntimeException("hasWatchedMovie failed", e);
        }
    }

    /** FR-20 — Phim user đã xem (vé CONFIRMED+PAID, suất chiếu đã bắt đầu) — gợi ý đánh giá. */
    public List<Movie> findWatchedMovies(String userId) {
        String sql = """
                SELECT DISTINCT m.id, m.title, m.slug, m.poster_url, m.average_rating
                FROM Bookings b
                JOIN Showtimes st ON st.id = b.showtime_id
                JOIN Movies m     ON m.id = st.movie_id
                WHERE b.user_id = ?
                  AND b.booking_status = 'CONFIRMED'
                  AND b.payment_status = 'PAID'
                  AND st.start_time <= GETDATE()
                ORDER BY m.title
                """;
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Movie m = new Movie();
                    m.setId(rs.getString("id"));
                    m.setTitle(rs.getString("title"));
                    m.setSlug(rs.getString("slug"));
                    m.setPosterUrl(rs.getString("poster_url"));
                    BigDecimal rating = rs.getBigDecimal("average_rating");
                    m.setAverageRating(rating != null ? rating : BigDecimal.ZERO);
                    result.add(m);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findWatchedMovies failed", e);
        }
        return result;
    }

    /**
     * FR-15 — Đếm đơn đã thanh toán thành công (CONFIRMED + PAID) của user.
     */
    public int countHistoryByUserId(String userId) {
        String sql = """
                SELECT COUNT(*) AS cnt
                FROM Bookings b
                WHERE b.user_id = ?
                  AND b.booking_status = 'CONFIRMED'
                  AND b.payment_status = 'PAID'
                """;

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("cnt");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("countHistoryByUserId failed", e);
        }
        return 0;
    }

    /**
     * FR-15 — Danh sách đơn đã thanh toán thành công, mới nhất trước.
     */
    public List<BookingHistoryItemDTO> findHistoryByUserId(String userId, int offset, int limit) {
        String sql = """
                SELECT b.id, b.booking_code, b.booked_at, b.booking_source,
                       b.booking_status, b.payment_status, b.final_amount, b.expired_at,
                       m.title AS movie_title, m.poster_url AS movie_poster_url,
                       cr.room_name, s.start_time,
                       (SELECT COUNT(*) FROM BookingSeats bs WHERE bs.booking_id = b.id) AS seat_count,
                       (SELECT STRING_AGG(se.seat_code, ', ') WITHIN GROUP (ORDER BY se.seat_row, se.seat_column)
                        FROM BookingSeats bs
                        JOIN Seats se ON se.id = bs.seat_id
                        WHERE bs.booking_id = b.id) AS seat_codes
                FROM Bookings b
                JOIN Showtimes s ON s.id = b.showtime_id
                JOIN Movies m ON m.id = s.movie_id
                JOIN CinemaRooms cr ON cr.id = s.room_id
                WHERE b.user_id = ?
                  AND b.booking_status = 'CONFIRMED'
                  AND b.payment_status = 'PAID'
                ORDER BY b.booked_at DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;

        List<BookingHistoryItemDTO> items = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            ps.setInt(2, offset);
            ps.setInt(3, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    items.add(mapHistoryRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findHistoryByUserId failed", e);
        }
        return items;
    }

    private static BookingHistoryItemDTO mapHistoryRow(ResultSet rs) throws SQLException {
        BookingHistoryItemDTO item = new BookingHistoryItemDTO();
        item.setBookingId(rs.getString("id"));
        item.setBookingCode(rs.getString("booking_code"));
        item.setBookedAt(rs.getTimestamp("booked_at"));
        item.setBookingSource(rs.getString("booking_source"));
        item.setBookingStatus(rs.getString("booking_status"));
        item.setPaymentStatus(rs.getString("payment_status"));
        item.setFinalAmount(rs.getBigDecimal("final_amount"));
        item.setExpiredAt(rs.getTimestamp("expired_at"));
        item.setMovieTitle(rs.getString("movie_title"));
        item.setMoviePosterUrl(rs.getString("movie_poster_url"));
        item.setRoomName(rs.getString("room_name"));
        item.setStartTime(rs.getTimestamp("start_time"));
        item.setSeatCount(rs.getInt("seat_count"));
        item.setSeatCodesSummary(rs.getString("seat_codes"));
        return item;
    }

    public int countConfirmedByUserId(String userId) {
        String sql = """
                SELECT COUNT(*) AS cnt
                FROM Bookings
                WHERE user_id = ? AND booking_status = 'CONFIRMED'
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("cnt");
            }
        } catch (SQLException e) {
            throw new RuntimeException("countConfirmedByUserId failed", e);
        }
        return 0;
    }

    // ── Sprint 3: Offline booking history ─────────────────────────────

    /**
     * Lấy danh sách booking OFFLINE có filter + phân trang.
     *
     * @param dateFrom   yyyy-MM-dd hoặc null
     * @param dateTo     yyyy-MM-dd hoặc null
     * @param status     "CONFIRMED", "PENDING", "CANCELLED" hoặc null (tất cả)
     * @param search     tìm theo tên hoặc SĐT khách hoặc booking_code, null = không lọc
     * @param page       trang bắt đầu từ 1
     * @param pageSize   số bản ghi mỗi trang
     */
    public List<model.dto.OfflineBookingDTO> getOfflineBookings(
            String dateFrom, String dateTo, String status, String search,
            int page, int pageSize) {

        StringBuilder where = new StringBuilder("WHERE b.booking_source = 'OFFLINE'");
        List<Object> params = new java.util.ArrayList<>();

        if (dateFrom != null && !dateFrom.isBlank()) {
            where.append(" AND CAST(b.booked_at AS DATE) >= ?");
            params.add(dateFrom);
        }
        if (dateTo != null && !dateTo.isBlank()) {
            where.append(" AND CAST(b.booked_at AS DATE) <= ?");
            params.add(dateTo);
        }
        if (status != null && !status.isBlank()) {
            where.append(" AND b.booking_status = ?");
            params.add(status);
        }
        if (search != null && !search.isBlank()) {
            where.append(" AND (b.customer_name LIKE ? OR b.customer_phone LIKE ? OR b.booking_code LIKE ?)");
            String like = "%" + search.trim() + "%";
            params.add(like); params.add(like); params.add(like);
        }

        String sql = """
                SELECT b.id, b.booking_code, b.customer_name, b.customer_phone,
                       m.title AS movie_title, cr.room_name,
                       s.start_time, b.booked_at,
                       (SELECT COUNT(*) FROM BookingSeats bs WHERE bs.booking_id = b.id) AS seat_count,
                       b.total_amount, b.final_amount,
                       b.booking_status, b.payment_status,
                       u.full_name AS staff_name, b.user_id
                FROM Bookings b
                JOIN Showtimes s  ON s.id  = b.showtime_id
                JOIN Movies m     ON m.id  = s.movie_id
                JOIN CinemaRooms cr ON cr.id = s.room_id
                LEFT JOIN Users u ON u.id  = b.created_by_staff_id
                """ + where + """
                ORDER BY b.booked_at DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;

        List<model.dto.OfflineBookingDTO> list = new java.util.ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int i = 1;
            for (Object p : params) ps.setObject(i++, p);
            ps.setInt(i++, (page - 1) * pageSize);
            ps.setInt(i,   pageSize);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    model.dto.OfflineBookingDTO dto = new model.dto.OfflineBookingDTO();
                    dto.setBookingId(rs.getString("id"));
                    dto.setBookingCode(rs.getString("booking_code"));
                    dto.setCustomerName(rs.getString("customer_name"));
                    dto.setCustomerPhone(rs.getString("customer_phone"));
                    dto.setMovieTitle(rs.getString("movie_title"));
                    dto.setRoomName(rs.getString("room_name"));
                    dto.setStartTime(rs.getTimestamp("start_time"));
                    dto.setBookedAt(rs.getTimestamp("booked_at"));
                    dto.setSeatCount(rs.getInt("seat_count"));
                    dto.setTotalAmount(rs.getBigDecimal("total_amount"));
                    dto.setFinalAmount(rs.getBigDecimal("final_amount"));
                    dto.setBookingStatus(rs.getString("booking_status"));
                    dto.setPaymentStatus(rs.getString("payment_status"));
                    dto.setStaffName(rs.getString("staff_name"));
                    dto.setUserId(rs.getString("user_id"));
                    list.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("getOfflineBookings failed", e);
        }
        return list;
    }

    /** Đếm tổng booking OFFLINE khớp filter (dùng để tính số trang). */
    public int countOfflineBookings(String dateFrom, String dateTo, String status, String search) {
        StringBuilder where = new StringBuilder("WHERE b.booking_source = 'OFFLINE'");
        List<Object> params = new java.util.ArrayList<>();

        if (dateFrom != null && !dateFrom.isBlank()) {
            where.append(" AND CAST(b.booked_at AS DATE) >= ?");
            params.add(dateFrom);
        }
        if (dateTo != null && !dateTo.isBlank()) {
            where.append(" AND CAST(b.booked_at AS DATE) <= ?");
            params.add(dateTo);
        }
        if (status != null && !status.isBlank()) {
            where.append(" AND b.booking_status = ?");
            params.add(status);
        }
        if (search != null && !search.isBlank()) {
            where.append(" AND (b.customer_name LIKE ? OR b.customer_phone LIKE ? OR b.booking_code LIKE ?)");
            String like = "%" + search.trim() + "%";
            params.add(like); params.add(like); params.add(like);
        }

        String sql = "SELECT COUNT(*) FROM Bookings b " + where;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int i = 1;
            for (Object p : params) ps.setObject(i++, p);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt(1);
            }
        } catch (SQLException e) {
            throw new RuntimeException("countOfflineBookings failed", e);
        }
        return 0;
    }
}
