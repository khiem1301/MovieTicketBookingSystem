package utils;

import model.dto.RevenuePeriodStatsDTO;
import model.dto.TopMovieStatsDTO;
import model.dto.TopShowtimeStatsDTO;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Date;
import java.util.List;

public final class ReportExportUtil {

    public static final String GROUP_DAY = "day";
    public static final String GROUP_MONTH = "month";
    public static final String GROUP_YEAR = "year";

    private static final DateTimeFormatter EXPORT_TS_FMT =
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private static final DateTimeFormatter SHOWTIME_FMT =
            DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private ReportExportUtil() {
    }

    public static String normalizeGroupBy(String raw) {
        if (raw == null) {
            return GROUP_MONTH;
        }
        return switch (raw.trim().toLowerCase()) {
            case GROUP_DAY, GROUP_YEAR -> raw.trim().toLowerCase();
            default -> GROUP_MONTH;
        };
    }

    public static String groupByLabel(String groupBy) {
        return switch (normalizeGroupBy(groupBy)) {
            case GROUP_DAY -> "ngày";
            case GROUP_YEAR -> "năm";
            default -> "tháng";
        };
    }

    public static String periodColumnLabel(String groupBy) {
        return switch (normalizeGroupBy(groupBy)) {
            case GROUP_DAY -> "Ngày";
            case GROUP_YEAR -> "Năm";
            default -> "Tháng";
        };
    }

    public static byte[] buildCsvBytes(List<RevenuePeriodStatsDTO> rows, String rangeLabel, String groupBy) {
        String normalized = normalizeGroupBy(groupBy);
        String periodHeader = periodColumnLabel(normalized);
        StringBuilder sb = new StringBuilder();
        sb.append("# ÉPCINE — Báo cáo doanh thu theo ").append(groupByLabel(normalized)).append('\n');
        sb.append("# Khoảng: ").append(escapeCsv(rangeLabel)).append('\n');
        sb.append("# Tạo lúc: ").append(LocalDateTime.now().format(EXPORT_TS_FMT)).append('\n');
        sb.append(periodHeader).append(",Doanh thu (VND),Số đơn,Số vé\n");

        if (rows == null || rows.isEmpty()) {
            sb.append("(Không có dữ liệu),0,0,0\n");
        } else {
            for (RevenuePeriodStatsDTO row : rows) {
                sb.append(escapeCsv(row.getPeriodLabel())).append(',');
                sb.append(formatAmount(row.getRevenue())).append(',');
                sb.append(row.getBookingCount()).append(',');
                sb.append(row.getTicketCount()).append('\n');
            }
        }

        String csv = sb.toString();
        return toUtf8BomBytes(csv);
    }

    public static String buildFilename(String groupBy, String rangeKey) {
        String normalized = normalizeGroupBy(groupBy);
        String safeRange = rangeKey == null || rangeKey.isBlank() ? "all" : rangeKey.replaceAll("[^a-zA-Z0-9_-]", "");
        return "revenue-" + normalized + "-" + safeRange + ".csv";
    }

    public static String buildExportQuery(String range, String from, String to, String groupBy) {
        StringBuilder q = new StringBuilder();
        appendParam(q, "range", range);
        appendParam(q, "from", from);
        appendParam(q, "to", to);
        appendParam(q, "groupBy", normalizeGroupBy(groupBy));
        return q.toString();
    }

    public static String buildTicketExportQuery(String range, String from, String to, String viewBy) {
        StringBuilder q = new StringBuilder();
        appendParam(q, "range", range);
        appendParam(q, "from", from);
        appendParam(q, "to", to);
        appendParam(q, "viewBy", TicketStatsViewUtil.normalizeViewBy(viewBy));
        return q.toString();
    }

    public static byte[] buildMovieTicketCsvBytes(List<TopMovieStatsDTO> rows, String rangeLabel) {
        StringBuilder sb = new StringBuilder();
        sb.append("# ÉPCINE — Thống kê vé bán theo phim\n");
        sb.append("# Khoảng: ").append(escapeCsv(rangeLabel)).append('\n');
        sb.append("# Lọc theo: ngày đặt vé (booked_at)\n");
        sb.append("# Tạo lúc: ").append(LocalDateTime.now().format(EXPORT_TS_FMT)).append('\n');
        sb.append("Phim,Số vé,Số đơn,Doanh thu (VND)\n");

        if (rows == null || rows.isEmpty()) {
            sb.append("(Không có dữ liệu),0,0,0\n");
        } else {
            for (TopMovieStatsDTO row : rows) {
                sb.append(escapeCsv(row.getTitle())).append(',');
                sb.append(row.getTicketCount()).append(',');
                sb.append(row.getBookingCount()).append(',');
                sb.append(formatAmount(row.getRevenue())).append('\n');
            }
        }
        return toUtf8BomBytes(sb.toString());
    }

    public static byte[] buildShowtimeTicketCsvBytes(List<TopShowtimeStatsDTO> rows, String rangeLabel) {
        StringBuilder sb = new StringBuilder();
        sb.append("# ÉPCINE — Thống kê vé bán theo suất chiếu\n");
        sb.append("# Khoảng: ").append(escapeCsv(rangeLabel)).append('\n');
        sb.append("# Lọc theo: giờ chiếu (start_time)\n");
        sb.append("# Tạo lúc: ").append(LocalDateTime.now().format(EXPORT_TS_FMT)).append('\n');
        sb.append("Phim,Phòng,Giờ chiếu,Trạng thái,Số vé,Số đơn,Doanh thu (VND)\n");

        if (rows == null || rows.isEmpty()) {
            sb.append("(Không có dữ liệu),,,,0,0,0\n");
        } else {
            for (TopShowtimeStatsDTO row : rows) {
                sb.append(escapeCsv(row.getMovieTitle())).append(',');
                sb.append(escapeCsv(row.getRoomName())).append(',');
                sb.append(escapeCsv(formatShowtime(row.getStartTime()))).append(',');
                sb.append(escapeCsv(row.getShowtimeStatus())).append(',');
                sb.append(row.getTicketCount()).append(',');
                sb.append(row.getBookingCount()).append(',');
                sb.append(formatAmount(row.getRevenue())).append('\n');
            }
        }
        return toUtf8BomBytes(sb.toString());
    }

    public static String buildTicketFilename(String viewBy, String rangeKey) {
        String normalized = TicketStatsViewUtil.normalizeViewBy(viewBy);
        String safeRange = rangeKey == null || rangeKey.isBlank() ? "all" : rangeKey.replaceAll("[^a-zA-Z0-9_-]", "");
        return "tickets-" + normalized + "-" + safeRange + ".csv";
    }

    private static String formatShowtime(Date value) {
        if (value == null) {
            return "";
        }
        return SHOWTIME_FMT.format(
                value.toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDateTime());
    }

    private static byte[] toUtf8BomBytes(String csv) {
        byte[] bom = new byte[] {(byte) 0xEF, (byte) 0xBB, (byte) 0xBF};
        byte[] body = csv.getBytes(java.nio.charset.StandardCharsets.UTF_8);
        byte[] result = new byte[bom.length + body.length];
        System.arraycopy(bom, 0, result, 0, bom.length);
        System.arraycopy(body, 0, result, bom.length, body.length);
        return result;
    }

    private static void appendParam(StringBuilder q, String name, String value) {
        if (value == null || value.isBlank()) {
            return;
        }
        if (!q.isEmpty()) {
            q.append('&');
        }
        q.append(name).append('=').append(java.net.URLEncoder.encode(value.trim(), java.nio.charset.StandardCharsets.UTF_8));
    }

    private static String formatAmount(BigDecimal amount) {
        if (amount == null) {
            return "0";
        }
        return amount.stripTrailingZeros().toPlainString();
    }

    private static String escapeCsv(String value) {
        if (value == null) {
            return "";
        }
        if (value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")) {
            return "\"" + value.replace("\"", "\"\"") + "\"";
        }
        return value;
    }
}
