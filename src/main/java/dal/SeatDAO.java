package dal;

import model.entity.Seat;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SeatDAO {

    /**
     * FR-35 / FR-12 — Lấy tất cả ghế active của phòng chiếu, kèm trạng thái available/booked/held.
     * Tính sẵn ticketPrice = base_price × price_multiplier (staff counter).
     * Servlet customer ghi đè ticketPrice sau khi có effectivePrice từ PricingCalculator.
     *
     * Ghế unavailable khi:
     * - BookingSeats thuộc booking PENDING/CONFIRMED cùng suất, hoặc
     * - SeatHolds cùng (showtime_id, seat_id) với expired_at > GETDATE()
     *   (trừ hold của chính currentUserId khi gọi overload 2 tham số — FR-13).
     */
    public List<Seat> getSeatsForShowtime(String showtimeId) {
        return querySeatsForShowtime(showtimeId, null);
    }

    /** FR-13 — Checkout online: ghế user đang giữ vẫn available trên sơ đồ. */
    public List<Seat> getSeatsForShowtime(String showtimeId, String currentUserId) {
        return querySeatsForShowtime(showtimeId, currentUserId);
    }

    private List<Seat> querySeatsForShowtime(String showtimeId, String currentUserId) {
        boolean forCustomer = currentUserId != null && !currentUserId.isBlank();

        String availabilityCase = forCustomer ? """
                CASE
                    WHEN bs.seat_id IS NOT NULL THEN 0
                    WHEN sh_hold.seat_id IS NOT NULL
                         AND (sh_hold.user_id IS NULL OR sh_hold.user_id <> ?) THEN 0
                    ELSE 1
                END
                """ : """
                CASE
                    WHEN bs.seat_id IS NULL AND sh_hold.seat_id IS NULL THEN 1
                    ELSE 0
                END
                """;

        String heldByMeCase = forCustomer
                ? "CASE WHEN sh_hold.user_id = ? THEN 1 ELSE 0 END"
                : "0";

        String sql = """
                SELECT s.id, s.room_id, s.seat_type_id, st.type_name, st.price_multiplier,
                       s.seat_row, s.seat_column, s.seat_code, s.status,
                       sh.base_price,
                       %s AS is_available,
                       %s AS held_by_me
                FROM Showtimes sh
                JOIN Seats s      ON s.room_id = sh.room_id
                JOIN SeatTypes st ON st.id = s.seat_type_id
                LEFT JOIN BookingSeats bs ON bs.seat_id = s.id
                    AND bs.booking_id IN (
                        SELECT b.id FROM Bookings b
                        WHERE b.showtime_id = sh.id
                          AND b.booking_status IN ('PENDING', 'CONFIRMED')
                    )
                LEFT JOIN SeatHolds sh_hold ON sh_hold.seat_id = s.id
                    AND sh_hold.showtime_id = sh.id
                    AND sh_hold.expired_at > GETDATE()
                WHERE sh.id = ?
                  AND s.status = 'ACTIVE'
                ORDER BY s.seat_row, s.seat_column
                """.formatted(availabilityCase, heldByMeCase);

        List<Seat> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int i = 1;
            if (forCustomer) {
                ps.setString(i++, currentUserId);
                ps.setString(i++, currentUserId);
            }
            ps.setString(i, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getSeatsForShowtime failed", e);
        }
        return result;
    }

    /** FR-26 — Ghế layout của phòng (không gồm BROKEN) cho editor manager. */
    public List<Seat> getSeatsByRoom(String roomId) {
        String sql = """
                SELECT s.id, s.room_id, s.seat_type_id, st.type_name, st.price_multiplier,
                       s.seat_row, s.seat_column, s.seat_code, s.status
                FROM Seats s
                JOIN SeatTypes st ON st.id = s.seat_type_id
                WHERE s.room_id = ? AND s.status <> 'BROKEN'
                ORDER BY s.seat_row, s.seat_column
                """;
        List<Seat> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRoomSeat(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getSeatsByRoom failed", e);
        }
        return result;
    }

    /**
     * FR-26 — Lưu layout ghế: xóa ghế non-BROKEN, upsert ghế mới, sync capacity.
     */
    public void saveLayout(String roomId, List<Seat> seats) {
        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            String deleteSql = "DELETE FROM Seats WHERE room_id = ? AND status <> 'BROKEN'";
            try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
                ps.setString(1, roomId);
                ps.executeUpdate();
            }

            String updateBrokenSql = """
                    UPDATE Seats SET status = 'ACTIVE', seat_type_id = ?, seat_row = ?, seat_column = ?
                    WHERE room_id = ? AND seat_code = ? AND status = 'BROKEN'
                    """;
            String insertSql = """
                    INSERT INTO Seats (id, room_id, seat_type_id, seat_row, seat_column, seat_code, status)
                    VALUES (NEWID(), ?, ?, ?, ?, ?, 'ACTIVE')
                    """;

            for (Seat seat : seats) {
                int updated;
                try (PreparedStatement ps = conn.prepareStatement(updateBrokenSql)) {
                    ps.setString(1, seat.getSeatTypeId());
                    ps.setString(2, seat.getSeatRow());
                    ps.setInt(3, seat.getSeatColumn());
                    ps.setString(4, roomId);
                    ps.setString(5, seat.getSeatCode());
                    updated = ps.executeUpdate();
                }
                if (updated == 0) {
                    try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                        ps.setString(1, roomId);
                        ps.setString(2, seat.getSeatTypeId());
                        ps.setString(3, seat.getSeatRow());
                        ps.setInt(4, seat.getSeatColumn());
                        ps.setString(5, seat.getSeatCode());
                        ps.executeUpdate();
                    }
                }
            }

            String syncCapSql = """
                    UPDATE CinemaRooms
                    SET capacity = (
                        SELECT COUNT(*) FROM Seats WHERE room_id = ? AND status = 'ACTIVE'
                    )
                    WHERE id = ?
                    """;
            try (PreparedStatement ps = conn.prepareStatement(syncCapSql)) {
                ps.setString(1, roomId);
                ps.setString(2, roomId);
                ps.executeUpdate();
            }

            conn.commit();
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            throw new RuntimeException("saveLayout failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    private Seat mapRoomSeat(ResultSet rs) throws SQLException {
        Seat s = new Seat();
        s.setId(rs.getString("id"));
        s.setRoomId(rs.getString("room_id"));
        s.setSeatTypeId(rs.getString("seat_type_id"));
        s.setSeatTypeName(rs.getString("type_name"));
        s.setPriceMultiplier(rs.getBigDecimal("price_multiplier"));
        s.setSeatRow(rs.getString("seat_row"));
        s.setSeatColumn(rs.getInt("seat_column"));
        s.setSeatCode(rs.getString("seat_code"));
        s.setStatus(rs.getString("status"));
        return s;
    }

    private Seat mapRow(ResultSet rs) throws SQLException {
        Seat s = new Seat();
        s.setId(rs.getString("id"));
        s.setRoomId(rs.getString("room_id"));
        s.setSeatTypeId(rs.getString("seat_type_id"));
        s.setSeatTypeName(rs.getString("type_name"));
        BigDecimal multiplier = rs.getBigDecimal("price_multiplier");
        s.setPriceMultiplier(multiplier);
        s.setSeatRow(rs.getString("seat_row"));
        s.setSeatColumn(rs.getInt("seat_column"));
        s.setSeatCode(rs.getString("seat_code"));
        s.setStatus(rs.getString("status"));
        s.setAvailable(rs.getInt("is_available") == 1);
        s.setHeldByCurrentUser(rs.getInt("held_by_me") == 1);

        BigDecimal basePrice = rs.getBigDecimal("base_price");
        if (basePrice != null && multiplier != null) {
            s.setTicketPrice(basePrice.multiply(multiplier));
        }
        return s;
    }
}
