package controller.customer;

import java.io.IOException;
import java.sql.Timestamp;

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
        BookingDetailDTO detail = bookingDAO.getDetailById(bookingId);
        if (!BookingAccessUtil.isOwner(detail, sessionUser.getId())) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        // PENDING quá expired_at → EXPIRED rồi load lại chi tiết
        if (detail != null
                && "PENDING".equalsIgnoreCase(detail.getBookingStatus())
                && detail.getExpiredAt() != null
                && detail.getExpiredAt().before(new Timestamp(System.currentTimeMillis()))) {
            if (bookingDAO.expireOnlinePendingBooking(bookingId, sessionUser.getId())) {
                detail = bookingDAO.getDetailById(bookingId);
            }
        }

        req.setAttribute("detail", detail);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }
}
