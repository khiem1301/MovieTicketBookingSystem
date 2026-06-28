package dal;

import model.entity.SeatType;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class SeatTypeDAO {

    private SeatType mapRow(ResultSet rs) throws SQLException {
        SeatType st = new SeatType();
        st.setId(rs.getString("id"));
        st.setTypeName(rs.getString("type_name"));
        st.setPriceMultiplier(rs.getBigDecimal("price_multiplier"));
        st.setDescription(rs.getString("description"));
        st.setSeatSpan(rs.getInt("seat_span"));
        return st;
    }

    public List<SeatType> getAll() {
        String sql = """
                SELECT id, type_name, price_multiplier, description, seat_span
                FROM SeatTypes
                ORDER BY price_multiplier, type_name
                """;
        List<SeatType> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.getAll failed", e);
        }
        return list;
    }

    public SeatType getById(String id) {
        String sql = """
                SELECT id, type_name, price_multiplier, description, seat_span
                FROM SeatTypes WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.getById failed", e);
        }
        return null;
    }

    /** Map lowercase type key → id (regular → REGULAR id). */
    public Map<String, String> getTypeKeyToIdMap() {
        Map<String, String> map = new HashMap<>();
        for (SeatType st : getAll()) {
            map.put(st.getTypeName().trim().toLowerCase(), st.getId());
        }
        return map;
    }

    public boolean isDuplicate(String typeName) {
        String sql = "SELECT COUNT(1) FROM SeatTypes WHERE LOWER(type_name) = LOWER(?)";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, typeName.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.isDuplicate failed", e);
        }
    }

    public boolean isDuplicateExcluding(String typeName, String excludeId) {
        String sql = "SELECT COUNT(1) FROM SeatTypes WHERE LOWER(type_name) = LOWER(?) AND id <> ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, typeName.trim());
            ps.setString(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.isDuplicateExcluding failed", e);
        }
    }

    public void create(String typeName, BigDecimal multiplier, String description, int seatSpan) {
        String sql = """
                INSERT INTO SeatTypes (id, type_name, price_multiplier, description, seat_span)
                VALUES (NEWID(), ?, ?, ?, ?)
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, typeName.trim().toUpperCase());
            ps.setBigDecimal(2, multiplier);
            ps.setString(3, description != null && !description.isBlank() ? description.trim() : null);
            ps.setInt(4, seatSpan);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.create failed", e);
        }
    }

    public void update(String id, String typeName, BigDecimal multiplier, String description, int seatSpan) {
        String sql = """
                UPDATE SeatTypes
                SET type_name = ?, price_multiplier = ?, description = ?, seat_span = ?
                WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, typeName.trim().toUpperCase());
            ps.setBigDecimal(2, multiplier);
            ps.setString(3, description != null && !description.isBlank() ? description.trim() : null);
            ps.setInt(4, seatSpan);
            ps.setString(5, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.update failed", e);
        }
    }

    public int countUsedIn(String seatTypeId) {
        String sql = "SELECT COUNT(1) FROM Seats WHERE seat_type_id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, seatTypeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.countUsedIn failed", e);
        }
    }

    public void delete(String id) {
        if (countUsedIn(id) > 0) {
            throw new IllegalStateException("Loại ghế đang được sử dụng bởi ghế trong layout, không thể xóa.");
        }
        String sql = "DELETE FROM SeatTypes WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("SeatTypeDAO.delete failed", e);
        }
    }
}
