package controller.staff;

import dal.BookingDAO;
import dal.SeatDAO;
import dal.ShowtimeDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.BookingDetailDTO;
import model.entity.Seat;
import model.entity.Showtime;
import model.dto.SessionUser;
import org.json.JSONArray;
import org.json.JSONObject;
import utils.SessionUtil;

import java.io.IOException;
import java.math.BigDecimal;
import java.text.SimpleDateFormat;
import java.util.*;

/**
 * FR-35 / FR-36 / FR-37 / FR-38 — Quầy bán vé (POS terminal).
 *
 * GET  /staff/counter                            → Trang POS chính (3 panel)
 * GET  /staff/counter?action=showtimes&movieId=X → JSON: suất chiếu theo phim
 * GET  /staff/counter?action=seats&showtimeId=X  → JSON: sơ đồ ghế
 * GET  /staff/counter?step=payment&bookingId=X   → Trang thanh toán
 * GET  /staff/counter?step=print&bookingId=X     → Trang in vé
 * POST /staff/counter                            → Tạo booking → redirect payment
 * POST /staff/counter?action=payment             → Xác nhận thanh toán → redirect print
 */
@WebServlet("/staff/counter")
public class CounterBookingServlet extends HttpServlet {

    private static final String VIEW_MAIN    = "/WEB-INF/views/staff/counter-booking.jsp";
    private static final String VIEW_PAYMENT = "/WEB-INF/views/staff/counter-payment.jsp";
    private static final String VIEW_PRINT   = "/WEB-INF/views/staff/counter-print.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isStaff(req)) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/staff/counter");
            return;
        }

        String action     = req.getParameter("action");
        String step       = req.getParameter("step");
        String movieId    = req.getParameter("movieId");
        String showtimeId = req.getParameter("showtimeId");
        String bookingId  = req.getParameter("bookingId");

        // ── JSON API endpoints ────────────────────────────────────
        if ("showtimes".equals(action) && movieId != null) {
            serveShowtimesJson(req, resp, movieId);
            return;
        }
        if ("seats".equals(action) && showtimeId != null) {
            serveSeatsJson(req, resp, showtimeId);
            return;
        }

        // ── Page steps ────────────────────────────────────────────
        try {
            if ("payment".equals(step) && bookingId != null && !bookingId.isBlank()) {
                BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
                if (detail == null) {
                    req.setAttribute("errorMessage", "Không tìm thấy đơn đặt vé.");
                    loadMainPage(req);
                    req.getRequestDispatcher(VIEW_MAIN).forward(req, resp);
                    return;
                }
                req.setAttribute("detail", detail);
                req.getRequestDispatcher(VIEW_PAYMENT).forward(req, resp);

            } else if ("print".equals(step) && bookingId != null && !bookingId.isBlank()) {
                BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
                if (detail == null) {
                    req.setAttribute("errorMessage", "Không tìm thấy đơn đặt vé.");
                    loadMainPage(req);
                    req.getRequestDispatcher(VIEW_MAIN).forward(req, resp);
                    return;
                }
                req.setAttribute("detail", detail);
                req.getRequestDispatcher(VIEW_PRINT).forward(req, resp);

            } else {
                loadMainPage(req);
                req.getRequestDispatcher(VIEW_MAIN).forward(req, resp);
            }
        } catch (RuntimeException e) {
            log("CounterBookingServlet GET error", e);
            req.setAttribute("errorMessage", "Lỗi hệ thống: " + e.getMessage());
            req.setAttribute("movies", List.of());
            req.getRequestDispatcher(VIEW_MAIN).forward(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isStaff(req)) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }
        req.setCharacterEncoding("UTF-8");

        String action = req.getParameter("action");

        if ("payment".equals(action)) {
            handlePayment(req, resp);
        } else {
            handleCreateBooking(req, resp);
        }
    }

    // ── Helpers: page loaders ─────────────────────────────────────

    private void loadMainPage(HttpServletRequest req) {
        req.setAttribute("movies", new ShowtimeDAO().getMoviesWithActiveShowtimes());
    }

    // ── Helpers: JSON API ─────────────────────────────────────────

    private void serveShowtimesJson(HttpServletRequest req, HttpServletResponse resp,
                                    String movieId) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        try {
            List<Showtime> list = new ShowtimeDAO().getShowtimesByMovieId(movieId);
            JSONArray arr = new JSONArray();
            SimpleDateFormat dateFmt = new SimpleDateFormat("yyyy-MM-dd");
            SimpleDateFormat timeFmt = new SimpleDateFormat("HH:mm");
            for (Showtime st : list) {
                JSONObject o = new JSONObject();
                o.put("id",        st.getId());
                o.put("roomName",  st.getRoomName());
                o.put("basePrice", st.getBasePrice());
                o.put("status",    st.getStatus());
                if (st.getStartTime() != null) {
                    o.put("date", dateFmt.format(st.getStartTime()));
                    o.put("time", timeFmt.format(st.getStartTime()));
                    o.put("startTs", st.getStartTime().getTime());
                }
                arr.put(o);
            }
            resp.getWriter().write(arr.toString());
        } catch (RuntimeException e) {
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private void serveSeatsJson(HttpServletRequest req, HttpServletResponse resp,
                                String showtimeId) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        try {
            List<Seat> seats = new SeatDAO().getSeatsForShowtime(showtimeId);
            Map<String, List<Seat>> byRow = groupByRow(seats);

            JSONArray rows = new JSONArray();
            for (Map.Entry<String, List<Seat>> entry : byRow.entrySet()) {
                JSONObject row = new JSONObject();
                row.put("rowName", entry.getKey());
                JSONArray seatsArr = new JSONArray();
                for (Seat s : entry.getValue()) {
                    JSONObject so = new JSONObject();
                    so.put("id",          s.getId());
                    so.put("seatCode",    s.getSeatCode());
                    so.put("seatColumn",  s.getSeatColumn());
                    so.put("typeName",    s.getSeatTypeName() == null ? "STANDARD" : s.getSeatTypeName());
                    so.put("ticketPrice", s.getTicketPrice() == null ? BigDecimal.ZERO : s.getTicketPrice());
                    so.put("available",   s.isAvailable());
                    seatsArr.put(so);
                }
                row.put("seats", seatsArr);
                rows.put(row);
            }
            resp.getWriter().write(rows.toString());
        } catch (RuntimeException e) {
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    // ── Helpers: POST handlers ────────────────────────────────────

    private void handleCreateBooking(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String showtimeId    = req.getParameter("showtimeId");
        String customerName  = trim(req.getParameter("customerName"));
        String customerPhone = trim(req.getParameter("customerPhone"));
        String[] rawSeatIds  = req.getParameterValues("seatIds");
        String[] rawPrices   = req.getParameterValues("seatPrices");

        if (isBlank(showtimeId)) { forwardError(req, resp, "Thiếu thông tin suất chiếu."); return; }
        if (isBlank(customerName))  { forwardError(req, resp, "Vui lòng nhập tên khách hàng."); return; }
        if (isBlank(customerPhone)) { forwardError(req, resp, "Vui lòng nhập số điện thoại."); return; }
        if (rawSeatIds == null || rawSeatIds.length == 0) {
            forwardError(req, resp, "Vui lòng chọn ít nhất một ghế."); return;
        }

        List<String> seatIds = Arrays.asList(rawSeatIds);
        List<BigDecimal> seatPrices = new ArrayList<>();
        try {
            for (String p : rawPrices) seatPrices.add(new BigDecimal(p));
        } catch (NumberFormatException e) {
            forwardError(req, resp, "Dữ liệu giá ghế không hợp lệ."); return;
        }

        SessionUser staff = SessionUtil.getLoggedUser(req);
        try {
            String bookingId = new BookingDAO().createOfflineBooking(
                    showtimeId, staff.getId(), null, customerName, customerPhone,
                    seatIds, seatPrices);
            resp.sendRedirect(req.getContextPath()
                    + "/staff/counter?step=payment&bookingId=" + bookingId);
        } catch (RuntimeException e) {
            log("CounterBookingServlet POST create error", e);
            forwardError(req, resp, "Tạo đơn thất bại: " + e.getMessage());
        }
    }

    private void handlePayment(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String bookingId = req.getParameter("bookingId");
        if (isBlank(bookingId)) {
            forwardError(req, resp, "Thiếu bookingId."); return;
        }
        try {
            new BookingDAO().confirmPayment(bookingId);
            resp.sendRedirect(req.getContextPath()
                    + "/staff/counter?step=print&bookingId=" + bookingId);
        } catch (RuntimeException e) {
            log("CounterBookingServlet POST payment error", e);
            req.setAttribute("errorMessage", "Xác nhận thanh toán thất bại: " + e.getMessage());
            req.setAttribute("detail", new BookingDAO().getDetailById(bookingId));
            req.getRequestDispatcher(VIEW_PAYMENT).forward(req, resp);
        }
    }

    private void forwardError(HttpServletRequest req, HttpServletResponse resp, String msg)
            throws ServletException, IOException {
        req.setAttribute("errorMessage", msg);
        loadMainPage(req);
        req.getRequestDispatcher(VIEW_MAIN).forward(req, resp);
    }

    // ── Utilities ─────────────────────────────────────────────────

    private boolean isStaff(HttpServletRequest req) {
        return "STAFF".equals(SessionUtil.getUserRole(req));
    }

    private boolean isBlank(String s) { return s == null || s.isBlank(); }

    private String trim(String v) { return v == null ? null : v.trim(); }

    private Map<String, List<Seat>> groupByRow(List<Seat> seats) {
        Map<String, List<Seat>> map = new LinkedHashMap<>();
        for (Seat s : seats) {
            map.computeIfAbsent(s.getSeatRow(), k -> new ArrayList<>()).add(s);
        }
        return map;
    }
}
