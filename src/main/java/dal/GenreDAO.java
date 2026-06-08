package dal;

import model.entity.Genre;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

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

    /** Thể loại đang được gắn với ít nhất một phim (mọi trạng thái). */
    public boolean hasLinkedMovies(String genreId) {
        String sql = """
                SELECT COUNT(1)
                FROM MovieGenres mg
                INNER JOIN Movies m ON m.id = mg.movie_id
                WHERE mg.genre_id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, genreId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.hasLinkedMovies failed", e);
        }
    }

    public Set<String> getGenreIdsInUse() {
        String sql = "SELECT DISTINCT genre_id FROM MovieGenres";
        Set<String> ids = new HashSet<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) ids.add(rs.getString("genre_id"));
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.getGenreIdsInUse failed", e);
        }
        return ids;
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

    public void delete(String id) {
        String sql = "DELETE FROM Genres WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.delete failed", e);
        }
    }
}
