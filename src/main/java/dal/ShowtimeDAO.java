package dal;

import model.entity.Movie;
import model.entity.Showtime;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ShowtimeDAO {

    /**
     * FR-35 — Lấy danh sách phim đang có lịch chiếu active (cho bước chọn phim tại quầy).
     * Chỉ trả phim có ít nhất 1 suất OPEN/SCHEDULED từ hiện tại trở đi.
     */
    public List<Movie> getMoviesWithActiveShowtimes() {
        String sql = """
                SELECT DISTINCT m.id, m.title, m.slug, m.poster_url, m.backdrop_url,
                       m.duration_minutes, m.age_rating, m.status, m.average_rating, m.created_at,
                       NULL AS genre_names
                FROM Movies m
                JOIN Showtimes s ON m.id = s.movie_id
                WHERE s.status IN ('OPEN', 'SCHEDULED')
                  AND s.start_time >= GETDATE()
                ORDER BY m.title
                """;
        List<Movie> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) result.add(mapMovie(rs));
        } catch (SQLException e) {
            throw new RuntimeException("getMoviesWithActiveShowtimes failed", e);
        }
        return result;
    }

    /**
     * FR-35 — Lấy danh sách suất chiếu còn lại trong ngày + tương lai theo phim.
     */
    public List<Showtime> getShowtimesByMovieId(String movieId) {
        String sql = """
                SELECT s.id, s.movie_id, m.title AS movie_title, m.poster_url AS movie_poster_url,
                       m.duration_minutes AS movie_duration, m.age_rating AS movie_age_rating,
                       s.room_id, cr.room_name,
                       s.start_time, s.end_time, s.base_price, s.status, s.created_at
                FROM Showtimes s
                JOIN Movies m      ON m.id = s.movie_id
                JOIN CinemaRooms cr ON cr.id = s.room_id
                WHERE s.movie_id = ?
                  AND s.status IN ('OPEN', 'SCHEDULED')
                  AND s.start_time >= GETDATE()
                ORDER BY s.start_time
                """;
        List<Showtime> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, movieId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapShowtime(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getShowtimesByMovieId failed", e);
        }
        return result;
    }

    /** Lấy thông tin đầy đủ một suất chiếu theo ID. */
    public Showtime getShowtimeById(String showtimeId) {
        String sql = """
                SELECT s.id, s.movie_id, m.title AS movie_title, m.poster_url AS movie_poster_url,
                       m.duration_minutes AS movie_duration, m.age_rating AS movie_age_rating,
                       s.room_id, cr.room_name,
                       s.start_time, s.end_time, s.base_price, s.status, s.created_at
                FROM Showtimes s
                JOIN Movies m      ON m.id = s.movie_id
                JOIN CinemaRooms cr ON cr.id = s.room_id
                WHERE s.id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return mapShowtime(rs);
            }
        } catch (SQLException e) {
            throw new RuntimeException("getShowtimeById failed", e);
        }
        return null;
    }

    private Movie mapMovie(ResultSet rs) throws SQLException {
        Movie m = new Movie();
        m.setId(rs.getString("id"));
        m.setTitle(rs.getString("title"));
        m.setSlug(rs.getString("slug"));
        m.setPosterUrl(rs.getString("poster_url"));
        m.setBackdropUrl(rs.getString("backdrop_url"));
        m.setDurationMinutes(rs.getInt("duration_minutes"));
        m.setAgeRating(rs.getString("age_rating"));
        m.setStatus(rs.getString("status"));
        BigDecimal rating = rs.getBigDecimal("average_rating");
        m.setAverageRating(rating != null ? rating : BigDecimal.ZERO);
        m.setCreatedAt(rs.getTimestamp("created_at"));
        m.setGenres(new ArrayList<>());
        return m;
    }

    private Showtime mapShowtime(ResultSet rs) throws SQLException {
        Showtime s = new Showtime();
        s.setId(rs.getString("id"));
        s.setMovieId(rs.getString("movie_id"));
        s.setMovieTitle(rs.getString("movie_title"));
        s.setMoviePosterUrl(rs.getString("movie_poster_url"));
        s.setMovieDurationMinutes(rs.getInt("movie_duration"));
        s.setMovieAgeRating(rs.getString("movie_age_rating"));
        s.setRoomId(rs.getString("room_id"));
        s.setRoomName(rs.getString("room_name"));
        s.setStartTime(rs.getTimestamp("start_time"));
        s.setEndTime(rs.getTimestamp("end_time"));
        s.setBasePrice(rs.getBigDecimal("base_price"));
        s.setStatus(rs.getString("status"));
        s.setCreatedAt(rs.getTimestamp("created_at"));
        return s;
    }
}
