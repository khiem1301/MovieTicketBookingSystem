package dal;

import model.entity.Genre;

import java.sql.*;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

public class GenreDAO {

    private Genre mapRow(ResultSet rs) throws SQLException {
        Genre g = new Genre();
        g.setId(rs.getString("id"));
        g.setGenreName(rs.getString("genre_name"));
        g.setDescription(rs.getString("description"));
        g.setActive(rs.getBoolean("is_active"));
        g.setCreatedAt(rs.getTimestamp("created_at"));
        return g;
    }

    public List<Genre> getAll() {
        String sql = "SELECT id, genre_name, description, is_active, created_at FROM Genres ORDER BY genre_name";
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

    public List<Genre> getAllActive() {
        String sql = "SELECT id, genre_name, description, is_active, created_at FROM Genres WHERE is_active = 1 ORDER BY genre_name";
        List<Genre> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.getAllActive failed", e);
        }
        return list;
    }

    public Genre getById(String id) {
        String sql = "SELECT id, genre_name, description, is_active, created_at FROM Genres WHERE id = ?";
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

    public void create(String genreName, String description, boolean isActive) {
        String sql = "INSERT INTO Genres (id, genre_name, description, is_active) VALUES (NEWID(), ?, ?, ?)";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, genreName.trim());
            ps.setString(2, (description != null && !description.trim().isEmpty()) ? description.trim() : null);
            ps.setBoolean(3, isActive);
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

    /** Thể loại có phim đang chiếu (NOW_SHOWING), suất chiếu sớm (EARLY_SHOWING) hoặc sắp chiếu (COMING_SOON). */
    public boolean hasActiveOrUpcomingMovies(String genreId) {
        String sql = """
                SELECT COUNT(1)
                FROM MovieGenres mg
                INNER JOIN Movies m ON m.id = mg.movie_id
                WHERE mg.genre_id = ?
                  AND m.status IN ('NOW_SHOWING', 'EARLY_SHOWING', 'COMING_SOON')
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, genreId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.hasActiveOrUpcomingMovies failed", e);
        }
    }

    public Map<String, Integer> getMovieCountPerGenre() {
        String sql = "SELECT genre_id, COUNT(movie_id) AS cnt FROM MovieGenres GROUP BY genre_id";
        Map<String, Integer> map = new HashMap<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                map.put(rs.getString("genre_id"), rs.getInt("cnt"));
            }
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.getMovieCountPerGenre failed", e);
        }
        return map;
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

    /** Trả về tập ID thể loại có ít nhất một phim đang chiếu, suất chiếu sớm hoặc sắp chiếu. */
    public Set<String> getGenreIdsWithActiveMovies() {
        String sql = """
                SELECT DISTINCT mg.genre_id
                FROM MovieGenres mg
                INNER JOIN Movies m ON m.id = mg.movie_id
                WHERE m.status IN ('NOW_SHOWING', 'EARLY_SHOWING', 'COMING_SOON')
                """;
        Set<String> ids = new HashSet<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) ids.add(rs.getString("genre_id"));
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.getGenreIdsWithActiveMovies failed", e);
        }
        return ids;
    }

    public void update(String id, String genreName, String description) {
        String sql = "UPDATE Genres SET genre_name = ?, description = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, genreName.trim());
            ps.setString(2, (description != null && !description.trim().isEmpty()) ? description.trim() : null);
            ps.setString(3, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.update failed", e);
        }
    }

    public void updateStatus(String id, boolean isActive) {
        String sql = "UPDATE Genres SET is_active = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBoolean(1, isActive);
            ps.setString(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("GenreDAO.updateStatus failed", e);
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
