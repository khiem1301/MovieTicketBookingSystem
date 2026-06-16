package utils;

public final class TicketStatsViewUtil {

    public static final String VIEW_MOVIE = "movie";
    public static final String VIEW_SHOWTIME = "showtime";

    private TicketStatsViewUtil() {
    }

    public static String normalizeViewBy(String raw) {
        if (raw == null) {
            return VIEW_MOVIE;
        }
        return VIEW_SHOWTIME.equalsIgnoreCase(raw.trim()) ? VIEW_SHOWTIME : VIEW_MOVIE;
    }

    public static boolean isShowtimeView(String viewBy) {
        return VIEW_SHOWTIME.equals(normalizeViewBy(viewBy));
    }

    public static String viewByLabel(String viewBy) {
        return isShowtimeView(viewBy) ? "suất chiếu" : "phim";
    }
}
