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
import utils.SessionUtil;

/**
 * FR-17 / FR-19 — Vé điện tử: chỉ chủ đơn (đã đăng nhập) mới xem được.
 * Query: /ticket?booking={bookingCode}
 */
@WebServlet("/ticket")
public class ETicketServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/e-ticket.jsp";
    private static final String VIEW_NOT_FOUND = "/WEB-INF/views/customer/e-ticket-not-found.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            // AuthFilter thường chặn trước; giữ fallback an toàn
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String bookingCode = req.getParameter("booking");
        if (bookingCode == null || bookingCode.isBlank()) {
            // Tương thích link cũ ?code=… nếu còn trong email đã gửi
            bookingCode = req.getParameter("code");
        }
        if (bookingCode == null || bookingCode.isBlank()) {
            forwardNotFound(req, resp);
            return;
        }

        BookingDetailDTO detail = new BookingDAO().getPaidDetailByBookingCode(bookingCode.trim());
        if (detail == null
                || detail.getUserId() == null
                || !detail.getUserId().equals(sessionUser.getId())) {
            // Không tiết lộ vé tồn tại nhưng thuộc người khác
            forwardNotFound(req, resp);
            return;
        }

        req.setAttribute("detail", detail);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static void forwardNotFound(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
        req.getRequestDispatcher(VIEW_NOT_FOUND).forward(req, resp);
    }
}
