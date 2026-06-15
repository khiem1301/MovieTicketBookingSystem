package dal;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

import utils.SeatHoldException;

/**
 * FR-13 — Giữ ghế tạm (SeatHolds) và kiểm tra availability trước khi INSERT.
 */
public class SeatHoldDAO {

    public static final int HOLD_MINUTES = 10;

    /**
     * Trả về mã ghế (seat_code) không thể giữ: đã book hoặc đang bị user khác hold.
     */
    public List<String> findBlockingSeatCodes(String showtimeId, List<String> seatIds, String userId) {
        if (seatIds == null || seatIds.isEmpty()) {
            return List.of();
        }

        String inClause = seatIds.stream().map(id -> "?").collect(Collectors.joining(", "));
        String sql = """
                SELECT s.seat_code
                FROM Seats s
                JOIN Showtimes sh ON sh.room_id = s.room_id AND sh.id = ?
                WHERE s.id IN (%s)
                  AND s.status = 'ACTIVE'
                  AND (
                      EXISTS (
                          SELECT 1 FROM BookingSeats bs
                          JOIN Bookings b ON b.id = bs.booking_id
                          WHERE bs.seat_id = s.id
                            AND b.showtime_id = sh.id
                            AND b.booking_status IN ('PENDING', 'CONFIRMED')
                      )
                      OR EXISTS (
                          SELECT 1 FROM SeatHolds h
                          WHERE h.showtime_id = sh.id
                            AND h.seat_id = s.id
                            AND h.expired_at > GETDATE()
                            AND (h.user_id IS NULL OR h.user_id <> ?)
                      )
                  )
                ORDER BY s.seat_code
                """.formatted(inClause);

        List<String> blocked = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int i = 1;
            ps.setString(i++, showtimeId);
            for (String seatId : seatIds) {
                ps.setString(i++, seatId);
            }
            ps.setString(i, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) blocked.add(rs.getString("seat_code"));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findBlockingSeatCodes failed", e);
        }
        return blocked;
    }

    /** Số ghế hợp lệ thuộc phòng của suất chiếu. */
    public int countValidSeatsForShowtime(String showtimeId, List<String> seatIds) {
        if (seatIds == null || seatIds.isEmpty()) return 0;

        String inClause = seatIds.stream().map(id -> "?").collect(Collectors.joining(", "));
        String sql = """
                SELECT COUNT(*) AS cnt
                FROM Seats s
                JOIN Showtimes sh ON sh.room_id = s.room_id AND sh.id = ?
                WHERE s.id IN (%s) AND s.status = 'ACTIVE'
                """.formatted(inClause);

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int i = 1;
            ps.setString(i++, showtimeId);
            for (String seatId : seatIds) {
                ps.setString(i++, seatId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getInt("cnt");
            }
        } catch (SQLException e) {
            throw new RuntimeException("countValidSeatsForShowtime failed", e);
        }
        return 0;
    }

    /**
     * Đồng bộ danh sách ghế đang giữ: rỗng → xóa hold; có ghế → thay batch hold 10 phút.
     *
     * @return expired_at mới, hoặc null nếu không còn ghế nào được giữ
     */
    public Timestamp syncHolds(String showtimeId, String userId, List<String> seatIds) {
        if (seatIds == null || seatIds.isEmpty()) {
            releaseHolds(showtimeId, userId);
            return null;
        }
        return holdSeats(showtimeId, userId, seatIds);
    }

    /** Xóa toàn bộ SeatHolds của user trên suất chiếu. */
    public void releaseHolds(String showtimeId, String userId) {
        String sql = "DELETE FROM SeatHolds WHERE showtime_id = ? AND user_id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtimeId);
            ps.setString(2, userId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("releaseHolds failed", e);
        }
    }

    /**
     * Thay thế hold cũ của user trên suất này và tạo hold mới (10 phút).
     *
     * @return expired_at của batch hold vừa tạo
     */
    public Timestamp holdSeats(String showtimeId, String userId, List<String> seatIds) {
        if (seatIds == null || seatIds.isEmpty()) {
            throw new IllegalArgumentException("seatIds must not be empty");
        }

        List<String> blocked = findBlockingSeatCodes(showtimeId, seatIds, userId);
        if (!blocked.isEmpty()) {
            throw new SeatHoldException("Ghế không còn trống: " + String.join(", ", blocked));
        }

        if (countValidSeatsForShowtime(showtimeId, seatIds) != seatIds.size()) {
            throw new SeatHoldException("Danh sách ghế không hợp lệ cho suất chiếu này.");
        }

        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);
            deleteExpiredHolds(conn);

            String deleteSql = "DELETE FROM SeatHolds WHERE showtime_id = ? AND user_id = ?";
            try (PreparedStatement ps = conn.prepareStatement(deleteSql)) {
                ps.setString(1, showtimeId);
                ps.setString(2, userId);
                ps.executeUpdate();
            }

            Timestamp expiredAt = computeExpiry(conn);
            String insertSql = """
                    INSERT INTO SeatHolds (showtime_id, seat_id, user_id, expired_at)
                    VALUES (?, ?, ?, ?)
                    """;

            try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
                for (String seatId : seatIds) {
                    ps.setString(1, showtimeId);
                    ps.setString(2, seatId);
                    ps.setString(3, userId);
                    ps.setTimestamp(4, expiredAt);
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            conn.commit();
            return expiredAt;

        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            if (isUniqueViolation(e)) {
                throw new SeatHoldException("Một hoặc nhiều ghế vừa bị người khác chọn. Vui lòng chọn lại.");
            }
            throw new RuntimeException("holdSeats failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    public Optional<Timestamp> getActiveHoldExpiry(String showtimeId, String userId) {
        String sql = """
                SELECT MAX(expired_at) AS max_expiry
                FROM SeatHolds
                WHERE showtime_id = ?
                  AND user_id = ?
                  AND expired_at > GETDATE()
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtimeId);
            ps.setString(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Timestamp ts = rs.getTimestamp("max_expiry");
                    if (ts != null) return Optional.of(ts);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("getActiveHoldExpiry failed", e);
        }
        return Optional.empty();
    }

    public List<String> getHeldSeatIds(String showtimeId, String userId) {
        String sql = """
                SELECT seat_id
                FROM SeatHolds
                WHERE showtime_id = ?
                  AND user_id = ?
                  AND expired_at > GETDATE()
                ORDER BY created_at
                """;
        List<String> ids = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtimeId);
            ps.setString(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getString("seat_id"));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getHeldSeatIds failed", e);
        }
        return ids;
    }

    public void deleteExpiredHolds() {
        try (Connection conn = DBContext.getConnection()) {
            deleteExpiredHolds(conn);
        } catch (SQLException e) {
            throw new RuntimeException("deleteExpiredHolds failed", e);
        }
    }

    private void deleteExpiredHolds(Connection conn) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "DELETE FROM SeatHolds WHERE expired_at <= GETDATE()")) {
            ps.executeUpdate();
        }
    }

    private Timestamp computeExpiry(Connection conn) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT DATEADD(MINUTE, ?, GETDATE()) AS expiry")) {
            ps.setInt(1, HOLD_MINUTES);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getTimestamp("expiry");
            }
        }
        throw new SQLException("Could not compute hold expiry");
    }

    private boolean isUniqueViolation(SQLException e) {
        int code = e.getErrorCode();
        return code == 2627 || code == 2601;
    }

    /** Loại bỏ trùng lặp, giữ thứ tự. */
    public static List<String> distinctSeatIds(List<String> seatIds) {
        if (seatIds == null) return List.of();
        return new ArrayList<>(new LinkedHashSet<>(seatIds));
    }
}
