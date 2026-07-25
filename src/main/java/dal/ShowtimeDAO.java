package dal;

import model.entity.Movie;
import model.entity.Showtime;

import java.math.BigDecimal;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class ShowtimeDAO {

    /** Thời gian dọn phòng giữa hai suất (phút) — tính vào kiểm tra trùng lịch. */
    public static final int CLEANUP_BUFFER_MINUTES = 15;

    /** Cho phép đặt vé muộn tối đa N phút sau start_time (đồng bộ {@link utils.ShowtimeBookingWindow}). */
    public static final int LATE_BOOKING_GRACE_MINUTES = utils.ShowtimeBookingWindow.LATE_BOOKING_GRACE_MINUTES;

    private static final String ACTIVE_BOOKING_PRED = """
            (
                b.booking_status = 'CONFIRMED'
                OR (
                    b.booking_status = 'PENDING'
                    AND (b.expired_at IS NULL OR b.expired_at > GETDATE())
                )
            )
            """;

    private static final String MANAGER_SELECT = """
            SELECT s.id, s.movie_id, m.title AS movie_title, m.poster_url AS movie_poster_url,
                   m.duration_minutes AS movie_duration, m.age_rating AS movie_age_rating,
                   s.room_id, cr.room_name, cr.capacity AS room_capacity,
                   s.start_time, s.end_time, s.base_price, s.status, s.created_at,
                   (SELECT COUNT(1) FROM Bookings b
                    WHERE b.showtime_id = s.id AND %s) AS booking_count,
                   (SELECT COUNT(1) FROM BookingSeats bs
                    JOIN Bookings b ON b.id = bs.booking_id
                    WHERE b.showtime_id = s.id AND %s) AS sold_seats
            FROM Showtimes s
            JOIN Movies m       ON m.id = s.movie_id
            JOIN CinemaRooms cr ON cr.id = s.room_id
            """.formatted(ACTIVE_BOOKING_PRED, ACTIVE_BOOKING_PRED);

    /**
     * FR-35 — Lấy danh sách phim cho trang POS tại quầy.
     * Trả về phim NOW_SHOWING + phim COMING_SOON có lịch chiếu tương lai.
     * Không bắt buộc phải có showtime để phim hiện ra — staff sẽ thấy
     * "Chưa có suất" khi chọn phim chưa có lịch.
     */
    public List<Movie> getMoviesWithActiveShowtimes() {
        String sql = """
                SELECT DISTINCT m.id, m.title, m.slug, m.poster_url, m.backdrop_url,
                       m.duration_minutes, m.age_rating, m.status, m.average_rating, m.created_at,
                       NULL AS genre_names
                FROM Movies m
                WHERE m.status = 'NOW_SHOWING'
                   OR EXISTS (
                       SELECT 1 FROM Showtimes s
                       WHERE s.movie_id = m.id
                         AND s.status IN ('SCHEDULED', 'SHOWING')
                         AND s.start_time > SYSDATETIME()
                   )
                ORDER BY m.status DESC, m.title
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
     * FR-11 — Suất chiếu sắp tới của phim (từ hiện tại trở đi, không gồm CANCELLED).
     */
    public List<Showtime> getUpcomingShowtimesByMovieId(String movieId) {
        String sql = """
                SELECT s.id, s.movie_id, m.title AS movie_title, m.poster_url AS movie_poster_url,
                       m.duration_minutes AS movie_duration, m.age_rating AS movie_age_rating,
                       s.room_id, cr.room_name,
                       s.start_time, s.end_time, s.base_price, s.status, s.created_at
                FROM Showtimes s
                JOIN Movies m       ON m.id = s.movie_id
                JOIN CinemaRooms cr ON cr.id = s.room_id
                WHERE s.movie_id = ?
                  AND s.status IN ('SCHEDULED', 'SHOWING')
                  AND s.end_time > SYSDATETIME()
                  AND s.start_time >= DATEADD(MINUTE, -?, SYSDATETIME())
                ORDER BY s.start_time
                """;
        List<Showtime> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, movieId);
            ps.setInt(2, LATE_BOOKING_GRACE_MINUTES);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapShowtime(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getUpcomingShowtimesByMovieId failed", e);
        }
        return result;
    }

    /**
     * FR-35 — Lấy danh sách suất chiếu còn đặt được (kể cả muộn trong grace) theo phim.
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
                  AND s.status IN ('SCHEDULED', 'SHOWING')
                  AND s.end_time > SYSDATETIME()
                  AND s.start_time >= DATEADD(MINUTE, -?, SYSDATETIME())
                ORDER BY s.start_time
                """;
        List<Showtime> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, movieId);
            ps.setInt(2, LATE_BOOKING_GRACE_MINUTES);
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

    /** FR-25 — Danh sách suất chiếu cho manager (mọi trạng thái). */
    public List<Showtime> getAllForManager() {
        String sql = MANAGER_SELECT + " ORDER BY cr.room_name ASC, s.start_time DESC";
        List<Showtime> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) result.add(mapShowtime(rs));
        } catch (SQLException e) {
            throw new RuntimeException("getAllForManager failed", e);
        }
        return result;
    }

    public void create(Showtime showtime, String createdBy) {
        String sql = """
                INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by)
                VALUES (NEWID(), ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtime.getMovieId());
            ps.setString(2, showtime.getRoomId());
            ps.setTimestamp(3, showtime.getStartTime());
            ps.setTimestamp(4, showtime.getEndTime());
            ps.setBigDecimal(5, showtime.getBasePrice());
            ps.setString(6, showtime.getStatus());
            ps.setString(7, createdBy);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("create showtime failed", e);
        }
    }

    /** Tạo nhiều suất trong một transaction. */
    public int createBatch(List<Showtime> showtimes, String createdBy) {
        if (showtimes == null || showtimes.isEmpty()) return 0;
        String sql = """
                INSERT INTO Showtimes (id, movie_id, room_id, start_time, end_time, base_price, status, created_by)
                VALUES (NEWID(), ?, ?, ?, ?, ?, ?, ?)
                """;
        try (Connection conn = DBContext.getConnection()) {
            conn.setAutoCommit(false);
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (Showtime showtime : showtimes) {
                    ps.setString(1, showtime.getMovieId());
                    ps.setString(2, showtime.getRoomId());
                    ps.setTimestamp(3, showtime.getStartTime());
                    ps.setTimestamp(4, showtime.getEndTime());
                    ps.setBigDecimal(5, showtime.getBasePrice());
                    ps.setString(6, showtime.getStatus());
                    ps.setString(7, createdBy);
                    ps.addBatch();
                }
                int[] counts = ps.executeBatch();
                conn.commit();
                int created = 0;
                for (int c : counts) {
                    if (c >= 0) created += c;
                    else if (c == Statement.SUCCESS_NO_INFO) created++;
                }
                return created;
            } catch (SQLException e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (SQLException e) {
            throw new RuntimeException("createBatch showtimes failed", e);
        }
    }

    public void update(Showtime showtime) {
        String sql = """
                UPDATE Showtimes
                SET movie_id = ?, room_id = ?, start_time = ?, end_time = ?,
                    base_price = ?, status = ?
                WHERE id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtime.getMovieId());
            ps.setString(2, showtime.getRoomId());
            ps.setTimestamp(3, showtime.getStartTime());
            ps.setTimestamp(4, showtime.getEndTime());
            ps.setBigDecimal(5, showtime.getBasePrice());
            ps.setString(6, showtime.getStatus());
            ps.setString(7, showtime.getId());
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("update showtime failed", e);
        }
    }

    public void updateStatus(String id, String status) {
        String sql = "UPDATE Showtimes SET status = ? WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("updateStatus failed", e);
        }
    }

    public void delete(String id) {
        String sql = "DELETE FROM Showtimes WHERE id = ?";
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, id);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("delete showtime failed", e);
        }
    }

    /**
     * Kiểm tra trùng lịch cùng phòng (bỏ qua suất CANCELLED), cộng buffer dọn phòng.
     * Overlap khi khoảng [start, end+buffer] giao nhau.
     */
    public boolean isOverlapping(String roomId, Timestamp startTime, Timestamp endTime, String excludeId) {
        return isOverlapping(roomId, startTime, endTime, excludeId, CLEANUP_BUFFER_MINUTES);
    }

    public boolean isOverlapping(String roomId, Timestamp startTime, Timestamp endTime,
                                 String excludeId, int bufferMinutes) {
        String sql = """
                SELECT COUNT(1)
                FROM Showtimes
                WHERE room_id = ?
                  AND status <> 'CANCELLED'
                  AND start_time < DATEADD(MINUTE, ?, ?)
                  AND DATEADD(MINUTE, ?, end_time) > ?
                """;
        if (excludeId != null && !excludeId.isBlank()) {
            sql += " AND id <> ?";
        }
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, roomId);
            ps.setInt(2, bufferMinutes);
            ps.setTimestamp(3, endTime);
            ps.setInt(4, bufferMinutes);
            ps.setTimestamp(5, startTime);
            if (excludeId != null && !excludeId.isBlank()) {
                ps.setString(6, excludeId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() && rs.getInt(1) > 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("isOverlapping failed", e);
        }
    }

    /** Đếm booking còn hiệu lực (CONFIRMED, hoặc PENDING chưa hết hạn). */
    public int countBookingsByShowtimeId(String showtimeId) {
        String sql = """
                SELECT COUNT(1) FROM Bookings b
                WHERE b.showtime_id = ?
                  AND %s
                """.formatted(ACTIVE_BOOKING_PRED);
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        } catch (SQLException e) {
            throw new RuntimeException("countBookingsByShowtimeId failed", e);
        }
    }

    /**
     * Đồng bộ trạng thái theo thời gian thực (không đụng CANCELLED):
     *   now &lt; start  → SCHEDULED
     *   start ≤ now &lt; end → SHOWING
     *   now ≥ end   → FINISHED
     */
    public int autoSyncStatuses() {
        String sql = """
                UPDATE Showtimes
                SET status = CASE
                    WHEN end_time   <= SYSDATETIME() THEN 'FINISHED'
                    WHEN start_time <= SYSDATETIME() THEN 'SHOWING'
                    ELSE 'SCHEDULED'
                END
                WHERE status <> 'CANCELLED'
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            return ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("autoSyncStatuses failed", e);
        }
    }

    /** @deprecated dùng {@link #autoSyncStatuses()} */
    @Deprecated
    public int autoMarkFinished() {
        return autoSyncStatuses();
    }

    /** @deprecated hết vé không còn là status suất chiếu */
    @Deprecated
    public int autoMarkSoldOut() {
        return 0;
    }

    /** Suất không huỷ trong một ngày (để copy lịch). */
    public List<Showtime> getByDateForCopy(java.sql.Date date, String roomId) {
        String sql = MANAGER_SELECT + """
                 WHERE CAST(s.start_time AS DATE) = ?
                   AND s.status <> 'CANCELLED'
                """;
        if (roomId != null && !roomId.isBlank()) {
            sql += " AND s.room_id = ?";
        }
        sql += " ORDER BY s.start_time ASC";
        List<Showtime> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, date);
            if (roomId != null && !roomId.isBlank()) {
                ps.setString(2, roomId);
            }
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) result.add(mapShowtime(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("getByDateForCopy failed", e);
        }
        return result;
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
        try {
            s.setRoomCapacity(rs.getInt("room_capacity"));
        } catch (SQLException ignored) {
            s.setRoomCapacity(0);
        }
        try {
            s.setSoldSeats(rs.getInt("sold_seats"));
        } catch (SQLException ignored) {
            s.setSoldSeats(0);
        }
        try {
            s.setBookingCount(rs.getInt("booking_count"));
        } catch (SQLException ignored) {
            s.setBookingCount(0);
        }
        return s;
    }
}
