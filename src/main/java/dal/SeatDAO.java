package dal;

import model.entity.Seat;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class SeatDAO {

    /**
     * FR-35 — Lấy tất cả ghế active của phòng chiếu, kèm trạng thái available/booked.
     * Tính sẵn ticketPrice = base_price × price_multiplier để hiển thị trực tiếp trong UI.
     *
     * Chú thích: kiểm tra availability đầy đủ (FR-13 — Seat Availability Validation)
     * sẽ được Khiêm bổ sung ở Sprint 2. Hiện tại ghế bị đánh dấu unavailable
     * khi đã có BookingSeats với booking PENDING/CONFIRMED cho cùng suất chiếu.
     */
    public List<Seat> getSeatsForShowtime(String showtimeId) {
        String sql = """
                SELECT s.id, s.room_id, s.seat_type_id, st.type_name, st.price_multiplier,
                       s.seat_row, s.seat_column, s.seat_code, s.status,
                       sh.base_price,
                       CASE
                           WHEN bs.seat_id IS NULL THEN 1
                           ELSE 0
                       END AS is_available
                FROM Showtimes sh
                JOIN Seats s      ON s.room_id = sh.room_id
                JOIN SeatTypes st ON st.id = s.seat_type_id
                LEFT JOIN BookingSeats bs ON bs.seat_id = s.id
                    AND bs.booking_id IN (
                        SELECT b.id FROM Bookings b
                        WHERE b.showtime_id = sh.id
                          AND b.booking_status IN ('PENDING', 'CONFIRMED')
                    )
                WHERE sh.id = ?
                  AND s.status = 'ACTIVE'
                ORDER BY s.seat_row, s.seat_column
                """;
        List<Seat> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getSeatsForShowtime failed", e);
        }
        return result;
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

        BigDecimal basePrice = rs.getBigDecimal("base_price");
        if (basePrice != null && multiplier != null) {
            s.setTicketPrice(basePrice.multiply(multiplier));
        }
        return s;
    }
}
