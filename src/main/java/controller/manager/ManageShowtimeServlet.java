package controller.manager;

import dal.BookingDAO;
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
import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@WebServlet("/manager/showtimes")
public class ManageShowtimeServlet extends HttpServlet {

    private static final Set<String> VALID_STATUSES = Set.of(
            "SCHEDULED", "SHOWING", "CANCELLED", "FINISHED"
    );
    private static final DateTimeFormatter DT_LOCAL = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm");
    private static final DateTimeFormatter TIME_HM = DateTimeFormatter.ofPattern("HH:mm");
    private static final int MAX_BASE_PRICE_DIGITS = 9;
    private static final BigDecimal MAX_BASE_PRICE = new BigDecimal("999999999");
    private static final int MAX_BULK_SLOTS = 12;

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
        } else if ("cancel".equals(action)) {
            handleCancel(req, resp);
        } else if ("bulkCreate".equals(action)) {
            handleBulkCreate(req, resp);
        } else if ("copyDay".equals(action)) {
            handleCopyDay(req, resp);
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
        // Trạng thái tự tính theo giờ chiếu (SCHEDULED / SHOWING / FINISHED)
        String status = "SCHEDULED";

        ParsedForm parsed = parseAndValidate(null, movieId, roomId, startTimeStr, basePriceStr, status, false);
        if (parsed.error != null) {
            forwardWithError(req, resp, parsed.error, movieId, roomId, startTimeStr, basePriceStr, status, null, null);
            return;
        }

        SessionUser user = SessionUtil.getLoggedUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/manager/showtimes");
            return;
        }

        parsed.showtime.setStatus(resolveAutoStatus(
                parsed.showtime.getStartTime(), parsed.showtime.getEndTime()));
        showtimeDAO.create(parsed.showtime, user.getId());
        resp.sendRedirect(req.getContextPath() + "/manager/showtimes?success=created");
    }

    private void handleBulkCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String movieId = trim(req.getParameter("movieId"));
        String roomId = trim(req.getParameter("roomId"));
        String dateStr = trim(req.getParameter("showDate"));
        String basePriceStr = trim(req.getParameter("basePrice"));
        String status = "SCHEDULED";
        String[] rawTimes = req.getParameterValues("startTimes");

        SessionUser user = SessionUtil.getLoggedUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/manager/showtimes");
            return;
        }

        List<String> times = normalizeTimes(rawTimes);
        if (times.isEmpty()) {
            forwardBulkError(req, resp, "Vui lòng thêm ít nhất một giờ chiếu.",
                    movieId, roomId, dateStr, basePriceStr, status);
            return;
        }
        if (times.size() > MAX_BULK_SLOTS) {
            forwardBulkError(req, resp, "Tối đa " + MAX_BULK_SLOTS + " suất mỗi lần tạo hàng loạt.",
                    movieId, roomId, dateStr, basePriceStr, status);
            return;
        }

        LocalDate showDate;
        try {
            showDate = LocalDate.parse(dateStr);
        } catch (Exception e) {
            forwardBulkError(req, resp, "Ngày chiếu không hợp lệ.",
                    movieId, roomId, dateStr, basePriceStr, status);
            return;
        }

        List<Showtime> toCreate = new ArrayList<>();
        for (String hm : times) {
            String startTimeStr = dateStr + "T" + hm;
            ParsedForm parsed = parseAndValidate(null, movieId, roomId, startTimeStr, basePriceStr, status, false);
            if (parsed.error != null) {
                forwardBulkError(req, resp, hm + " — " + parsed.error,
                        movieId, roomId, dateStr, basePriceStr, status);
                return;
            }
            // Kiểm tra trùng trong cùng batch (cùng phòng)
            for (Showtime other : toCreate) {
                if (overlapsLocal(parsed.showtime, other)) {
                    forwardBulkError(req, resp,
                            "Các giờ trong danh sách bị chồng lịch (kèm " + ShowtimeDAO.CLEANUP_BUFFER_MINUTES
                                    + " phút dọn phòng): " + hm,
                            movieId, roomId, dateStr, basePriceStr, status);
                    return;
                }
            }
            toCreate.add(parsed.showtime);
        }

        int created = showtimeDAO.createBatch(toCreate, user.getId());
        resp.sendRedirect(req.getContextPath() + "/manager/showtimes?success=bulk&count=" + created
                + "&date=" + showDate);
    }

    private void handleCopyDay(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String fromDateStr = trim(req.getParameter("fromDate"));
        String toDateStr = trim(req.getParameter("toDate"));
        String roomId = trim(req.getParameter("roomId"));
        String status = "SCHEDULED";

        SessionUser user = SessionUtil.getLoggedUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/manager/showtimes");
            return;
        }

        LocalDate fromDate;
        LocalDate toDate;
        try {
            fromDate = LocalDate.parse(fromDateStr);
            toDate = LocalDate.parse(toDateStr);
        } catch (Exception e) {
            redirectWithMessage(req, resp, "Ngày nguồn/đích không hợp lệ.");
            return;
        }

        if (toDate.isBefore(LocalDate.now())) {
            redirectWithMessage(req, resp, "Ngày đích phải từ hôm nay trở đi.");
            return;
        }
        if (fromDate.equals(toDate)) {
            redirectWithMessage(req, resp, "Ngày đích phải khác ngày nguồn.");
            return;
        }

        List<Showtime> source = showtimeDAO.getByDateForCopy(Date.valueOf(fromDate), roomId);
        if (source.isEmpty()) {
            redirectWithMessage(req, resp, "Không có suất chiếu nào để copy từ ngày đã chọn.");
            return;
        }

        long days = ChronoUnit.DAYS.between(fromDate, toDate);
        List<Showtime> toCreate = new ArrayList<>();
        List<String> skipped = new ArrayList<>();

        for (Showtime src : source) {
            LocalDateTime newStart = src.getStartTime().toLocalDateTime().plusDays(days);
            LocalDateTime newEnd = src.getEndTime().toLocalDateTime().plusDays(days);
            if (newStart.isBefore(LocalDateTime.now())) {
                skipped.add(src.getMovieTitle() + " " + newStart.toLocalTime().format(TIME_HM));
                continue;
            }
            Timestamp startTs = Timestamp.valueOf(newStart);
            Timestamp endTs = Timestamp.valueOf(newEnd);
            if (showtimeDAO.isOverlapping(src.getRoomId(), startTs, endTs, null)) {
                skipped.add(src.getMovieTitle() + " " + newStart.toLocalTime().format(TIME_HM) + " (trùng lịch)");
                continue;
            }
            Showtime copy = new Showtime();
            copy.setMovieId(src.getMovieId());
            copy.setRoomId(src.getRoomId());
            copy.setStartTime(startTs);
            copy.setEndTime(endTs);
            copy.setBasePrice(src.getBasePrice());
            copy.setStatus(resolveAutoStatus(startTs, endTs));
            toCreate.add(copy);
        }

        if (toCreate.isEmpty()) {
            redirectWithMessage(req, resp, "Không copy được suất nào."
                    + (skipped.isEmpty() ? "" : " Bỏ qua: " + String.join("; ", skipped)));
            return;
        }

        int created = showtimeDAO.createBatch(toCreate, user.getId());
        String msg = "Đã copy " + created + " suất sang " + toDate + ".";
        if (!skipped.isEmpty()) {
            msg += " Bỏ qua " + skipped.size() + " suất (trùng/quá giờ).";
        }
        resp.sendRedirect(req.getContextPath() + "/manager/showtimes?success=copied&count=" + created
                + "&date=" + toDate + "&msg=" + java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8));
    }

    private void handleCancel(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String id = trim(req.getParameter("id"));
        String reason = trim(req.getParameter("reason"));
        Showtime existing = (id != null) ? showtimeDAO.getShowtimeById(id) : null;
        if (existing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/showtimes");
            return;
        }

        // Chỉ hủy suất chưa chiếu (SCHEDULED). Đã bắt đầu / kết thúc thì ổn định — không hủy.
        String status = existing.getStatus();
        if ("CANCELLED".equals(status)) {
            redirectWithMessage(req, resp, "Suất chiếu này đã bị hủy trước đó.");
            return;
        }
        if ("SHOWING".equals(status) || "FINISHED".equals(status)
                || (existing.getStartTime() != null
                    && !existing.getStartTime().after(new Timestamp(System.currentTimeMillis())))) {
            redirectWithMessage(req, resp,
                    "Không thể hủy suất đã bắt đầu chiếu hoặc đã kết thúc.");
            return;
        }

        if (reason == null || reason.length() < 10) {
            redirectWithMessage(req, resp, "Lý do hủy phải có ít nhất 10 ký tự.");
            return;
        }
        if (reason.length() > 1000) {
            redirectWithMessage(req, resp, "Lý do hủy không được vượt quá 1000 ký tự.");
            return;
        }

        SessionUser manager = SessionUtil.getLoggedUser(req);
        if (manager == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/manager/showtimes");
            return;
        }

        try {
            List<model.dto.ShowtimeCancelBookingInfo> affected =
                    new BookingDAO().cancelShowtimeAndCompensate(
                            id, reason, manager.getId(), java.math.BigDecimal.ONE);

            String showLabel = "";
            if (existing.getStartTime() != null) {
                showLabel = new java.text.SimpleDateFormat("dd/MM/yyyy HH:mm")
                        .format(existing.getStartTime());
                if (existing.getRoomName() != null) {
                    showLabel += " · " + existing.getRoomName();
                }
            }
            utils.EmailUtil.sendShowtimeCancelledEmailsAsync(
                    existing.getMovieTitle() != null ? existing.getMovieTitle() : "Phim",
                    showLabel,
                    reason,
                    affected);

            int mailed = 0;
            int pointsTotal = 0;
            for (model.dto.ShowtimeCancelBookingInfo b : affected) {
                if (b.getEmail() != null && !b.getEmail().isBlank()) mailed++;
                pointsTotal += b.getPointsAwarded();
            }
            String msg = "Đã hủy suất chiếu. Đơn xác nhận: " + affected.size()
                    + " · Email dự kiến: " + mailed
                    + " · Tổng điểm hoàn: " + String.format("%,d", pointsTotal) + ".";
            resp.sendRedirect(req.getContextPath() + "/manager/showtimes?success=cancelled&msg="
                    + java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8));
        } catch (IllegalArgumentException | IllegalStateException ex) {
            redirectWithMessage(req, resp, ex.getMessage());
        } catch (RuntimeException ex) {
            log("handleCancel failed", ex);
            redirectWithMessage(req, resp, "Hủy suất thất bại: " + ex.getMessage());
        }
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
        boolean wasCancelled = "CANCELLED".equals(existing.getStatus());
        String statusForValidate = wasCancelled ? "CANCELLED" : "SCHEDULED";

        String existingStartLocal = formatDateTimeLocal(existing.getStartTime());
        if (locked) {
            if (!same(trim(req.getParameter("movieId")), existing.getMovieId())
                    || !same(trim(req.getParameter("roomId")), existing.getRoomId())
                    || !same(trim(req.getParameter("startTime")), existingStartLocal)) {
                forwardWithError(req, resp,
                        "Suất chiếu đã có " + bookingCount + " đơn đặt vé — không thể đổi phim, phòng hoặc giờ chiếu. Chỉ sửa giá vé.",
                        existing.getMovieId(), existing.getRoomId(),
                        existingStartLocal, basePriceStr, existing.getStatus(), existing, bookingCount);
                return;
            }
        }

        // Chỉ bỏ qua check "phải ở tương lai" khi giữ nguyên giờ chiếu cũ
        // (vd. chỉ sửa giá suất đã qua). Đổi giờ → không được về quá khứ.
        boolean startUnchanged = same(startTimeStr, existingStartLocal);
        ParsedForm parsed = parseAndValidate(id, movieId, roomId, startTimeStr, basePriceStr,
                statusForValidate, startUnchanged);
        if (parsed.error != null) {
            forwardWithError(req, resp, parsed.error, movieId, roomId, startTimeStr, basePriceStr,
                    existing.getStatus(), existing, bookingCount);
            return;
        }

        if (wasCancelled) {
            parsed.showtime.setStatus("CANCELLED");
        } else {
            parsed.showtime.setStatus(resolveAutoStatus(parsed.showtime.getStartTime(), parsed.showtime.getEndTime()));
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

        // Không cho đặt/đổi giờ chiếu về quá khứ (so sánh tới phút — form datetime-local không có giây).
        if (!skipFutureCheck) {
            LocalDateTime nowMinute = LocalDateTime.now().truncatedTo(ChronoUnit.MINUTES);
            LocalDateTime startMinute = startTime.toLocalDateTime().truncatedTo(ChronoUnit.MINUTES);
            if (!startMinute.isAfter(nowMinute)) {
                result.error = "Giờ bắt đầu phải ở tương lai (không được chọn thời điểm trong quá khứ).";
                return result;
            }
        }

        BigDecimal basePrice;
        try {
            basePrice = new BigDecimal(basePriceStr.replace(",", "").trim());
            if (basePrice.compareTo(BigDecimal.ZERO) <= 0) {
                result.error = "Giá vé cơ bản phải lớn hơn 0.";
                return result;
            }
            if (basePrice.compareTo(MAX_BASE_PRICE) > 0
                    || basePrice.toBigInteger().toString().length() > MAX_BASE_PRICE_DIGITS) {
                result.error = "Giá vé cơ bản không quá 9 chữ số.";
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
            result.error = "Trùng lịch với suất chiếu khác trong cùng phòng (đã tính "
                    + ShowtimeDAO.CLEANUP_BUFFER_MINUTES + " phút dọn phòng).";
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

    private boolean overlapsLocal(Showtime a, Showtime b) {
        int buffer = ShowtimeDAO.CLEANUP_BUFFER_MINUTES;
        LocalDateTime aStart = a.getStartTime().toLocalDateTime();
        LocalDateTime aEnd = a.getEndTime().toLocalDateTime().plusMinutes(buffer);
        LocalDateTime bStart = b.getStartTime().toLocalDateTime();
        LocalDateTime bEnd = b.getEndTime().toLocalDateTime().plusMinutes(buffer);
        return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
    }

    private void forwardWithError(HttpServletRequest req, HttpServletResponse resp, String error,
                                  String movieId, String roomId, String startTime, String basePrice,
                                  String status, Showtime editShowtime, Integer bookingCount)
            throws ServletException, IOException {
        req.setAttribute("error", error);
        req.setAttribute("inputMovieId", movieId);
        req.setAttribute("inputRoomId", roomId);
        req.setAttribute("inputStartTime", startTime);
        req.setAttribute("inputBasePrice", basePrice);
        req.setAttribute("inputStatus", status);
        if (editShowtime != null) {
            req.setAttribute("editShowtime", editShowtime);
            req.setAttribute("editBookingCount", bookingCount != null ? bookingCount : 0);
        }
        loadAndForward(req, resp);
    }

    private void forwardBulkError(HttpServletRequest req, HttpServletResponse resp, String error,
                                  String movieId, String roomId, String date, String basePrice, String status)
            throws ServletException, IOException {
        req.setAttribute("bulkError", error);
        req.setAttribute("openBulkModal", true);
        req.setAttribute("inputMovieId", movieId);
        req.setAttribute("inputRoomId", roomId);
        req.setAttribute("inputShowDate", date);
        req.setAttribute("inputBasePrice", basePrice);
        req.setAttribute("inputStatus", status);
        loadAndForward(req, resp);
    }

    private void redirectWithMessage(HttpServletRequest req, HttpServletResponse resp, String message) throws IOException {
        resp.sendRedirect(req.getContextPath() + "/manager/showtimes?error=msg&msg="
                + java.net.URLEncoder.encode(message, java.nio.charset.StandardCharsets.UTF_8));
    }

    private void loadAndForward(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            showtimeDAO.autoSyncStatuses();
        } catch (RuntimeException ex) {
            // Không chặn trang nếu auto-status lỗi (DB chưa migration / CHECK cũ)
            System.err.println("[ManageShowtimeServlet] autoSyncStatuses failed: " + ex.getMessage());
        }

        List<Showtime> showtimeList = showtimeDAO.getAllForManager();
        req.setAttribute("showtimeList", showtimeList);
        req.setAttribute("movieList", movieDAO.getSchedulableMovies());
        req.setAttribute("roomList", roomDAO.getActiveRooms());
        req.setAttribute("cleanupBufferMinutes", ShowtimeDAO.CLEANUP_BUFFER_MINUTES);
        req.setAttribute("today", LocalDate.now().toString());

        Map<String, Integer> bookingCountMap = new HashMap<>();
        for (Showtime st : showtimeList) {
            bookingCountMap.put(st.getId(), st.getBookingCount());
        }
        req.setAttribute("bookingCountMap", bookingCountMap);

        req.getRequestDispatcher("/WEB-INF/views/manager/showtime-list.jsp").forward(req, resp);
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role);
    }

    private boolean isSchedulableStatus(String status) {
        return "NOW_SHOWING".equals(status) || "COMING_SOON".equals(status);
    }

    private static String resolveAutoStatus(Timestamp startTime, Timestamp endTime) {
        if (startTime == null || endTime == null) {
            return "SCHEDULED";
        }
        Timestamp now = new Timestamp(System.currentTimeMillis());
        if (!endTime.after(now)) {
            return "FINISHED";
        }
        if (!startTime.after(now)) {
            return "SHOWING";
        }
        return "SCHEDULED";
    }

    private static List<String> normalizeTimes(String[] rawTimes) {
        LinkedHashSet<String> unique = new LinkedHashSet<>();
        if (rawTimes == null) return new ArrayList<>();
        for (String raw : rawTimes) {
            if (raw == null) continue;
            String t = raw.trim();
            if (t.isEmpty()) continue;
            try {
                LocalTime.parse(t, TIME_HM);
                unique.add(t);
            } catch (DateTimeParseException ignored) {
                // bỏ giờ sai định dạng
            }
        }
        return new ArrayList<>(unique);
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
