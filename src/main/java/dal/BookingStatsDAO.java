package dal;

import model.dto.BookingOverviewStatsDTO;
import model.dto.TopMovieStatsDTO;
import utils.ReportDateUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * Aggregate thống kê đặt vé — doanh thu, số vé, top phim.
 * Chỉ tính đơn CONFIRMED + PAID (nguồn: Bookings, chưa dùng Payments).
 */
public class BookingStatsDAO {

    private static final String PAID_BOOKING_WHERE = """
            booking_status = 'CONFIRMED'
            AND payment_status = 'PAID'
            """;

    private static final String PAID_BOOKING_WHERE_B = """
            b.booking_status = 'CONFIRMED'
            AND b.payment_status = 'PAID'
            """;

    public BookingOverviewStatsDTO getOverviewStats(LocalDateTime fromInclusive, LocalDateTime toExclusive) {
        BookingOverviewStatsDTO stats = new BookingOverviewStatsDTO();
        stats.setRevenue(sumRevenue(fromInclusive, toExclusive));
        stats.setBookingCount(countBookings(fromInclusive, toExclusive));
        stats.setTicketCount(countTickets(fromInclusive, toExclusive));
        return stats;
    }

    public BookingOverviewStatsDTO getCurrentMonthOverview() {
        ReportDateUtil.DateRange month = ReportDateUtil.currentMonth();
        return getOverviewStats(month.fromInclusive(), month.toExclusive());
    }

    public List<TopMovieStatsDTO> findTopMoviesByTickets(
            LocalDateTime fromInclusive, LocalDateTime toExclusive, int offset, int limit) {
        if (limit <= 0) {
            return List.of();
        }

        String dateFilterB = buildDateFilter("b.booked_at", fromInclusive, toExclusive);
        String dateFilterB2 = buildDateFilter("b2.booked_at", fromInclusive, toExclusive);

        String sql = """
                SELECT m.id, m.title, m.poster_url,
                       ticket_stats.ticket_count,
                       ticket_stats.booking_count,
                       COALESCE(rev.revenue, 0) AS revenue
                FROM Movies m
                INNER JOIN (
                    SELECT s.movie_id,
                           COUNT(bs.id) AS ticket_count,
                           COUNT(DISTINCT b.id) AS booking_count
                    FROM Bookings b
                    INNER JOIN Showtimes s ON s.id = b.showtime_id
                    INNER JOIN BookingSeats bs ON bs.booking_id = b.id
                    WHERE %s
                    %s
                    GROUP BY s.movie_id
                ) ticket_stats ON ticket_stats.movie_id = m.id
                LEFT JOIN (
                    SELECT s2.movie_id, SUM(b2.final_amount) AS revenue
                    FROM Bookings b2
                    INNER JOIN Showtimes s2 ON s2.id = b2.showtime_id
                    WHERE %s
                    %s
                    GROUP BY s2.movie_id
                ) rev ON rev.movie_id = m.id
                ORDER BY ticket_stats.ticket_count DESC, rev.revenue DESC, m.title ASC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """.formatted(PAID_BOOKING_WHERE, dateFilterB, PAID_BOOKING_WHERE, dateFilterB2);

        List<TopMovieStatsDTO> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = bindDateParams(ps, 1, fromInclusive, toExclusive);
            idx = bindDateParams(ps, idx, fromInclusive, toExclusive);
            ps.setInt(idx, Math.max(0, offset));
            ps.setInt(idx + 1, limit);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TopMovieStatsDTO dto = new TopMovieStatsDTO();
                    dto.setMovieId(rs.getString("id"));
                    dto.setTitle(rs.getString("title"));
                    dto.setPosterUrl(rs.getString("poster_url"));
                    dto.setTicketCount(rs.getInt("ticket_count"));
                    dto.setBookingCount(rs.getInt("booking_count"));
                    dto.setRevenue(rs.getBigDecimal("revenue"));
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findTopMoviesByTickets failed", e);
        }
        return result;
    }

    public int countTopMovies(LocalDateTime fromInclusive, LocalDateTime toExclusive) {
        String dateFilterB = buildDateFilter("b.booked_at", fromInclusive, toExclusive);
        String sql = """
                SELECT COUNT(*) AS total
                FROM (
                    SELECT s.movie_id
                    FROM Bookings b
                    INNER JOIN Showtimes s ON s.id = b.showtime_id
                    INNER JOIN BookingSeats bs ON bs.booking_id = b.id
                    WHERE %s
                    %s
                    GROUP BY s.movie_id
                ) counted
                """.formatted(PAID_BOOKING_WHERE, dateFilterB);

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindDateParams(ps, 1, fromInclusive, toExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("countTopMovies failed", e);
        }
        return 0;
    }

    private BigDecimal sumRevenue(LocalDateTime fromInclusive, LocalDateTime toExclusive) {
        String sql = """
                SELECT COALESCE(SUM(final_amount), 0) AS revenue
                FROM Bookings
                WHERE %s
                %s
                """.formatted(PAID_BOOKING_WHERE, buildDateFilter("booked_at", fromInclusive, toExclusive));

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindDateParams(ps, 1, fromInclusive, toExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getBigDecimal("revenue");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("sumRevenue failed", e);
        }
        return BigDecimal.ZERO;
    }

    private int countBookings(LocalDateTime fromInclusive, LocalDateTime toExclusive) {
        String sql = """
                SELECT COUNT(*) AS total
                FROM Bookings
                WHERE %s
                %s
                """.formatted(PAID_BOOKING_WHERE, buildDateFilter("booked_at", fromInclusive, toExclusive));

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindDateParams(ps, 1, fromInclusive, toExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("countBookings failed", e);
        }
        return 0;
    }

    private int countTickets(LocalDateTime fromInclusive, LocalDateTime toExclusive) {
        String sql = """
                SELECT COUNT(bs.id) AS total
                FROM BookingSeats bs
                INNER JOIN Bookings b ON b.id = bs.booking_id
                WHERE %s
                %s
                """.formatted(PAID_BOOKING_WHERE_B, buildDateFilter("b.booked_at", fromInclusive, toExclusive));

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindDateParams(ps, 1, fromInclusive, toExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("countTickets failed", e);
        }
        return 0;
    }

    private static String buildDateFilter(String column, LocalDateTime fromInclusive, LocalDateTime toExclusive) {
        if (fromInclusive == null || toExclusive == null) {
            return "";
        }
        return " AND " + column + " >= ? AND " + column + " < ? ";
    }

    private static int bindDateParams(
            PreparedStatement ps, int startIndex,
            LocalDateTime fromInclusive, LocalDateTime toExclusive) throws SQLException {
        if (fromInclusive == null || toExclusive == null) {
            return startIndex;
        }
        ps.setTimestamp(startIndex, Timestamp.valueOf(fromInclusive));
        ps.setTimestamp(startIndex + 1, Timestamp.valueOf(toExclusive));
        return startIndex + 2;
    }
}
