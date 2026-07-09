package controller.customer;

import java.io.IOException;
import java.util.List;

import dal.BookingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.BookingHistoryItemDTO;
import model.dto.SessionUser;
import utils.AdminPaginationUtil;
import utils.SessionUtil;

/**
 * FR-15 — Lịch sử đặt vé của customer (lọc theo trạng thái + phân trang).
 */
@WebServlet("/booking-history")
public class BookingHistoryServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/booking-history.jsp";
    private static final int PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String statusFilter = trim(req.getParameter("status"));
        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));

        BookingDAO bookingDAO = new BookingDAO();
        String userId = sessionUser.getId();
        bookingDAO.expireStalePendingOnlineBookingsForUser(userId);

        int total = bookingDAO.countHistoryByUserId(userId, statusFilter);
        int totalPages = AdminPaginationUtil.totalPages(total, PAGE_SIZE);
        page = AdminPaginationUtil.clampPage(page, totalPages);

        List<BookingHistoryItemDTO> bookings = bookingDAO.findHistoryByUserId(
                userId,
                statusFilter,
                AdminPaginationUtil.offset(page, PAGE_SIZE),
                PAGE_SIZE);

        String basePath = req.getContextPath() + "/booking-history";
        req.setAttribute("bookings", bookings);
        req.setAttribute("currentStatus", statusFilter != null ? statusFilter.trim() : "");
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("totalBookings", total);
        req.setAttribute("pgCurrent", page);
        req.setAttribute("pgTotal", totalPages);
        req.setAttribute("pgTotalItems", total);
        req.setAttribute("pgPath", basePath);
        req.setAttribute("pgQueryExtra", AdminPaginationUtil.queryParam("status", statusFilter));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }
}
