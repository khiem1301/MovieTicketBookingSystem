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
 * FR-15 — Chi tiết đơn đã thanh toán thành công trong lịch sử (owner only).
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

        BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
        if (!BookingAccessUtil.isOwner(detail, sessionUser.getId())
                || !isCompletedPaid(detail)) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        req.setAttribute("detail", detail);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static boolean isCompletedPaid(BookingDetailDTO detail) {
        return detail != null
                && "CONFIRMED".equalsIgnoreCase(detail.getBookingStatus())
                && "PAID".equalsIgnoreCase(detail.getPaymentStatus());
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }
}
