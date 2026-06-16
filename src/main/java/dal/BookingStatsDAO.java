package dal;

import model.dto.BookingOverviewStatsDTO;
import model.dto.RevenuePeriodStatsDTO;
import model.dto.TopMovieStatsDTO;
import model.dto.TopShowtimeStatsDTO;
import utils.ReportDateUtil;
import utils.ReportExportUtil;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Year;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Aggregate thống kê đặt vé — doanh thu, số vé, top phim.
 * Chỉ tính đơn CONFIRMED + PAID (nguồn: Bookings, chưa dùng Payments).
 */
public class BookingStatsDAO {

    public static final int EXPORT_ROW_LIMIT = 10_000;

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

    public List<RevenuePeriodStatsDTO> findRevenueByPeriod(
            LocalDateTime fromInclusive, LocalDateTime toExclusive, String groupBy) {
        String normalized = ReportExportUtil.normalizeGroupBy(groupBy);
        PeriodSql periodSql = buildPeriodSql(normalized);
        String dateFilter = buildDateFilter("b.booked_at", fromInclusive, toExclusive);

        String sql = """
                SELECT %s AS period_key,
                       %s AS sort_key,
                       COALESCE(SUM(b.final_amount), 0) AS revenue,
                       COUNT(DISTINCT b.id) AS booking_count,
                       COUNT(bs.id) AS ticket_count
                FROM Bookings b
                LEFT JOIN BookingSeats bs ON bs.booking_id = b.id
                WHERE %s
                %s
                GROUP BY %s
                ORDER BY sort_key ASC
                """.formatted(
                periodSql.selectExpr(),
                periodSql.sortExpr(),
                PAID_BOOKING_WHERE_B,
                dateFilter,
                periodSql.groupByExpr());

        List<RevenuePeriodStatsDTO> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindDateParams(ps, 1, fromInclusive, toExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    RevenuePeriodStatsDTO dto = new RevenuePeriodStatsDTO();
                    String periodKey = rs.getString("period_key");
                    dto.setPeriodKey(periodKey);
                    dto.setPeriodLabel(formatPeriodLabel(normalized, periodKey, rs));
                    dto.setRevenue(rs.getBigDecimal("revenue"));
                    dto.setBookingCount(rs.getInt("booking_count"));
                    dto.setTicketCount(rs.getInt("ticket_count"));
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findRevenueByPeriod failed", e);
        }
        return result;
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

    public List<TopShowtimeStatsDTO> findTicketStatsByShowtime(
            LocalDateTime fromInclusive, LocalDateTime toExclusive, int offset, int limit) {
        if (limit <= 0) {
            return List.of();
        }

        String dateFilter = buildDateFilter("s.start_time", fromInclusive, toExclusive);
        String sql = """
                SELECT s.id, m.title, r.room_name, s.start_time, s.end_time, s.status,
                       COUNT(bs.id) AS ticket_count,
                       COUNT(DISTINCT b.id) AS booking_count,
                       COALESCE(SUM(b.final_amount), 0) AS revenue
                FROM Showtimes s
                INNER JOIN Bookings b ON b.showtime_id = s.id
                INNER JOIN BookingSeats bs ON bs.booking_id = b.id
                INNER JOIN Movies m ON m.id = s.movie_id
                INNER JOIN CinemaRooms r ON r.id = s.room_id
                WHERE %s
                %s
                GROUP BY s.id, m.title, r.room_name, s.start_time, s.end_time, s.status
                ORDER BY ticket_count DESC, s.start_time DESC
                OFFSET ? ROWS FETCH NEXT ? ROWS ONLY
                """.formatted(PAID_BOOKING_WHERE_B, dateFilter);

        List<TopShowtimeStatsDTO> result = new ArrayList<>();
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            int idx = bindDateParams(ps, 1, fromInclusive, toExclusive);
            ps.setInt(idx, Math.max(0, offset));
            ps.setInt(idx + 1, limit);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    TopShowtimeStatsDTO dto = new TopShowtimeStatsDTO();
                    dto.setShowtimeId(rs.getString("id"));
                    dto.setMovieTitle(rs.getString("title"));
                    dto.setRoomName(rs.getString("room_name"));
                    Timestamp start = rs.getTimestamp("start_time");
                    Timestamp end = rs.getTimestamp("end_time");
                    if (start != null) {
                        dto.setStartTime(new java.util.Date(start.getTime()));
                    }
                    if (end != null) {
                        dto.setEndTime(new java.util.Date(end.getTime()));
                    }
                    dto.setShowtimeStatus(rs.getString("status"));
                    dto.setTicketCount(rs.getInt("ticket_count"));
                    dto.setBookingCount(rs.getInt("booking_count"));
                    dto.setRevenue(rs.getBigDecimal("revenue"));
                    result.add(dto);
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findTicketStatsByShowtime failed", e);
        }
        return result;
    }

    public int countShowtimesWithTickets(LocalDateTime fromInclusive, LocalDateTime toExclusive) {
        String dateFilter = buildDateFilter("s.start_time", fromInclusive, toExclusive);
        String sql = """
                SELECT COUNT(*) AS total
                FROM (
                    SELECT s.id
                    FROM Showtimes s
                    INNER JOIN Bookings b ON b.showtime_id = s.id
                    INNER JOIN BookingSeats bs ON bs.booking_id = b.id
                    WHERE %s
                    %s
                    GROUP BY s.id
                ) counted
                """.formatted(PAID_BOOKING_WHERE_B, dateFilter);

        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            bindDateParams(ps, 1, fromInclusive, toExclusive);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("total");
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("countShowtimesWithTickets failed", e);
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

    private static PeriodSql buildPeriodSql(String groupBy) {
        return switch (groupBy) {
            case ReportExportUtil.GROUP_DAY -> new PeriodSql(
                    "CAST(b.booked_at AS DATE)",
                    "CAST(b.booked_at AS DATE)",
                    "CAST(b.booked_at AS DATE)");
            case ReportExportUtil.GROUP_YEAR -> new PeriodSql(
                    "CAST(YEAR(b.booked_at) AS VARCHAR(4))",
                    "YEAR(b.booked_at)",
                    "YEAR(b.booked_at)");
            default -> new PeriodSql(
                    "CONCAT(CAST(YEAR(b.booked_at) AS VARCHAR(4)), '-', RIGHT('0' + CAST(MONTH(b.booked_at) AS VARCHAR(2)), 2))",
                    "YEAR(b.booked_at) * 100 + MONTH(b.booked_at)",
                    "YEAR(b.booked_at), MONTH(b.booked_at)");
        };
    }

    private static String formatPeriodLabel(String groupBy, String periodKey, ResultSet rs) throws SQLException {
        if (periodKey == null || periodKey.isBlank()) {
            return "—";
        }
        return switch (groupBy) {
            case ReportExportUtil.GROUP_DAY -> {
                Date date = rs.getDate("sort_key");
                if (date != null) {
                    yield date.toLocalDate().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                }
                try {
                    yield LocalDate.parse(periodKey.trim().substring(0, 10), DateTimeFormatter.ISO_LOCAL_DATE)
                            .format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                } catch (Exception ex) {
                    yield periodKey;
                }
            }
            case ReportExportUtil.GROUP_YEAR -> Year.of(Integer.parseInt(periodKey.trim())).toString();
            default -> {
                YearMonth ym = YearMonth.parse(periodKey, DateTimeFormatter.ofPattern("yyyy-MM"));
                yield String.format("%02d/%d", ym.getMonthValue(), ym.getYear());
            }
        };
    }

    private record PeriodSql(String selectExpr, String sortExpr, String groupByExpr) {
    }
}
