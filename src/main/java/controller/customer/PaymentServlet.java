package controller.customer;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;

import dal.BookingDAO;
import dal.PromotionDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.dto.BookingDetailDTO;
import model.dto.SessionUser;
import model.entity.Promotion;
import utils.PromotionCalculator;
import utils.SessionUtil;

/**
 * FR-14 / FR-16 stub / FR-22 — Trang thanh toán online tại /payment?bookingId=
 * GET  → tóm tắt đơn + countdown hết hạn
 * POST action=cancel → hủy đơn PENDING, giải phóng ghế
 * POST action=applyPromo → áp mã voucher (FR-22)
 * POST action=removePromo → gỡ mã voucher (FR-22)
 * POST (khác) → stub VNPay/MoMo (FR-16–18)
 */
@WebServlet("/payment")
public class PaymentServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/payment.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String bookingId = trim(req.getParameter("bookingId"));
        if (isBlank(bookingId)) {
            resp.sendRedirect(req.getContextPath() + "/movies");
            return;
        }

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        forwardPayment(req, resp, bookingId, sessionUser.getId(), null, null);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String bookingId = trim(req.getParameter("bookingId"));
        String action = trim(req.getParameter("action"));

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        if (isBlank(bookingId)) {
            resp.sendRedirect(req.getContextPath() + "/movies");
            return;
        }

        BookingDAO bookingDAO = new BookingDAO();
        BookingDetailDTO detail = bookingDAO.getDetailById(bookingId);

        if ("cancel".equals(action)) {
            handleCancel(req, resp, bookingDAO, detail, bookingId, sessionUser.getId());
            return;
        }

        String guardError = validateAccess(detail, sessionUser.getId());
        if (guardError != null) {
            handleGuardFailure(req, resp, detail, guardError);
            return;
        }

        if ("applyPromo".equals(action)) {
            handleApplyPromo(req, resp, bookingDAO, detail, bookingId, sessionUser.getId());
            return;
        }

        if ("removePromo".equals(action)) {
            handleRemovePromo(req, resp, bookingDAO, bookingId, sessionUser.getId());
            return;
        }

        forwardPayment(req, resp, bookingId, sessionUser.getId(),
                null, "Thanh toán VNPay / MoMo sẽ có trong phiên bản tiếp theo (FR-16).");
    }

    private void handleApplyPromo(HttpServletRequest req, HttpServletResponse resp,
                                BookingDAO bookingDAO, BookingDetailDTO detail,
                                String bookingId, String userId)
            throws IOException, ServletException {
        String promoCode = trim(req.getParameter("promoCode"));
        if (isBlank(promoCode)) {
            forwardPayment(req, resp, bookingId, userId, "Vui lòng nhập mã voucher.", null);
            return;
        }

        Promotion promotion = new PromotionDAO().findByCode(promoCode).orElse(null);
        if (promotion == null) {
            forwardPayment(req, resp, bookingId, userId,
                    "Không tìm thấy mã voucher \"" + promoCode.toUpperCase() + "\".", null);
            return;
        }
        String applyError = new PromotionDAO().validateForApply(promotion);
        if (applyError != null) {
            forwardPayment(req, resp, bookingId, userId, applyError, null);
            return;
        }

        BigDecimal subtotal = detail.getTotalAmount();
        String minOrderError = PromotionCalculator.validateMinOrder(promotion, subtotal);
        if (minOrderError != null) {
            forwardPayment(req, resp, bookingId, userId, minOrderError, null);
            return;
        }

        BigDecimal discount = PromotionCalculator.calculateDiscount(promotion, subtotal);
        if (discount.compareTo(BigDecimal.ZERO) <= 0) {
            forwardPayment(req, resp, bookingId, userId, "Mã voucher không áp dụng được cho đơn này.", null);
            return;
        }

        BigDecimal finalAmount = PromotionCalculator.recalculateFinalAmount(
                subtotal, discount, detail.getVatRate());

        try {
            bookingDAO.applyPromotionToBooking(
                    bookingId, userId, promotion.getId(), discount, finalAmount);
            forwardPayment(req, resp, bookingId, userId, null,
                    "Đã áp dụng mã " + promotion.getCode() + ".");
        } catch (IllegalStateException ex) {
            forwardPayment(req, resp, bookingId, userId, ex.getMessage(), null);
        }
    }

    private void handleRemovePromo(HttpServletRequest req, HttpServletResponse resp,
                                   BookingDAO bookingDAO, String bookingId, String userId)
            throws IOException, ServletException {
        try {
            bookingDAO.removePromotionFromBooking(bookingId, userId);
            forwardPayment(req, resp, bookingId, userId, null, "Đã gỡ mã giảm giá.");
        } catch (IllegalStateException ex) {
            forwardPayment(req, resp, bookingId, userId, ex.getMessage(), null);
        }
    }

    private void forwardPayment(HttpServletRequest req, HttpServletResponse resp,
                                String bookingId, String userId,
                                String errorMessage, String infoMessage)
            throws ServletException, IOException {
        BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
        String guardError = validateAccess(detail, userId);
        if (guardError != null) {
            handleGuardFailure(req, resp, detail, guardError);
            return;
        }
        req.setAttribute("detail", detail);
        if (errorMessage != null) {
            req.setAttribute("errorMessage", errorMessage);
        }
        if (infoMessage != null) {
            req.setAttribute("infoMessage", infoMessage);
        }
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private void handleCancel(HttpServletRequest req, HttpServletResponse resp,
                              BookingDAO bookingDAO, BookingDetailDTO detail,
                              String bookingId, String userId)
            throws IOException, ServletException {
        if (detail == null
                || detail.getUserId() == null
                || !detail.getUserId().equals(userId)
                || !"ONLINE".equals(detail.getBookingSource())
                || !"PENDING".equals(detail.getBookingStatus())) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        String showtimeId = detail.getShowtimeId();
        if (bookingDAO.cancelOnlinePendingBooking(bookingId, userId)) {
            HttpSession session = req.getSession(false);
            if (session != null) {
                session.removeAttribute("checkoutDraft");
            }
            String target = isBlank(showtimeId)
                    ? req.getContextPath() + "/movies?info=" + encode("Đã hủy đơn đặt vé.")
                    : req.getContextPath() + "/checkout?showtimeId=" + showtimeId
                    + "&info=" + encode("Đã hủy đơn. Ghế đã được giải phóng.");
            resp.sendRedirect(target);
            return;
        }

        if (showtimeId != null) {
            resp.sendRedirect(req.getContextPath()
                    + "/checkout?showtimeId=" + showtimeId
                    + "&error=" + encode("Không thể hủy đơn. Vui lòng thử lại."));
        } else {
            resp.sendRedirect(req.getContextPath() + "/movies");
        }
    }

    private void handleGuardFailure(HttpServletRequest req, HttpServletResponse resp,
                                    BookingDetailDTO detail, String guardError)
            throws ServletException, IOException {
        if ("NOT_FOUND".equals(guardError)) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }
        String showtimeId = detail != null ? detail.getShowtimeId() : null;
        if (showtimeId != null) {
            resp.sendRedirect(req.getContextPath()
                    + "/checkout?showtimeId=" + showtimeId + "&error="
                    + encode(guardError));
        } else {
            resp.sendRedirect(req.getContextPath() + "/movies");
        }
    }

    private String validateAccess(BookingDetailDTO detail, String userId) {
        if (detail == null) {
            return "NOT_FOUND";
        }
        if (detail.getUserId() == null || !detail.getUserId().equals(userId)) {
            return "NOT_FOUND";
        }
        if (!"ONLINE".equals(detail.getBookingSource())) {
            return "NOT_FOUND";
        }
        if (!"PENDING".equals(detail.getBookingStatus())) {
            return "Đơn đặt vé không còn ở trạng thái chờ thanh toán.";
        }
        Timestamp expiredAt = detail.getExpiredAt();
        if (expiredAt != null && expiredAt.before(new Timestamp(System.currentTimeMillis()))) {
            return "Đơn đặt vé đã hết hạn. Vui lòng chọn ghế lại.";
        }
        return null;
    }

    private String encode(String msg) {
        return URLEncoder.encode(msg, StandardCharsets.UTF_8);
    }

    private boolean isBlank(String s) { return s == null || s.isBlank(); }

    private String trim(String v) { return v == null ? null : v.trim(); }
}
