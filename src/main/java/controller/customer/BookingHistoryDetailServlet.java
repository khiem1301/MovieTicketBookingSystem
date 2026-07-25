package controller.customer;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import dal.BookingDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.BookingDetailDTO;
import model.dto.SessionUser;
import utils.BookingAccessUtil;
import utils.EmailUtil;
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

        // 1 QR / 1 đơn — cùng URL vé điện tử như email xác nhận
        if (detail.getTickets() != null && !detail.getTickets().isEmpty()) {
            String ticketUrl = resolveTicketViewUrl(req, detail.getBookingCode());
            req.setAttribute("eticketViewUrl", ticketUrl);
            req.setAttribute("eticketQrImageUrl", EmailUtil.buildQrImageUrl(ticketUrl));
        }

        req.setAttribute("detail", detail);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    /**
     * Ưu tiên app.base.url (giống email); fallback URL tuyệt đối từ request hiện tại.
     */
    private static String resolveTicketViewUrl(HttpServletRequest req, String bookingCode) {
        String fromConfig = EmailUtil.buildTicketViewUrl(bookingCode);
        if (fromConfig != null && fromConfig.startsWith("http")) {
            return fromConfig;
        }
        StringBuilder base = new StringBuilder();
        base.append(req.getScheme()).append("://").append(req.getServerName());
        int port = req.getServerPort();
        if (("http".equals(req.getScheme()) && port != 80)
                || ("https".equals(req.getScheme()) && port != 443)) {
            base.append(':').append(port);
        }
        base.append(req.getContextPath());
        String encoded = URLEncoder.encode(
                bookingCode != null ? bookingCode : "", StandardCharsets.UTF_8);
        return base + "/ticket?booking=" + encoded;
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
