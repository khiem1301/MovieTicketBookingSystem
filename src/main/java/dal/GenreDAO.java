package dal;

import model.entity.Genre;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class GenreDAO {

    private Genre mapRow(ResultSet rs) throws SQLException {
        Genre g = new Genre();
        g.setId(rs.getString("id"));
        g.setGenreName(rs.getString("genre_name"));
        g.setCreatedAt(rs.getTimestamp("created_at"));
        return g;
    }

    public List<Genre> getAll() {
        String sql = "SELECT id, genre_name, created_at FROM Genres ORDER BY genre_name";
        List<Genre> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.getAll failed", e);
        }
        return list;
    }

    public Genre getById(String id) {
        String sql = "SELECT id, genre_name, created_at FROM Genres WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRow(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.getById failed", e);
        }
        return null;
    }

    public boolean isDuplicate(String name) {
        String sql = "SELECT COUNT(1) FROM Genres WHERE genre_name = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.isDuplicate failed", e);
        }
    }

    public boolean isDuplicateExcluding(String name, String excludeId) {
        String sql = "SELECT COUNT(1) FROM Genres WHERE genre_name = ? AND id <> ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, name.trim());
            ps.setString(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.isDuplicateExcluding failed", e);
        }
    }

    public void create(String genreName) {
        String sql = "INSERT INTO Genres (id, genre_name) VALUES (NEWID(), ?)";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, genreName.trim());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.create failed", e);
        }
    }

    public void update(String id, String genreName) {
        String sql = "UPDATE Genres SET genre_name = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, genreName.trim());
            ps.setString(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.update failed", e);
        }
    }
}
