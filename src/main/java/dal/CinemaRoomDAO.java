package dal;

import model.entity.CinemaRoom;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

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

    /** FR-25 — Phòng đang hoạt động, có thể xếp suất chiếu. */
    public List<CinemaRoom> getActiveRooms() {
        String sql = """
                SELECT id, room_name, capacity, status, created_at
                FROM CinemaRooms
                WHERE status = 'ACTIVE'
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
                  AND status IN ('SCHEDULED', 'OPEN', 'SOLD_OUT')
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
