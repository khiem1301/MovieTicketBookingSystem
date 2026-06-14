package controller.manager;

import dal.CinemaRoomDAO;
import dal.MovieDAO;
import dal.ShowtimeDAO;
import model.dto.SessionUser;
import model.entity.CinemaRoom;
import model.entity.Movie;
import model.entity.Showtime;
import utils.SessionUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@WebServlet("/manager/showtimes")
public class ManageShowtimeServlet extends HttpServlet {

    private static final Set<String> VALID_STATUSES = Set.of(
            "SCHEDULED", "OPEN", "SOLD_OUT", "CANCELLED", "FINISHED"
    );
    private static final DateTimeFormatter DT_LOCAL = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm");

    private final ShowtimeDAO showtimeDAO = new ShowtimeDAO();
    private final MovieDAO movieDAO = new MovieDAO();
    private final CinemaRoomDAO roomDAO = new CinemaRoomDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        if ("edit".equals(req.getParameter("action"))) {
            String id = req.getParameter("id");
            Showtime editing = (id != null) ? showtimeDAO.getShowtimeById(id) : null;
            if (editing != null) {
                req.setAttribute("editShowtime", editing);
                req.setAttribute("editBookingCount", showtimeDAO.countBookingsByShowtimeId(id));
            }
        }

        loadAndForward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        if ("update".equals(action)) {
            handleUpdate(req, resp);
        } else if ("delete".equals(action)) {
            handleDelete(req, resp);
        } else {
            handleCreate(req, resp);
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String movieId = trim(req.getParameter("movieId"));
        String roomId = trim(req.getParameter("roomId"));
        String startTimeStr = trim(req.getParameter("startTime"));
        String basePriceStr = trim(req.getParameter("basePrice"));

        ParsedForm parsed = parseAndValidate(null, movieId, roomId, startTimeStr, basePriceStr, "SCHEDULED", false);
        if (parsed.error != null) {
            forwardWithError(req, resp, parsed.error, movieId, roomId, startTimeStr, basePriceStr, null, null);
            return;
        }

        SessionUser user = SessionUtil.getLoggedUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/manager/showtimes");
            return;
        }

        showtimeDAO.create(parsed.showtime, user.getId());
        resp.sendRedirect(req.getContextPath() + "/manager/showtimes?success=created");
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = trim(req.getParameter("id"));
        Showtime existing = (id != null) ? showtimeDAO.getShowtimeById(id) : null;
        if (existing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/showtimes");
            return;
        }

        int bookingCount = showtimeDAO.countBookingsByShowtimeId(id);
        boolean locked = bookingCount > 0;

        String movieId = locked ? existing.getMovieId() : trim(req.getParameter("movieId"));
        String roomId = locked ? existing.getRoomId() : trim(req.getParameter("roomId"));
        String startTimeStr = locked ? formatDateTimeLocal(existing.getStartTime()) : trim(req.getParameter("startTime"));
        String basePriceStr = trim(req.getParameter("basePrice"));
        String status = trim(req.getParameter("status"));
        if (status == null || status.isBlank()) {
            status = existing.getStatus();
        }

        if (locked) {
            if (!same(trim(req.getParameter("movieId")), existing.getMovieId())
                    || !same(trim(req.getParameter("roomId")), existing.getRoomId())
                    || !same(trim(req.getParameter("startTime")), formatDateTimeLocal(existing.getStartTime()))) {
                forwardWithError(req, resp,
                        "Suất chiếu đã có " + bookingCount + " đơn đặt vé — không thể đổi phim, phòng hoặc giờ chiếu. Chỉ sửa giá vé hoặc trạng thái.",
                        existing.getMovieId(), existing.getRoomId(),
                        formatDateTimeLocal(existing.getStartTime()), basePriceStr, existing, bookingCount);
                return;
            }
        }

        ParsedForm parsed = parseAndValidate(id, movieId, roomId, startTimeStr, basePriceStr, status, true);
        if (parsed.error != null) {
            forwardWithError(req, resp, parsed.error, movieId, roomId, startTimeStr, basePriceStr, existing, bookingCount);
            return;
        }

        parsed.showtime.setId(id);
        showtimeDAO.update(parsed.showtime);
        resp.sendRedirect(req.getContextPath() + "/manager/showtimes?success=updated");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String id = trim(req.getParameter("id"));
        Showtime existing = (id != null) ? showtimeDAO.getShowtimeById(id) : null;
        if (existing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/showtimes");
            return;
        }

        int bookingCount = showtimeDAO.countBookingsByShowtimeId(id);
        if (bookingCount > 0) {
            resp.sendRedirect(req.getContextPath() + "/manager/showtimes?error=has_bookings");
            return;
        }

        showtimeDAO.delete(id);
        resp.sendRedirect(req.getContextPath() + "/manager/showtimes?success=deleted");
    }

    private ParsedForm parseAndValidate(String excludeId, String movieId, String roomId,
                                        String startTimeStr, String basePriceStr, String status,
                                        boolean skipFutureCheck) {
        ParsedForm result = new ParsedForm();

        if (movieId == null || movieId.isBlank()) {
            result.error = "Vui lòng chọn phim.";
            return result;
        }
        if (roomId == null || roomId.isBlank()) {
            result.error = "Vui lòng chọn phòng chiếu.";
            return result;
        }
        if (startTimeStr == null || startTimeStr.isBlank()) {
            result.error = "Vui lòng chọn giờ bắt đầu.";
            return result;
        }
        if (basePriceStr == null || basePriceStr.isBlank()) {
            result.error = "Vui lòng nhập giá vé cơ bản.";
            return result;
        }
        if (!VALID_STATUSES.contains(status)) {
            result.error = "Trạng thái suất chiếu không hợp lệ.";
            return result;
        }

        Movie movie = movieDAO.getById(movieId);
        if (movie == null || !isSchedulableStatus(movie.getStatus())) {
            result.error = "Phim không hợp lệ hoặc không thể xếp lịch.";
            return result;
        }

        CinemaRoom room = roomDAO.getById(roomId);
        if (room == null || !"ACTIVE".equals(room.getStatus())) {
            result.error = "Phòng chiếu không hợp lệ hoặc không đang hoạt động.";
            return result;
        }

        Timestamp startTime;
        try {
            LocalDateTime ldt = LocalDateTime.parse(startTimeStr, DT_LOCAL);
            startTime = Timestamp.valueOf(ldt);
        } catch (DateTimeParseException e) {
            result.error = "Giờ bắt đầu không hợp lệ.";
            return result;
        }

        if (!skipFutureCheck && startTime.before(new Timestamp(System.currentTimeMillis()))) {
            result.error = "Giờ bắt đầu phải ở tương lai.";
            return result;
        }

        BigDecimal basePrice;
        try {
            basePrice = new BigDecimal(basePriceStr.replace(",", "").trim());
            if (basePrice.compareTo(BigDecimal.ZERO) <= 0) {
                result.error = "Giá vé cơ bản phải lớn hơn 0.";
                return result;
            }
        } catch (NumberFormatException e) {
            result.error = "Giá vé không hợp lệ.";
            return result;
        }

        int duration = movie.getDurationMinutes();
        if (duration <= 0) {
            result.error = "Phim chưa có thời lượng hợp lệ.";
            return result;
        }

        Timestamp endTime = Timestamp.valueOf(startTime.toLocalDateTime().plusMinutes(duration));

        if (showtimeDAO.isOverlapping(roomId, startTime, endTime, excludeId)) {
            result.error = "Trùng lịch với suất chiếu khác trong cùng phòng chiếu.";
            return result;
        }

        Showtime s = new Showtime();
        s.setMovieId(movieId);
        s.setRoomId(roomId);
        s.setStartTime(startTime);
        s.setEndTime(endTime);
        s.setBasePrice(basePrice);
        s.setStatus(status);
        result.showtime = s;
        return result;
    }

    private void forwardWithError(HttpServletRequest req, HttpServletResponse resp, String error,
                                  String movieId, String roomId, String startTime, String basePrice,
                                  Showtime editShowtime, Integer bookingCount)
            throws ServletException, IOException {
        req.setAttribute("error", error);
        req.setAttribute("inputMovieId", movieId);
        req.setAttribute("inputRoomId", roomId);
        req.setAttribute("inputStartTime", startTime);
        req.setAttribute("inputBasePrice", basePrice);
        if (editShowtime != null) {
            req.setAttribute("editShowtime", editShowtime);
            req.setAttribute("editBookingCount", bookingCount != null ? bookingCount : 0);
        }
        loadAndForward(req, resp);
    }

    private void loadAndForward(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<Showtime> showtimeList = showtimeDAO.getAllForManager();
        req.setAttribute("showtimeList", showtimeList);
        req.setAttribute("movieList", movieDAO.getSchedulableMovies());
        req.setAttribute("roomList", roomDAO.getActiveRooms());

        Map<String, Integer> bookingCountMap = new HashMap<>();
        for (Showtime st : showtimeList) {
            bookingCountMap.put(st.getId(), showtimeDAO.countBookingsByShowtimeId(st.getId()));
        }
        req.setAttribute("bookingCountMap", bookingCountMap);

        req.getRequestDispatcher("/WEB-INF/views/manager/showtime-list.jsp").forward(req, resp);
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role) || "ADMIN".equals(role);
    }

    private boolean isSchedulableStatus(String status) {
        return "NOW_SHOWING".equals(status) || "COMING_SOON".equals(status);
    }

    private static String trim(String v) {
        return v == null ? null : v.trim();
    }

    private static boolean same(String a, String b) {
        if (a == null && b == null) return true;
        if (a == null || b == null) return false;
        return a.equals(b);
    }

    private static String formatDateTimeLocal(Timestamp ts) {
        if (ts == null) return "";
        return ts.toLocalDateTime().format(DT_LOCAL);
    }

    private static final class ParsedForm {
        String error;
        Showtime showtime;
    }
}
