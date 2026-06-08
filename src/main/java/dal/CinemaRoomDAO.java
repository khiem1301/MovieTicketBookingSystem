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
