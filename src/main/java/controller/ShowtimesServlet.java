package controller;

import dal.BookingDAO;
import dal.MovieDAO;
import dal.MovieReviewDAO;
import dal.PricingRuleDAO;
import dal.ShowtimeDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.SessionUser;
import model.entity.Movie;
import model.entity.MovieReview;
import model.entity.PricingRule;
import model.entity.Showtime;
import utils.PricingCalculator;
import utils.SessionUtil;

import java.io.IOException;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.time.format.TextStyle;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

/**
 * FR-11 — Trang lịch chiếu công khai theo phim.
 * Phần thông tin phim (trên) và phần chọn suất (dưới) tách riêng JSP component.
 */
@WebServlet(urlPatterns = {"/showtimes"})
public class ShowtimesServlet extends HttpServlet {

    private static final int DATE_TAB_COUNT = 7;
    private static final DateTimeFormatter DATE_KEY_FMT = DateTimeFormatter.ISO_LOCAL_DATE;
    private static final Locale VI = Locale.forLanguageTag("vi");

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String movieId = req.getParameter("movieId");
        if (movieId == null || movieId.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/movies");
            return;
        }

        MovieDAO movieDAO = new MovieDAO();
        Movie movie = movieDAO.getById(movieId.trim());
        if (movie == null || "DELETED".equals(movie.getStatus())) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        ShowtimeDAO showtimeDAO = new ShowtimeDAO();
        try { showtimeDAO.autoSyncStatuses(); } catch (RuntimeException ignored) {}
        PricingRuleDAO pricingRuleDAO = new PricingRuleDAO();

        List<Showtime> showtimes = showtimeDAO.getUpcomingShowtimesByMovieId(movie.getId());
        List<PricingRule> pricingRules = pricingRuleDAO.getActiveRules();
        PricingCalculator.applyToShowtimes(showtimes, pricingRules);

        LocalDate today = LocalDate.now();
        List<String> dateKeys = new ArrayList<>();
        List<String> dateLabels = new ArrayList<>();
        for (int i = 0; i < DATE_TAB_COUNT; i++) {
            LocalDate date = today.plusDays(i);
            dateKeys.add(date.format(DATE_KEY_FMT));
            dateLabels.add(buildDateLabel(date, i));
        }

        Map<String, Map<String, List<Showtime>>> showtimeMap = buildShowtimeMap(showtimes, dateKeys);

        MovieReviewDAO reviewDAO = new MovieReviewDAO();
        final int reviewPageSize = 10;
        int movieReviewCount = reviewDAO.countByMovie(movie.getId());

        int reviewTotalPages = Math.max(1, (int) Math.ceil(movieReviewCount / (double) reviewPageSize));
        int reviewPage = 1;
        try {
            reviewPage = Integer.parseInt(req.getParameter("reviewPage"));
        } catch (Exception ignored) { /* default 1 */ }
        if (reviewPage < 1) reviewPage = 1;
        if (reviewPage > reviewTotalPages) reviewPage = reviewTotalPages;
        int reviewOffset = (reviewPage - 1) * reviewPageSize;

        List<MovieReview> movieReviews = reviewDAO.findByMovie(movie.getId(), reviewOffset, reviewPageSize);

        MovieReview myReview = null;
        boolean canReview = false;
        boolean reviewBanned = false;
        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser != null && "CUSTOMER".equals(SessionUtil.getUserRole(req))) {
            myReview = reviewDAO.findByMovieAndUser(movie.getId(), sessionUser.getId()).orElse(null);
            reviewBanned = reviewDAO.countDeletionsByUserAndMovie(sessionUser.getId(), movie.getId())
                    >= MovieReviewDAO.DELETION_BAN_THRESHOLD;
            canReview = !reviewBanned && new BookingDAO().hasWatchedMovie(sessionUser.getId(), movie.getId());
        }

        req.setAttribute("movie", movie);
        req.setAttribute("dateKeys", dateKeys);
        req.setAttribute("dateLabels", dateLabels);
        req.setAttribute("showtimeMap", showtimeMap);
        req.setAttribute("genreList", movieDAO.getAllGenres());
        req.setAttribute("similarMovies", movieDAO.getSimilarMovies(movie.getId(), 6));
        req.setAttribute("canReview", canReview);
        req.setAttribute("reviewBanned", reviewBanned);
        req.setAttribute("movieReviews", movieReviews);
        req.setAttribute("movieReviewCount", movieReviewCount);
        req.setAttribute("reviewPage", reviewPage);
        req.setAttribute("reviewTotalPages", reviewTotalPages);
        req.setAttribute("reviewPageSize", reviewPageSize);
        req.setAttribute("myReview", myReview);

        req.getRequestDispatcher("/WEB-INF/views/customer/showtimes.jsp").forward(req, resp);
    }

    private String buildDateLabel(LocalDate date, int offset) {
        if (offset == 0) return "Hôm nay";
        if (offset == 1) return "Ngày mai";
        String dayName = date.getDayOfWeek()
                .getDisplayName(TextStyle.SHORT, VI);
        if (dayName != null && !dayName.isBlank()) {
            return capitalize(dayName);
        }
        return date.format(DateTimeFormatter.ofPattern("EEE", VI));
    }

    private String capitalize(String text) {
        if (text == null || text.isEmpty()) return text;
        return Character.toUpperCase(text.charAt(0)) + text.substring(1);
    }

    private Map<String, Map<String, List<Showtime>>> buildShowtimeMap(
            List<Showtime> showtimes, List<String> dateKeys) {

        Map<String, Map<String, List<Showtime>>> map = new LinkedHashMap<>();
        for (String key : dateKeys) {
            map.put(key, new LinkedHashMap<>());
        }

        for (Showtime showtime : showtimes) {
            Timestamp start = showtime.getStartTime();
            if (start == null) continue;

            String dateKey = start.toLocalDateTime().toLocalDate().format(DATE_KEY_FMT);
            Map<String, List<Showtime>> rooms = map.get(dateKey);
            if (rooms == null) continue;

            String roomName = showtime.getRoomName() != null ? showtime.getRoomName() : "Phòng chiếu";
            rooms.computeIfAbsent(roomName, k -> new ArrayList<>()).add(showtime);
        }
        return map;
    }
}
