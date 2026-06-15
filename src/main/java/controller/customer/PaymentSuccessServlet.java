package controller.customer;

import java.io.IOException;

import dal.BookingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.dto.BookingDetailDTO;
import model.dto.SessionUser;
import utils.SessionUtil;

/**
 * FR-17 — Trang xác nhận thanh toán thành công.
 */
@WebServlet("/payment/success")
public class PaymentSuccessServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/payment-success.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String bookingId = trim(req.getParameter("bookingId"));
        if (bookingId == null || bookingId.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/movies");
            return;
        }

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
        if (detail == null
                || detail.getUserId() == null
                || !detail.getUserId().equals(sessionUser.getId())
                || !"ONLINE".equals(detail.getBookingSource())
                || !"PAID".equals(detail.getPaymentStatus())) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        HttpSession session = req.getSession(false);
        if (session != null) {
            session.removeAttribute("checkoutDraft");
            session.removeAttribute("vietqrQrUrl");
            session.removeAttribute("vietqrTransferContent");
            session.removeAttribute("vietqrBookingId");
            session.removeAttribute("vietqrAmount");
        }

        req.setAttribute("detail", detail);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private static String trim(String v) {
        return v == null ? null : v.trim();
    }
}
