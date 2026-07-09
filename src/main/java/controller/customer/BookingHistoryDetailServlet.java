package controller.customer;

import java.io.IOException;

import dal.BookingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.BookingDetailDTO;
import model.dto.SessionUser;
import utils.BookingAccessUtil;
import utils.SessionUtil;

/**
 * FR-15 — Chi tiết một đơn trong lịch sử đặt vé (owner only).
 */
@WebServlet("/booking-history/detail")
public class BookingHistoryDetailServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/booking-history-detail.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String bookingId = trim(req.getParameter("bookingId"));
        if (bookingId == null || bookingId.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/booking-history");
            return;
        }

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        BookingDAO bookingDAO = new BookingDAO();
        bookingDAO.expireStalePendingOnlineBooking(bookingId, sessionUser.getId());

        BookingDetailDTO detail = bookingDAO.getDetailById(bookingId);
        if (!BookingAccessUtil.isOwner(detail, sessionUser.getId())) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        req.setAttribute("detail", detail);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }
}
