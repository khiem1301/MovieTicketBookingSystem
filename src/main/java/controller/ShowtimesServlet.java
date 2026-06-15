package controller;

import dal.MovieDAO;
import dal.PricingRuleDAO;
import dal.ShowtimeDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.Movie;
import model.entity.PricingRule;
import model.entity.Showtime;
import utils.PricingCalculator;

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

        req.setAttribute("movie", movie);
        req.setAttribute("dateKeys", dateKeys);
        req.setAttribute("dateLabels", dateLabels);
        req.setAttribute("showtimeMap", showtimeMap);
        req.setAttribute("genreList", movieDAO.getAllGenres());
        req.setAttribute("similarMovies", movieDAO.getSimilarMovies(movie.getId(), 6));

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
