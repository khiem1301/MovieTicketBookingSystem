package controller.customer;

import java.io.IOException;
import java.util.List;

import dal.BookingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.BookingSummaryDTO;
import model.dto.SessionUser;
import utils.SessionUtil;

/**
 * FR-15 — Lịch sử đặt vé tại /booking-history (CUSTOMER, ONLINE + OFFLINE).
 */
@WebServlet("/booking-history")
public class BookingHistoryServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/booking-history.jsp";
    private static final int PAGE_SIZE = 8;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/booking-history");
            return;
        }

        String status = trim(req.getParameter("status"));
        if (!BookingDAO.isValidSummaryStatusFilter(status)) {
            status = "ALL";
        }

        String searchQuery = trim(req.getParameter("q"));
        if (searchQuery != null && searchQuery.length() > 100) {
            searchQuery = searchQuery.substring(0, 100);
        }
        if (searchQuery != null && searchQuery.isEmpty()) {
            searchQuery = null;
        }

        int page = parsePage(req.getParameter("page"));
        int offset = (page - 1) * PAGE_SIZE;

        BookingDAO bookingDAO = new BookingDAO();
        String userId = sessionUser.getId();
        int totalCount = bookingDAO.countByUserId(userId, status, searchQuery);
        List<BookingSummaryDTO> bookings =
                bookingDAO.findSummariesByUserId(userId, status, searchQuery, offset, PAGE_SIZE);

        int totalPages = totalCount == 0 ? 0 : (int) Math.ceil((double) totalCount / PAGE_SIZE);

        req.setAttribute("bookings", bookings);
        req.setAttribute("activeStatus", status);
        req.setAttribute("searchQuery", searchQuery != null ? searchQuery : "");
        req.setAttribute("currentPage", page);
        req.setAttribute("totalCount", totalCount);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("hasMore", page < totalPages);
        req.setAttribute("pageSize", PAGE_SIZE);

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static int parsePage(String raw) {
        if (raw == null || raw.isBlank()) {
            return 1;
        }
        try {
            int page = Integer.parseInt(raw.trim());
            return Math.max(1, page);
        } catch (NumberFormatException e) {
            return 1;
        }
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }
}
