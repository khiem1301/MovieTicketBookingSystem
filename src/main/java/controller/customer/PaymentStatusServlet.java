package controller.customer;

import java.io.IOException;
import java.io.PrintWriter;

import dal.BookingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.SessionUser;
import model.entity.Booking;
import utils.SessionUtil;

/**
 * FR-16 — Poll trạng thái thanh toán (JSON) cho trang payment.
 */
@WebServlet("/payment/status")
public class PaymentStatusServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        SessionUser user = SessionUtil.getLoggedUser(req);
        if (user == null) {
            resp.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        String bookingId = trim(req.getParameter("bookingId"));
        if (bookingId == null || bookingId.isBlank()) {
            resp.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            return;
        }

        Booking booking = new BookingDAO().getById(bookingId);
        if (booking == null
                || booking.getUserId() == null
                || !booking.getUserId().equals(user.getId())) {
            resp.setStatus(HttpServletResponse.SC_NOT_FOUND);
            return;
        }

        boolean paid = "PAID".equals(booking.getPaymentStatus())
                && "CONFIRMED".equals(booking.getBookingStatus());
        boolean pending = "PENDING".equals(booking.getBookingStatus())
                && "UNPAID".equals(booking.getPaymentStatus());

        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        try (PrintWriter out = resp.getWriter()) {
            out.print("{\"paid\":");
            out.print(paid);
            out.print(",\"pending\":");
            out.print(pending);
            if (paid) {
                out.print(",\"successUrl\":\"");
                out.print(req.getContextPath());
                out.print("/payment/success?bookingId=");
                out.print(escapeJson(bookingId));
                out.print("\"");
            }
            out.print("}");
        }
    }

    private static String escapeJson(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String trim(String v) {
        return v == null ? null : v.trim();
    }
}
