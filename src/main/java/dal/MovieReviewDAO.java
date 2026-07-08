package dal;

import model.entity.Movie;
import model.entity.MovieReview;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;

/** FR-20 — Đánh giá phim (1–5 sao + nhận xét), mỗi user chỉ review 1 lần / 1 phim. */
public class MovieReviewDAO {

    private static final String MOVIE_JOIN_COLS = """
            r.id, r.movie_id, r.user_id, r.rating, r.review_content, r.created_at,
            m.title AS movie_title, m.slug AS movie_slug, m.poster_url AS movie_poster_url,
            u.full_name AS user_full_name, u.avatar_url AS user_avatar_url
            """;

    public Optional<MovieReview> findByMovieAndUser(String movieId, String userId) {
        String sql = "SELECT id, movie_id, user_id, rating, review_content, created_at " +
                     "FROM MovieReviews WHERE movie_id = ? AND user_id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, movieId);
            ps.setString(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? Optional.of(mapPlain(rs)) : Optional.empty();
            }
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.findByMovieAndUser failed", e);
        }
    }

    /** Tạo mới hoặc cập nhật đánh giá của user cho phim, rồi tính lại average_rating. */
    public void upsert(String movieId, String userId, int rating, String content) {
        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            String existingId = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT id FROM MovieReviews WHERE movie_id = ? AND user_id = ?")) {
                ps.setString(1, movieId);
                ps.setString(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) existingId = rs.getString("id");
                }
            }

            if (existingId != null) {
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE MovieReviews SET rating = ?, review_content = ?, created_at = GETDATE() WHERE id = ?")) {
                    ps.setInt(1, rating);
                    setNullableString(ps, 2, content);
                    ps.setString(3, existingId);
                    ps.executeUpdate();
                }
            } else {
                try (PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO MovieReviews (movie_id, user_id, rating, review_content) VALUES (?,?,?,?)")) {
                    ps.setString(1, movieId);
                    ps.setString(2, userId);
                    ps.setInt(3, rating);
                    setNullableString(ps, 4, content);
                    ps.executeUpdate();
                }
            }

            try (PreparedStatement ps = conn.prepareStatement("""
                    UPDATE Movies
                    SET average_rating = (
                        SELECT AVG(CAST(rating AS DECIMAL(10,2))) FROM MovieReviews WHERE movie_id = ?
                    )
                    WHERE id = ?
                    """)) {
                ps.setString(1, movieId);
                ps.setString(2, movieId);
                ps.executeUpdate();
            }

            conn.commit();
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            throw new RuntimeException("MovieReviewDAO.upsert failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    /** Xóa đánh giá của chính user đó, rồi tính lại average_rating. @return false nếu không có quyền/không tồn tại. */
    public boolean delete(String reviewId, String userId) {
        Connection conn = null;
        try {
            conn = DBContext.getConnection();
            conn.setAutoCommit(false);

            String movieId = null;
            try (PreparedStatement ps = conn.prepareStatement(
                    "SELECT movie_id FROM MovieReviews WHERE id = ? AND user_id = ?")) {
                ps.setString(1, reviewId);
                ps.setString(2, userId);
                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) movieId = rs.getString("movie_id");
                }
            }
            if (movieId == null) {
                conn.rollback();
                return false;
            }

            try (PreparedStatement ps = conn.prepareStatement(
                    "DELETE FROM MovieReviews WHERE id = ? AND user_id = ?")) {
                ps.setString(1, reviewId);
                ps.setString(2, userId);
                ps.executeUpdate();
            }

            try (PreparedStatement ps = conn.prepareStatement("""
                    UPDATE Movies
                    SET average_rating = COALESCE(
                        (SELECT AVG(CAST(rating AS DECIMAL(10,2))) FROM MovieReviews WHERE movie_id = ?),
                        0.00
                    )
                    WHERE id = ?
                    """)) {
                ps.setString(1, movieId);
                ps.setString(2, movieId);
                ps.executeUpdate();
            }

            conn.commit();
            return true;
        } catch (SQLException e) {
            if (conn != null) {
                try { conn.rollback(); } catch (SQLException ignored) { }
            }
            throw new RuntimeException("MovieReviewDAO.delete failed", e);
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (SQLException ignored) { }
            }
        }
    }

    /** Đánh giá của một phim cụ thể (mới nhất trước) — dùng cho trang chi tiết phim. */
    public List<MovieReview> findByMovie(String movieId, int offset, int limit) {
        String sql = "SELECT " + MOVIE_JOIN_COLS + """
                FROM MovieReviews r
                JOIN Movies m ON m.id = r.movie_id
                JOIN Users  u ON u.id = r.user_id
                WHERE r.movie_id = ?
                ORDER BY r.created_at DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;
        return query(sql, movieId, offset, limit);
    }

    public int countByMovie(String movieId) {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM MovieReviews WHERE movie_id = ?")) {
            ps.setString(1, movieId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.countByMovie failed", e);
        }
    }

    /** Đánh giá mới nhất trên toàn hệ thống — /reviews?sort=latest */
    public List<MovieReview> findLatest(int offset, int limit) {
        String sql = "SELECT " + MOVIE_JOIN_COLS + """
                FROM MovieReviews r
                JOIN Movies m ON m.id = r.movie_id
                JOIN Users  u ON u.id = r.user_id
                ORDER BY r.created_at DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;
        return query(sql, offset, limit);
    }

    public int countLatest() {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM MovieReviews");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.countLatest failed", e);
        }
    }

    /** Đánh giá của một user — /reviews/mine */
    public List<MovieReview> findByUser(String userId, int offset, int limit) {
        String sql = "SELECT " + MOVIE_JOIN_COLS + """
                FROM MovieReviews r
                JOIN Movies m ON m.id = r.movie_id
                JOIN Users  u ON u.id = r.user_id
                WHERE r.user_id = ?
                ORDER BY r.created_at DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;
        return query(sql, userId, offset, limit);
    }

    /** ID các phim mà user đã đánh giá — dùng để loại khỏi danh sách "phim có thể đánh giá". */
    public Set<String> findReviewedMovieIds(String userId) {
        Set<String> ids = new HashSet<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT movie_id FROM MovieReviews WHERE user_id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) ids.add(rs.getString("movie_id"));
            }
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.findReviewedMovieIds failed", e);
        }
        return ids;
    }

    public int countByUser(String userId) {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(*) FROM MovieReviews WHERE user_id = ?")) {
            ps.setString(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.countByUser failed", e);
        }
    }

    /** Phim đánh giá cao nhất (có ít nhất 1 review) — /reviews?sort=top */
    public List<Movie> findTopRatedMovies(int offset, int limit) {
        String sql = """
                SELECT m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names,
                       COUNT(r.id) AS review_count
                FROM Movies m
                JOIN MovieReviews r ON r.movie_id = m.id
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY m.average_rating DESC, COUNT(r.id) DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;
        return queryMovies(sql, offset, limit);
    }

    /** Phim được yêu thích nhất (nhiều lượt đánh giá nhất) — /reviews?sort=popular */
    public List<Movie> findMostReviewedMovies(int offset, int limit) {
        String sql = """
                SELECT m.id, m.title, m.slug, m.description, m.duration_minutes,
                       m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                       m.age_rating, m.status, m.average_rating, m.created_at,
                       STRING_AGG(g.genre_name, ',') AS genre_names,
                       COUNT(r.id) AS review_count
                FROM Movies m
                JOIN MovieReviews r ON r.movie_id = m.id
                LEFT JOIN MovieGenres mg ON m.id = mg.movie_id
                LEFT JOIN Genres g       ON mg.genre_id = g.id
                GROUP BY m.id, m.title, m.slug, m.description, m.duration_minutes,
                         m.release_date, m.trailer_url, m.poster_url, m.backdrop_url, m.director,
                         m.age_rating, m.status, m.average_rating, m.created_at
                ORDER BY COUNT(r.id) DESC, m.average_rating DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """;
        return queryMovies(sql, offset, limit);
    }

    /** Số phim đã có ít nhất 1 đánh giá — dùng để phân trang top/popular. */
    public int countReviewedMovies() {
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                     "SELECT COUNT(DISTINCT movie_id) FROM MovieReviews");
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getInt(1) : 0;
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.countReviewedMovies failed", e);
        }
    }

    private List<Movie> queryMovies(String sql, int offset, int limit) {
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, offset);
            ps.setInt(2, limit);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
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
                    String genreNames = rs.getString("genre_names");
                    m.setGenres(genreNames != null && !genreNames.isBlank()
                            ? Arrays.asList(genreNames.split(",")) : new ArrayList<>());
                    m.setReviewCount(rs.getInt("review_count"));
                    result.add(m);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.queryMovies failed", e);
        }
        return result;
    }

    private List<MovieReview> query(String sql, Object... params) {
        List<MovieReview> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) {
                ps.setObject(i + 1, params[i]);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapJoined(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("MovieReviewDAO.query failed", e);
        }
        return result;
    }

    private MovieReview mapPlain(ResultSet rs) throws SQLException {
        MovieReview r = new MovieReview();
        r.setId(rs.getString("id"));
        r.setMovieId(rs.getString("movie_id"));
        r.setUserId(rs.getString("user_id"));
        r.setRating(rs.getInt("rating"));
        r.setReviewContent(rs.getString("review_content"));
        r.setCreatedAt(rs.getTimestamp("created_at"));
        return r;
    }

    private MovieReview mapJoined(ResultSet rs) throws SQLException {
        MovieReview r = mapPlain(rs);
        r.setMovieTitle(rs.getString("movie_title"));
        r.setMovieSlug(rs.getString("movie_slug"));
        r.setMoviePosterUrl(rs.getString("movie_poster_url"));
        r.setUserFullName(rs.getString("user_full_name"));
        r.setUserAvatarUrl(rs.getString("user_avatar_url"));
        return r;
    }

    private void setNullableString(PreparedStatement ps, int idx, String val) throws SQLException {
        if (val != null && !val.isBlank()) ps.setString(idx, val.trim());
        else ps.setNull(idx, Types.NVARCHAR);
    }
}
