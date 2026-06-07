package controller.staff;

import dal.BookingDAO;
import dal.SeatDAO;
import dal.ShowtimeDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.Seat;
import model.entity.Showtime;
import model.dto.SessionUser;
import utils.SessionUtil;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.*;

/**
 * FR-35 — Counter Ticket Booking: Quầy bán vé cho staff.
 * FR-38 — Walk-in Customer Support: Hỗ trợ đặt vé cho khách vãng lai (không cần tài khoản).
 *
 * Luồng 3 bước:
 *   GET /staff/counter              → Bước 1: chọn phim
 *   GET /staff/counter?step=showtime&movieId=X → Bước 2: chọn suất chiếu
 *   GET /staff/counter?step=seat&showtimeId=X  → Bước 3: chọn ghế + thông tin khách
 *   POST /staff/counter             → Tạo booking OFFLINE → redirect xác nhận
 */
@WebServlet("/staff/counter")
public class CounterBookingServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/staff/counter-booking.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isStaff(req)) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/staff/counter");
            return;
        }

        String step      = req.getParameter("step");
        String movieId   = req.getParameter("movieId");
        String showtimeId = req.getParameter("showtimeId");

        ShowtimeDAO showtimeDAO = new ShowtimeDAO();

        String bookingId = req.getParameter("bookingId");

        try {
            if ("confirm".equals(step) && bookingId != null && !bookingId.isBlank()) {
                // Bước 4: hiển thị xác nhận đơn vừa tạo
                req.setAttribute("booking", new BookingDAO().getById(bookingId));
                req.setAttribute("step", "confirm");

            } else if ("showtime".equals(step) && movieId != null && !movieId.isBlank()) {
                // Bước 2: danh sách suất chiếu theo phim
                List<Showtime> showtimes = showtimeDAO.getShowtimesByMovieId(movieId);
                req.setAttribute("showtimes", showtimes);
                req.setAttribute("selectedMovieId", movieId);
                req.setAttribute("step", "showtime");

            } else if ("seat".equals(step) && showtimeId != null && !showtimeId.isBlank()) {
                // Bước 3: sơ đồ ghế + form thông tin khách
                Showtime showtime = showtimeDAO.getShowtimeById(showtimeId);
                if (showtime == null) {
                    req.setAttribute("errorMessage", "Không tìm thấy suất chiếu.");
                    req.setAttribute("step", "movie");
                    req.setAttribute("movies", showtimeDAO.getMoviesWithActiveShowtimes());
                } else {
                    List<Seat> seats = new SeatDAO().getSeatsForShowtime(showtimeId);
                    req.setAttribute("showtime", showtime);
                    req.setAttribute("seatsByRow", groupByRow(seats));
                    req.setAttribute("step", "seat");
                }

            } else {
                // Bước 1: danh sách phim
                req.setAttribute("movies", showtimeDAO.getMoviesWithActiveShowtimes());
                req.setAttribute("step", "movie");
            }
        } catch (RuntimeException e) {
            log("CounterBookingServlet: DB error", e);
            req.setAttribute("errorMessage", "Lỗi hệ thống, vui lòng thử lại.");
            req.setAttribute("step", "movie");
            req.setAttribute("movies", List.of());
        }

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isStaff(req)) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        req.setCharacterEncoding("UTF-8");

        String showtimeId    = req.getParameter("showtimeId");
        String customerName  = trim(req.getParameter("customerName"));
        String customerPhone = trim(req.getParameter("customerPhone"));
        String[] rawSeatIds  = req.getParameterValues("seatIds");
        String[] rawPrices   = req.getParameterValues("seatPrices");
        boolean isWalkIn     = "walkin".equals(req.getParameter("customerType"));

        // Validate
        if (showtimeId == null || showtimeId.isBlank()) {
            forwardError(req, resp, "Thiếu thông tin suất chiếu.");
            return;
        }
        if (customerName == null || customerName.isBlank()) {
            forwardError(req, resp, "Vui lòng nhập tên khách hàng.");
            return;
        }
        if (customerPhone == null || customerPhone.isBlank()) {
            forwardError(req, resp, "Vui lòng nhập số điện thoại khách hàng.");
            return;
        }
        if (rawSeatIds == null || rawSeatIds.length == 0) {
            forwardError(req, resp, "Vui lòng chọn ít nhất một ghế.");
            return;
        }

        List<String> seatIds = Arrays.asList(rawSeatIds);
        List<BigDecimal> seatPrices = new ArrayList<>();
        try {
            for (String p : rawPrices) seatPrices.add(new BigDecimal(p));
        } catch (NumberFormatException e) {
            forwardError(req, resp, "Dữ liệu giá ghế không hợp lệ.");
            return;
        }

        SessionUser staff = SessionUtil.getLoggedUser(req);
        // FR-38: walk-in → userId = null; có tài khoản → SP2 sẽ tra cứu theo SĐT
        String userId = isWalkIn ? null : null;  // SP2 (FR-42): tra cứu member theo phone

        try {
            BookingDAO bookingDAO = new BookingDAO();
            String bookingId = bookingDAO.createOfflineBooking(
                    showtimeId, staff.getId(), userId, customerName, customerPhone,
                    seatIds, seatPrices);

            resp.sendRedirect(req.getContextPath()
                    + "/staff/counter?step=confirm&bookingId=" + bookingId);

        } catch (RuntimeException e) {
            log("CounterBookingServlet POST: DB error", e);
            forwardError(req, resp, "Tạo đơn thất bại, vui lòng thử lại.");
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private boolean isStaff(HttpServletRequest req) {
        return "STAFF".equals(SessionUtil.getUserRole(req));
    }

    private void forwardError(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws ServletException, IOException {
        req.setAttribute("errorMessage", msg);
        req.setAttribute("step", "movie");
        req.setAttribute("movies", List.of());
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }

    /** Nhóm danh sách ghế theo hàng (key = seat_row), giữ nguyên thứ tự hàng. */
    private Map<String, List<Seat>> groupByRow(List<Seat> seats) {
        Map<String, List<Seat>> map = new LinkedHashMap<>();
        for (Seat s : seats) {
            map.computeIfAbsent(s.getSeatRow(), k -> new ArrayList<>()).add(s);
        }
        return map;
    }
}
