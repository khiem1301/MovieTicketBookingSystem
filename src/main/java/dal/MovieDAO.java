package dal;

import model.entity.Genre;
import model.entity.Movie;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public class MovieDAO {

    /** Phim COMING_SOON có suất chiếu OPEN/SCHEDULED trước ngày công chiếu. */
    private static final String HAS_EARLY_SHOWTIME = """
            EXISTS (
                SELECT 1 FROM Showtimes st
                WHERE st.movie_id = m.id
                  AND st.status IN ('SCHEDULED', 'OPEN')
                  AND st.start_time > SYSDATETIME()
                  AND m.release_date IS NOT NULL
                  AND CAST(st.start_time AS DATE) < m.release_date
            )
            """;

    private static final String MOVIE_COLS = """
            id, title, slug, description, duration_minutes, release_date,
            trailer_url, poster_url, backdrop_url, director,
            language, subtitle, age_rating, status, average_rating, created_at
            """;

    // Hero slider + featured section: lấy phim nổi bật theo rating
    public List<Movie> getFeaturedMovies(int limit) {
        String sql = """
                SELECT TOP (?) m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names
                FROM Movies m
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                WHERE m.status IN ('NOW_SHOWING', 'COMING_SOON')
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY m.average_rating DESC, m.created_at DESC
                """;
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getFeaturedMovies failed", e);
        }
        return result;
    }

    // Movie grid theo tab: NOW_SHOWING | COMING_SOON (không gồm phim suất chiếu sớm)
    public List<Movie> getMoviesByStatus(String status, int limit) {
        String comingSoonFilter = "COMING_SOON".equals(status)
                ? " AND NOT (" + HAS_EARLY_SHOWTIME + ")"
                : "";
        String sql = """
                SELECT TOP (?) m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names
                FROM Movies m
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                WHERE m.status = ?
                """ + comingSoonFilter + """
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY m.average_rating DESC, m.created_at DESC
                """;
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setString(2, status);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getMoviesByStatus failed", e);
        }
        return result;
    }

    // Trang /movies: lọc theo trạng thái, thể loại, từ khóa
    public List<Movie> searchPublicMovies(String status, String genreId, String keyword) {
        StringBuilder sql = new StringBuilder("""
                SELECT m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names
                FROM Movies m
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                WHERE m.status = ?
                """);
        List<Object> params = new ArrayList<>();
        params.add(status);

        if ("COMING_SOON".equals(status)) {
            sql.append(" AND NOT (").append(HAS_EARLY_SHOWTIME).append(")");
        }

        if (genreId != null && !genreId.isBlank()) {
            sql.append("""
                     AND EXISTS (
                         SELECT 1 FROM MovieGenres mg2
                         WHERE mg2.movie_id = m.id AND mg2.genre_id = ?
                     )
                    """);
            params.add(genreId.trim());
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND m.title LIKE ?");
            params.add("%" + keyword.trim() + "%");
        }

        sql.append("""
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY m.average_rating DESC, m.created_at DESC
                """);

        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("searchPublicMovies failed", e);
        }
        return result;
    }

    // Suất chiếu sớm: chỉ phim có lịch chiếu thật trước ngày công chiếu
    public List<Movie> getEarlyShowtimeMovies(int limit) {
        String sql = """
                SELECT TOP (?) m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names
                FROM Movies m
                INNER JOIN Showtimes st ON st.movie_id = m.id
                    AND st.status IN ('SCHEDULED', 'OPEN')
                    AND st.start_time > SYSDATETIME()
                    AND m.release_date IS NOT NULL
                    AND CAST(st.start_time AS DATE) < m.release_date
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                WHERE m.status = 'COMING_SOON'
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY MIN(st.start_time) ASC, m.created_at DESC
                """;
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getEarlyShowtimeMovies failed", e);
        }
        return result;
    }

    public List<Movie> searchEarlyShowtimeMovies(String genreId, String keyword) {
        StringBuilder sql = new StringBuilder("""
                SELECT m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names
                FROM Movies m
                INNER JOIN Showtimes st ON st.movie_id = m.id
                    AND st.status IN ('SCHEDULED', 'OPEN')
                    AND st.start_time > SYSDATETIME()
                    AND m.release_date IS NOT NULL
                    AND CAST(st.start_time AS DATE) < m.release_date
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                WHERE m.status = 'COMING_SOON'
                """);
        List<Object> params = new ArrayList<>();

        if (genreId != null && !genreId.isBlank()) {
            sql.append("""
                     AND EXISTS (
                         SELECT 1 FROM MovieGenres mg2
                         WHERE mg2.movie_id = m.id AND mg2.genre_id = ?
                     )
                    """);
            params.add(genreId.trim());
        }
        if (keyword != null && !keyword.isBlank()) {
            sql.append(" AND m.title LIKE ?");
            params.add("%" + keyword.trim() + "%");
        }

        sql.append("""
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY MIN(st.start_time) ASC, m.created_at DESC
                """);

        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, params.get(i));
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("searchEarlyShowtimeMovies failed", e);
        }
        return result;
    }

    // Manager: danh sách tất cả phim
    public List<Movie> getAllForManager() {
        String sql = "SELECT " + MOVIE_COLS + " FROM Movies ORDER BY created_at DESC";
        List<Movie> list = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRowFull(rs));
        } catch (SQLException e) {
            throw new RuntimeException("getAllForManager failed", e);
        }
        return list;
    }

    public Movie getById(String id) {
        String sql = "SELECT " + MOVIE_COLS + " FROM Movies WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapRowFull(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("getById failed", e);
        }
        return null;
    }

    public List<String> getGenreIds(String movieId) {
        String sql = "SELECT genre_id FROM MovieGenres WHERE movie_id = ?";
        List<String> ids = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, movieId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getString("genre_id"));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getGenreIds failed", e);
        }
        return ids;
    }

    public boolean isDuplicateTitle(String title) {
        String sql = "SELECT COUNT(1) FROM Movies WHERE title = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("isDuplicateTitle failed", e);
        }
    }

    public boolean isDuplicateSlug(String slug) {
        String sql = "SELECT COUNT(1) FROM Movies WHERE slug = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, slug.trim());
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("isDuplicateSlug failed", e);
        }
    }

    public boolean isDuplicateTitleExcluding(String title, String excludeId) {
        String sql = "SELECT COUNT(1) FROM Movies WHERE title = ? AND id <> ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, title.trim());
            ps.setString(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("isDuplicateTitleExcluding failed", e);
        }
    }

    public boolean isDuplicateSlugExcluding(String slug, String excludeId) {
        String sql = "SELECT COUNT(1) FROM Movies WHERE slug = ? AND id <> ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, slug.trim());
            ps.setString(2, excludeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("isDuplicateSlugExcluding failed", e);
        }
    }

    public void create(Movie movie, List<String> genreIds) {
        String id = UUID.randomUUID().toString();
        movie.setId(id);
        String sql = """
                INSERT INTO Movies (
                    id, title, slug, description, duration_minutes, release_date,
                    trailer_url, poster_url, backdrop_url, director,
                    language, subtitle, age_rating, status
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                insertMovie(conn, sql, movie);
                replaceGenres(conn, id, genreIds);
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("create failed", e);
        }
    }

    public void update(Movie movie, List<String> genreIds) {
        String sql = """
                UPDATE Movies SET
                    title = ?, slug = ?, description = ?, duration_minutes = ?,
                    release_date = ?, trailer_url = ?, poster_url = ?, backdrop_url = ?,
                    director = ?, language = ?, subtitle = ?,
                    age_rating = ?, status = ?
                WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try {
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    bindMovieFields(ps, movie, 1);
                    ps.setString(14, movie.getId());
                    ps.executeUpdate();
                }
                replaceGenres(conn, movie.getId(), genreIds);
                conn.commit();
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("update failed", e);
        }
    }

    // Dropdown thể loại trong header
    public List<Genre> getAllGenres() {
        return new GenreDAO().getAll();
    }

    private void insertMovie(Connection conn, String sql, Movie m) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, m.getId());
            bindMovieFields(ps, m, 2);
            ps.executeUpdate();
        }
    }

    private void bindMovieFields(PreparedStatement ps, Movie m, int start) throws SQLException {
        int i = start;
        ps.setString(i++, m.getTitle().trim());
        ps.setString(i++, m.getSlug().trim());
        ps.setString(i++, emptyToNull(m.getDescription()));
        ps.setInt(i++, m.getDurationMinutes());
        ps.setDate(i++, m.getReleaseDate());
        ps.setString(i++, emptyToNull(m.getTrailerUrl()));
        ps.setString(i++, emptyToNull(m.getPosterUrl()));
        ps.setString(i++, emptyToNull(m.getBackdropUrl()));
        ps.setString(i++, emptyToNull(m.getDirector()));
        ps.setString(i++, emptyToNull(m.getLanguage()));
        ps.setString(i++, emptyToNull(m.getSubtitle()));
        ps.setString(i++, emptyToNull(m.getAgeRating()));
        ps.setString(i, m.getStatus());
    }

    private void replaceGenres(Connection conn, String movieId, List<String> genreIds)
            throws SQLException {
        try (PreparedStatement del = conn.prepareStatement(
                "DELETE FROM MovieGenres WHERE movie_id = ?")) {
            del.setString(1, movieId);
            del.executeUpdate();
        }
        if (genreIds == null || genreIds.isEmpty()) return;
        try (PreparedStatement ins = conn.prepareStatement(
                "INSERT INTO MovieGenres (movie_id, genre_id) VALUES (?, ?)")) {
            for (String genreId : genreIds) {
                if (genreId == null || genreId.isBlank()) continue;
                ins.setString(1, movieId);
                ins.setString(2, genreId.trim());
                ins.addBatch();
            }
            ins.executeBatch();
        }
    }

    private String emptyToNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }

    private Movie mapRow(ResultSet rs) throws SQLException {
        Movie m = mapRowListing(rs);
        String genreNames = rs.getString("genre_names");
        if (genreNames != null && !genreNames.isBlank()) {
            m.setGenres(Arrays.asList(genreNames.split(",")));
        } else {
            m.setGenres(new ArrayList<>());
        }
        return m;
    }

    /** Cột dùng cho trang chủ — không gồm language, subtitle. */
    private Movie mapRowListing(ResultSet rs) throws SQLException {
        Movie m = new Movie();
        m.setId(rs.getString("id"));
        m.setTitle(rs.getString("title"));
        m.setSlug(rs.getString("slug"));
        m.setDescription(rs.getString("description"));
        m.setDurationMinutes(rs.getInt("duration_minutes"));
        m.setReleaseDate(rs.getDate("release_date"));
        m.setTrailerUrl(rs.getString("trailer_url"));
        m.setPosterUrl(rs.getString("poster_url"));
        m.setBackdropUrl(rs.getString("backdrop_url"));
        m.setDirector(rs.getString("director"));
        m.setAgeRating(rs.getString("age_rating"));
        m.setStatus(rs.getString("status"));
        BigDecimal rating = rs.getBigDecimal("average_rating");
        m.setAverageRating(rating != null ? rating : BigDecimal.ZERO);
        m.setCreatedAt(rs.getTimestamp("created_at"));
        m.setGenres(new ArrayList<>());
        return m;
    }

    private Movie mapRowFull(ResultSet rs) throws SQLException {
        Movie m = new Movie();
        m.setId(rs.getString("id"));
        m.setTitle(rs.getString("title"));
        m.setSlug(rs.getString("slug"));
        m.setDescription(rs.getString("description"));
        m.setDurationMinutes(rs.getInt("duration_minutes"));
        m.setReleaseDate(rs.getDate("release_date"));
        m.setTrailerUrl(rs.getString("trailer_url"));
        m.setPosterUrl(rs.getString("poster_url"));
        m.setBackdropUrl(rs.getString("backdrop_url"));
        m.setDirector(rs.getString("director"));
        m.setLanguage(rs.getString("language"));
        m.setSubtitle(rs.getString("subtitle"));
        m.setAgeRating(rs.getString("age_rating"));
        m.setStatus(rs.getString("status"));
        BigDecimal rating = rs.getBigDecimal("average_rating");
        m.setAverageRating(rating != null ? rating : BigDecimal.ZERO);
        m.setCreatedAt(rs.getTimestamp("created_at"));
        m.setGenres(new ArrayList<>());
        return m;
    }
}
