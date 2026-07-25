package controller.staff;

import dal.BookingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.OfflineBookingDTO;
import utils.SessionUtil;

import java.io.IOException;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.util.List;

/**
 * Sprint 3 — FR-39: Lịch sử đặt vé tại quầy (OFFLINE).
 *
 * GET /staff/history                  → Danh sách tất cả booking OFFLINE
 * GET /staff/history?bookingId=X      → Chi tiết 1 booking (reuse counter-print view)
 */
@WebServlet("/staff/history")
public class CounterHistoryServlet extends HttpServlet {

    private static final int PAGE_SIZE = 15;

    private static final String VIEW_LIST   = "/WEB-INF/views/staff/counter-history.jsp";
    private static final String VIEW_DETAIL = "/WEB-INF/views/staff/counter-print.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!isStaff(req)) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/staff/history");
            return;
        }

        String bookingId = req.getParameter("bookingId");

        // ── Chi tiết 1 booking ───────────────────────────────────────────
        if (bookingId != null && !bookingId.isBlank()) {
            try {
                var detail = new BookingDAO().getDetailById(bookingId);
                if (detail == null) {
                    req.setAttribute("errorMessage", "Không tìm thấy đơn đặt vé.");
                    forwardList(req, resp, "", "", "", "", 1);
                    return;
                }
                // PENDING/UNPAID → chuyển về màn thanh toán để hoàn tất
                if ("PENDING".equals(detail.getBookingStatus())
                        && "UNPAID".equals(detail.getPaymentStatus())) {
                    resp.sendRedirect(req.getContextPath()
                            + "/staff/counter?step=payment&bookingId=" + bookingId);
                    return;
                }
                // Chỉ đơn đã xác nhận (+ đã thanh toán) mới xem / in vé
                if (!"CONFIRMED".equalsIgnoreCase(detail.getBookingStatus())
                        || !"PAID".equalsIgnoreCase(detail.getPaymentStatus())) {
                    req.setAttribute("errorMessage",
                            "Chỉ xem được đơn đã xác nhận và thanh toán. "
                                    + "Đơn hủy / hết hạn / chưa thanh toán không có vé để xem hoặc in.");
                    forwardList(req, resp,
                            trim(req.getParameter("dateFrom")),
                            trim(req.getParameter("dateTo")),
                            trim(req.getParameter("status")),
                            trim(req.getParameter("search")),
                            parsePage(req.getParameter("page")));
                    return;
                }
                req.setAttribute("detail", detail);
                req.setAttribute("fromHistory", true);
                req.getRequestDispatcher(VIEW_DETAIL).forward(req, resp);
            } catch (RuntimeException e) {
                log("CounterHistoryServlet detail error", e);
                req.setAttribute("errorMessage", "Lỗi tải chi tiết: " + e.getMessage());
                forwardList(req, resp, "", "", "", "", 1);
            }
            return;
        }

        // ── Danh sách + filter ────────────────────────────────────────────
        String dateFrom = trim(req.getParameter("dateFrom"));
        String dateTo   = trim(req.getParameter("dateTo"));
        String status   = trim(req.getParameter("status"));
        String search   = trim(req.getParameter("search"));
        int page = parsePage(req.getParameter("page"));

        forwardList(req, resp, dateFrom, dateTo, status, search, page);
    }

    private void forwardList(HttpServletRequest req, HttpServletResponse resp,
                             String dateFrom, String dateTo, String status, String search, int page)
            throws ServletException, IOException {
        try {
            BookingDAO dao = new BookingDAO();
            int total = dao.countOfflineBookings(dateFrom, dateTo, status, search);
            int totalPages = Math.max(1, (int) Math.ceil((double) total / PAGE_SIZE));
            if (page > totalPages) page = totalPages;

            List<OfflineBookingDTO> bookings =
                    dao.getOfflineBookings(dateFrom, dateTo, status, search, page, PAGE_SIZE);

            req.setAttribute("bookings",   bookings);
            req.setAttribute("totalCount", total);
            req.setAttribute("page",       page);
            req.setAttribute("totalPages", totalPages);
            req.setAttribute("dateFrom",   dateFrom);
            req.setAttribute("dateTo",     dateTo);
            req.setAttribute("status",     status);
            req.setAttribute("search",     search);

            // Quick-filter date strings for JSP
            LocalDate today = LocalDate.now();
            req.setAttribute("todayStr",    today.toString());
            req.setAttribute("weekStart",   today.with(DayOfWeek.MONDAY).toString());
            req.setAttribute("weekEnd",     today.with(DayOfWeek.SUNDAY).toString());
            req.setAttribute("monthStart",  today.withDayOfMonth(1).toString());
            req.setAttribute("monthEnd",    today.withDayOfMonth(today.lengthOfMonth()).toString());

            req.getRequestDispatcher(VIEW_LIST).forward(req, resp);
        } catch (RuntimeException e) {
            log("CounterHistoryServlet list error", e);
            req.setAttribute("errorMessage", "Lỗi tải danh sách: " + e.getMessage());
            req.setAttribute("bookings", List.of());
            req.setAttribute("totalCount", 0);
            req.setAttribute("page", 1);
            req.setAttribute("totalPages", 1);
            req.getRequestDispatcher(VIEW_LIST).forward(req, resp);
        }
    }

    private boolean isStaff(HttpServletRequest req) {
        return "STAFF".equals(SessionUtil.getUserRole(req));
    }

    private String trim(String s) { return s == null ? "" : s.trim(); }

    private int parsePage(String s) {
        try { int p = Integer.parseInt(s); return p > 0 ? p : 1; }
        catch (Exception e) { return 1; }
    }
}
