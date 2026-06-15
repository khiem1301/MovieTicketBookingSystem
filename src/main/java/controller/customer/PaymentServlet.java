package controller.customer;

import java.io.IOException;
import java.math.BigDecimal;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.util.Optional;

import dal.BookingDAO;
import dal.PaymentDAO;
import dal.PaymentDAO.PaymentRecord;
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
import utils.VietQRConfig;
import utils.VietQRUtil;

/**
 * FR-14 / FR-16 VietQR / FR-22 — Trang thanh toán online tại /payment?bookingId=
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

        BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
        if (detail != null
                && detail.getUserId() != null
                && detail.getUserId().equals(sessionUser.getId())
                && "PAID".equals(detail.getPaymentStatus())) {
            resp.sendRedirect(req.getContextPath() + "/payment/success?bookingId=" + bookingId);
            return;
        }

        String error = trim(req.getParameter("error"));
        forwardPayment(req, resp, bookingId, sessionUser.getId(),
                error, null, loadVietQRSession(req, bookingId));
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

        if ("payVietQR".equals(action)) {
            handlePayVietQR(req, resp, detail, bookingId, sessionUser.getId());
            return;
        }

        if ("confirmVietQR".equals(action)) {
            handleConfirmVietQR(req, resp, bookingId, sessionUser.getId());
            return;
        }

        forwardPayment(req, resp, bookingId, sessionUser.getId(),
                "Vui lòng chọn thanh toán VietQR.", null, null);
    }

    private void handlePayVietQR(HttpServletRequest req, HttpServletResponse resp,
                                 BookingDetailDTO detail, String bookingId, String userId)
            throws IOException, ServletException {
        if (!VietQRConfig.isConfigured()) {
            forwardPayment(req, resp, bookingId, userId,
                    "Chưa cấu hình VietQR. Sao chép vietqr.properties.example → vietqr.properties.",
                    null, null);
            return;
        }

        BigDecimal finalAmount = detail.getFinalAmount();
        if (finalAmount == null || finalAmount.compareTo(BigDecimal.ZERO) <= 0) {
            forwardPayment(req, resp, bookingId, userId,
                    "Số tiền thanh toán không hợp lệ.", null, null);
            return;
        }

        String transferContent = VietQRUtil.transferContent(detail.getBookingCode());
        String qrUrl = VietQRUtil.qrImageUrl(finalAmount, transferContent);

        PaymentDAO paymentDAO = new PaymentDAO();
        Optional<PaymentRecord> existing = paymentDAO.findLatestPendingVietQR(bookingId);
        if (existing.isEmpty()
                || existing.get().amount().compareTo(finalAmount) != 0
                || !transferContent.equals(existing.get().transactionCode())) {
            paymentDAO.insertPendingOnlineVietQR(bookingId, finalAmount, transferContent);
        }

        VietQRPaymentSession sessionData = new VietQRPaymentSession(
                qrUrl,
                transferContent,
                VietQRConfig.bankName(),
                VietQRConfig.accountNumber(),
                VietQRConfig.accountName(),
                finalAmount);

        HttpSession session = req.getSession(true);
        session.setAttribute("vietqrBookingId", bookingId);
        session.setAttribute("vietqrQrUrl", qrUrl);
        session.setAttribute("vietqrTransferContent", transferContent);
        session.setAttribute("vietqrAmount", finalAmount.toPlainString());

        forwardPayment(req, resp, bookingId, userId, null,
                "Quét mã VietQR và chuyển khoản đúng số tiền, nội dung ghi chú.",
                sessionData);
    }

    private void handleConfirmVietQR(HttpServletRequest req, HttpServletResponse resp,
                                     String bookingId, String userId)
            throws IOException, ServletException {
        BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
        String guardError = validateAccess(detail, userId);
        if (guardError != null) {
            handleGuardFailure(req, resp, detail, guardError);
            return;
        }

        Optional<PaymentRecord> paymentOpt = new PaymentDAO().findLatestPendingVietQR(bookingId);
        if (paymentOpt.isEmpty()) {
            forwardPayment(req, resp, bookingId, userId,
                    "Chưa có giao dịch VietQR. Vui lòng tạo mã QR trước.",
                    null, loadVietQRSession(req, bookingId));
            return;
        }

        PaymentRecord payment = paymentOpt.get();
        String transId = "VIETQR-" + payment.transactionCode();
        boolean ok = new BookingDAO().completeOnlinePayment(bookingId, payment.id(), transId);
        if (!ok) {
            forwardPayment(req, resp, bookingId, userId,
                    "Không thể xác nhận thanh toán. Vui lòng thử lại hoặc liên hệ hỗ trợ.",
                    null, loadVietQRSession(req, bookingId));
            return;
        }

        clearVietQRSession(req);
        resp.sendRedirect(req.getContextPath() + "/payment/success?bookingId=" + bookingId);
    }

    private void handleApplyPromo(HttpServletRequest req, HttpServletResponse resp,
                                BookingDAO bookingDAO, BookingDetailDTO detail,
                                String bookingId, String userId)
            throws IOException, ServletException {
        String promoCode = trim(req.getParameter("promoCode"));
        if (isBlank(promoCode)) {
            forwardPayment(req, resp, bookingId, userId, "Vui lòng nhập mã voucher.", null, loadVietQRSession(req, bookingId));
            return;
        }

        Promotion promotion = new PromotionDAO().findByCode(promoCode).orElse(null);
        if (promotion == null) {
            forwardPayment(req, resp, bookingId, userId,
                    "Không tìm thấy mã voucher \"" + promoCode.toUpperCase() + "\".", null, loadVietQRSession(req, bookingId));
            return;
        }
        String applyError = new PromotionDAO().validateForApply(promotion);
        if (applyError != null) {
            forwardPayment(req, resp, bookingId, userId, applyError, null, loadVietQRSession(req, bookingId));
            return;
        }

        BigDecimal subtotal = detail.getTotalAmount();
        String minOrderError = PromotionCalculator.validateMinOrder(promotion, subtotal);
        if (minOrderError != null) {
            forwardPayment(req, resp, bookingId, userId, minOrderError, null, loadVietQRSession(req, bookingId));
            return;
        }

        BigDecimal discount = PromotionCalculator.calculateDiscount(promotion, subtotal);
        if (discount.compareTo(BigDecimal.ZERO) <= 0) {
            forwardPayment(req, resp, bookingId, userId, "Mã voucher không áp dụng được cho đơn này.", null, loadVietQRSession(req, bookingId));
            return;
        }

        BigDecimal finalAmount = PromotionCalculator.recalculateFinalAmount(
                subtotal, discount, detail.getVatRate());

        try {
            bookingDAO.applyPromotionToBooking(
                    bookingId, userId, promotion.getId(), discount, finalAmount);
            clearVietQRSession(req);
            forwardPayment(req, resp, bookingId, userId, null,
                    "Đã áp dụng mã " + promotion.getCode() + ". Vui lòng tạo lại mã QR VietQR.",
                    null);
        } catch (IllegalStateException ex) {
            forwardPayment(req, resp, bookingId, userId, ex.getMessage(), null, loadVietQRSession(req, bookingId));
        }
    }

    private void handleRemovePromo(HttpServletRequest req, HttpServletResponse resp,
                                   BookingDAO bookingDAO, String bookingId, String userId)
            throws IOException, ServletException {
        try {
            bookingDAO.removePromotionFromBooking(bookingId, userId);
            clearVietQRSession(req);
            forwardPayment(req, resp, bookingId, userId, null,
                    "Đã gỡ mã giảm giá. Vui lòng tạo lại mã QR VietQR.", null);
        } catch (IllegalStateException ex) {
            forwardPayment(req, resp, bookingId, userId, ex.getMessage(), null, loadVietQRSession(req, bookingId));
        }
    }

    private void forwardPayment(HttpServletRequest req, HttpServletResponse resp,
                                String bookingId, String userId,
                                String errorMessage, String infoMessage, VietQRPaymentSession vietqr)
            throws ServletException, IOException {
        BookingDetailDTO detail = new BookingDAO().getDetailById(bookingId);
        String guardError = validateAccess(detail, userId);
        if (guardError != null) {
            handleGuardFailure(req, resp, detail, guardError);
            return;
        }
        req.setAttribute("detail", detail);
        req.setAttribute("vietqrConfigured", VietQRConfig.isConfigured());
        VietQRPaymentSession active = vietqr != null ? vietqr : loadVietQRSession(req, bookingId);
        if (active != null) {
            req.setAttribute("vietqrActive", true);
            req.setAttribute("vietqrQrUrl", active.qrUrl());
            req.setAttribute("vietqrTransferContent", active.transferContent());
            req.setAttribute("vietqrBankName", active.bankName());
            req.setAttribute("vietqrAccountNo", active.accountNo());
            req.setAttribute("vietqrAccountName", active.accountName());
        }
        if (errorMessage != null) {
            req.setAttribute("errorMessage", errorMessage);
        }
        if (infoMessage != null) {
            req.setAttribute("infoMessage", infoMessage);
        }
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private VietQRPaymentSession loadVietQRSession(HttpServletRequest req, String bookingId) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return null;
        }
        Object storedBooking = session.getAttribute("vietqrBookingId");
        if (storedBooking == null || !bookingId.equals(storedBooking.toString())) {
            return null;
        }
        String qrUrl = (String) session.getAttribute("vietqrQrUrl");
        String transferContent = (String) session.getAttribute("vietqrTransferContent");
        if (qrUrl == null || qrUrl.isBlank() || transferContent == null) {
            return null;
        }
        if (!VietQRConfig.isConfigured()) {
            return null;
        }
        return new VietQRPaymentSession(
                qrUrl,
                transferContent,
                VietQRConfig.bankName(),
                VietQRConfig.accountNumber(),
                VietQRConfig.accountName(),
                null);
    }

    private void clearVietQRSession(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session != null) {
            session.removeAttribute("vietqrQrUrl");
            session.removeAttribute("vietqrTransferContent");
            session.removeAttribute("vietqrBookingId");
            session.removeAttribute("vietqrAmount");
        }
    }

    private record VietQRPaymentSession(
            String qrUrl,
            String transferContent,
            String bankName,
            String accountNo,
            String accountName,
            BigDecimal amount) {}

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
            clearVietQRSession(req);
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
