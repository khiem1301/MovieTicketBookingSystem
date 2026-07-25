package dal;

import model.entity.CinemaRoom;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

public class CinemaRoomDAO {

    private CinemaRoom mapRow(ResultSet rs) throws SQLException {
        CinemaRoom r = new CinemaRoom();
        r.setId(rs.getString("id"));
        r.setRoomName(rs.getString("room_name"));
        r.setCapacity(rs.getInt("capacity"));
        r.setStatus(rs.getString("status"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        return r;
    }

    public List<CinemaRoom> getAll() {
        String sql = """
                SELECT id, room_name, capacity, status, created_at
                FROM CinemaRooms
                ORDER BY room_name
                """;
        List<CinemaRoom> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.getAll failed", e);
        }
        return list;
    }

    /** Đếm phòng theo trạng thái (null/blank/ALL = tất cả). */
    public int countByStatus(String status) {
        String normalized = normalizeStatusFilter(status);
        StringBuilder sql = new StringBuilder(
                "SELECT COUNT(1) FROM CinemaRooms");
        if (normalized != null) {
            sql.append(" WHERE status = ?");
        }
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            if (normalized != null) {
                ps.setString(1, normalized);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.countByStatus failed", e);
        }
    }

    /** Danh sách phòng phân trang, sắp xếp theo tên. */
    public List<CinemaRoom> findPaged(String status, int offset, int limit) {
        String normalized = normalizeStatusFilter(status);
        StringBuilder sql = new StringBuilder("""
                SELECT id, room_name, capacity, status, created_at
                FROM CinemaRooms
                """);
        if (normalized != null) {
            sql.append(" WHERE status = ?");
        }
        sql.append(" ORDER BY room_name OFFSET ? ROWS FETCH NEXT ? ROWS ONLY");

        List<CinemaRoom> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            int i = 1;
            if (normalized != null) {
                ps.setString(i++, normalized);
            }
            ps.setInt(i++, Math.max(0, offset));
            ps.setInt(i, Math.max(1, limit));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) list.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.findPaged failed", e);
        }
        return list;
    }

    private static String normalizeStatusFilter(String status) {
        if (status == null || status.isBlank() || "ALL".equalsIgnoreCase(status.trim())) {
            return null;
        }
        String s = status.trim().toUpperCase();
        if ("ACTIVE".equals(s) || "INACTIVE".equals(s)) {
            return s;
        }
        return null;
    }

    /** FR-25 — Phòng đang hoạt động, có ghế, có thể xếp suất chiếu. */
    public List<CinemaRoom> getActiveRooms() {
        String sql = """
                SELECT id, room_name, capacity, status, created_at
                FROM CinemaRooms
                WHERE status = 'ACTIVE'
                  AND capacity > 0
                ORDER BY room_name
                """;
        List<CinemaRoom> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.getActiveRooms failed", e);
        }
        return list;
    }

    public CinemaRoom getById(String id) {
        String sql = """
                SELECT id, room_name, capacity, status, created_at
                FROM CinemaRooms WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.getById failed", e);
        }
        return null;
    }

    public String create(String roomName) {
        String sql = """
                INSERT INTO CinemaRooms (id, room_name, capacity, status)
                OUTPUT INSERTED.id
                VALUES (NEWID(), ?, 0, 'ACTIVE')
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomName.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString(1);
            }
            throw new RuntimeException("CinemaRoomDAO.create failed: no id returned");
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.create failed", e);
        }
    }

    /** Tạo phòng trong transaction đang mở — trả về id. */
    public String create(Connection conn, String roomName) throws SQLException {
        String sql = """
                INSERT INTO CinemaRooms (id, room_name, capacity, status)
                OUTPUT INSERTED.id
                VALUES (NEWID(), ?, 0, 'ACTIVE')
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomName.trim());
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return rs.getString(1);
            }
        }
        throw new SQLException("CinemaRoomDAO.create(conn) failed: no id returned");
    }

    /**
     * Phòng tạo nhầm — chỉ xóa được khi chưa từng gắn suất chiếu
     * và ghế phòng chưa từng bị giữ chỗ / đặt vé.
     */
    public boolean isMistakenRoomDeletable(String roomId) {
        return countShowtimes(roomId) == 0
                && countSeatHoldsForRoom(roomId) == 0
                && countBookingSeatsForRoom(roomId) == 0;
    }

    /** Id các phòng đủ điều kiện xóa (tạo nhầm). */
    public Set<String> findMistakenDeletableIds() {
        String sql = """
                SELECT cr.id
                FROM CinemaRooms cr
                WHERE NOT EXISTS (
                          SELECT 1 FROM Showtimes s WHERE s.room_id = cr.id
                      )
                  AND NOT EXISTS (
                          SELECT 1
                          FROM SeatHolds sh
                          INNER JOIN Seats se ON se.id = sh.seat_id
                          WHERE se.room_id = cr.id
                      )
                  AND NOT EXISTS (
                          SELECT 1
                          FROM BookingSeats bs
                          INNER JOIN Seats se ON se.id = bs.seat_id
                          WHERE se.room_id = cr.id
                      )
                """;
        Set<String> ids = new HashSet<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) ids.add(rs.getString(1));
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.findMistakenDeletableIds failed", e);
        }
        return ids;
    }

    public int countShowtimes(String roomId) {
        String sql = "SELECT COUNT(1) FROM Showtimes WHERE room_id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.countShowtimes failed", e);
        }
    }

    public int countSeatHoldsForRoom(String roomId) {
        String sql = """
                SELECT COUNT(1)
                FROM SeatHolds sh
                INNER JOIN Seats se ON se.id = sh.seat_id
                WHERE se.room_id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.countSeatHoldsForRoom failed", e);
        }
    }

    public int countBookingSeatsForRoom(String roomId) {
        String sql = """
                SELECT COUNT(1)
                FROM BookingSeats bs
                INNER JOIN Seats se ON se.id = bs.seat_id
                WHERE se.room_id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.countBookingSeatsForRoom failed", e);
        }
    }

    /**
     * Xóa phòng tạo nhầm (ghế trước, rồi phòng).
     * @throws IllegalStateException nếu phòng đã có suất chiếu / giữ chỗ / đặt vé
     */
    public void deleteMistakenRoom(String id) {
        if (!isMistakenRoomDeletable(id)) {
            throw new IllegalStateException(
                    "Chỉ xóa được phòng tạo nhầm — phòng này đã có suất chiếu hoặc dữ liệu đặt ghế.");
        }
        delete(id);
    }

    /** Xóa ghế rồi phòng (không kiểm tra nghiệp vụ — dùng sau khi đã validate). */
    public void delete(String id) {
        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM Seats WHERE room_id = ?")) {
                    ps.setString(1, id);
                    ps.executeUpdate();
                }
                try (PreparedStatement ps = conn.prepareStatement("DELETE FROM CinemaRooms WHERE id = ?")) {
                    ps.setString(1, id);
                    ps.executeUpdate();
                }
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.delete failed", e);
        }
    }

    public void updateName(String id, String roomName) {
        String sql = "UPDATE CinemaRooms SET room_name = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomName.trim());
            ps.setString(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.updateName failed", e);
        }
    }

    public void updateStatus(String id, String status) {
        String sql = "UPDATE CinemaRooms SET status = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.updateStatus failed", e);
        }
    }

    public boolean existsByName(String name) {
        String sql = "SELECT COUNT(1) FROM CinemaRooms WHERE room_name = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.existsByName failed", e);
        }
    }

    public boolean existsByNameExcluding(String name, String excludeId) {
        String sql = "SELECT COUNT(1) FROM CinemaRooms WHERE room_name = ? AND id <> ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name.trim());
            ps.setString(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.existsByNameExcluding failed", e);
        }
    }

    public int countUpcomingShowtimes(String roomId) {
        String sql = """
                SELECT COUNT(1) FROM Showtimes
                WHERE room_id = ?
                  AND start_time > GETDATE()
                  AND status IN ('SCHEDULED', 'SHOWING')
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("CinemaRoomDAO.countUpcomingShowtimes failed", e);
        }
    }

    /** Số ghế ACTIVE trong phòng. */
    public int countActiveSeats(String roomId) {
        String sql = "SELECT COUNT(1) FROM Seats WHERE room_id = ? AND status = 'ACTIVE'";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            return 0;
        }
    }

    /** Số ghế accessibility (ACTIVE) trong phòng — dùng cho panel chi tiết. */
    public int countAccessibleSeats(String roomId) {
        String sql = """
                SELECT COUNT(1)
                FROM Seats
                WHERE room_id = ?
                  AND status = 'ACTIVE'
                  AND seat_type_id IN (
                      SELECT id FROM SeatTypes WHERE type_name IN ('WHEELCHAIR', 'ACCESSIBLE')
                  )
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            return 0;
        }
    }
}
