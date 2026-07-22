package controller.customer;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import org.json.JSONObject;

import dal.BookingDAO;
import dal.PaymentDAO;
import dal.PaymentDAO.PaymentRecord;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.EmailUtil;
import utils.SePayConfig;

/**
 * FR-16 — Webhook SePay: tự xác nhận VietQR khi có tiền vào khớp nội dung CK + số tiền.
 * Áp dụng cả đơn ONLINE (customer) và OFFLINE (quầy staff).
 * Docs: https://docs.sepay.vn/tich-hop-webhooks.html
 */
@WebServlet("/payment/sepay/webhook")
public class SePayWebhookServlet extends HttpServlet {

    private static final Logger LOG = Logger.getLogger(SePayWebhookServlet.class.getName());

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        // Health check / SePay "Gửi thử" đôi khi GET
        writeSuccess(resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!SePayConfig.isEnabled()) {
            writeJson(resp, HttpServletResponse.SC_SERVICE_UNAVAILABLE,
                    "{\"success\":false,\"message\":\"SePay disabled\"}");
            return;
        }

        if (!SePayConfig.matchesApiKey(req.getHeader("Authorization"))) {
            LOG.warning("SePay webhook: invalid API key");
            writeJson(resp, HttpServletResponse.SC_UNAUTHORIZED,
                    "{\"success\":false,\"message\":\"Unauthorized\"}");
            return;
        }

        String body;
        try (BufferedReader reader = req.getReader()) {
            body = reader.lines().collect(Collectors.joining("\n"));
        }
        if (body == null || body.isBlank()) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "{\"success\":false,\"message\":\"Empty body\"}");
            return;
        }

        JSONObject json;
        try {
            json = new JSONObject(body);
        } catch (Exception e) {
            writeJson(resp, HttpServletResponse.SC_BAD_REQUEST,
                    "{\"success\":false,\"message\":\"Invalid JSON\"}");
            return;
        }

        String transferType = json.optString("transferType", "").trim().toLowerCase();
        if (!"in".equals(transferType)) {
            // Không phải tiền vào — vẫn trả success để SePay không retry
            writeSuccess(resp);
            return;
        }

        String accountNumber = json.optString("accountNumber", "").trim();
        String configuredAcc = SePayConfig.accountNumber();
        if (!configuredAcc.isBlank() && !configuredAcc.equals(accountNumber)) {
            LOG.info("SePay webhook: skip — account mismatch " + accountNumber);
            writeSuccess(resp);
            return;
        }

        long amountLong = -1L;
        if (!json.isNull("transferAmount")) {
            Object rawAmount = json.get("transferAmount");
            if (rawAmount instanceof Number n) {
                amountLong = n.longValue();
            } else {
                try {
                    amountLong = Long.parseLong(rawAmount.toString().trim().replace(",", ""));
                } catch (Exception ignored) {
                    amountLong = -1L;
                }
            }
        }
        if (amountLong <= 0) {
            LOG.warning("SePay webhook: skip — invalid transferAmount in body=" + body);
            writeSuccess(resp);
            return;
        }
        BigDecimal amount = BigDecimal.valueOf(amountLong);

        String content = json.optString("content", "");
        String code = json.optString("code", "");
        String description = json.optString("description", "");
        String haystack = (content + " " + code + " " + description).trim();
        if (haystack.isBlank()) {
            LOG.warning("SePay webhook: skip — empty content/code");
            writeSuccess(resp);
            return;
        }

        PaymentDAO paymentDAO = new PaymentDAO();
        Optional<PaymentRecord> paymentOpt =
                paymentDAO.findPendingVietQRByTransferContent(haystack, amount);
        if (paymentOpt.isEmpty()) {
            LOG.warning("SePay webhook: NO MATCH pending VietQR | amount=" + amountLong
                    + " | content=[" + content + "] code=[" + code + "]");
            // Vẫn 200 success để SePay không retry — nhưng đơn CHƯA thanh toán
            writeSuccess(resp);
            return;
        }

        PaymentRecord payment = paymentOpt.get();
        long sepayId = json.optLong("id", 0L);
        String externalId = sepayId > 0
                ? "SEPAY-" + sepayId
                : "SEPAY-" + json.optString("referenceCode", payment.transactionCode());

        try {
            boolean ok = new BookingDAO().completeOnlinePayment(
                    payment.bookingId(), payment.id(), externalId);
            if (ok) {
                EmailUtil.sendBookingConfirmationEmailAsync(payment.bookingId());
                LOG.info("SePay webhook: confirmed bookingId=" + payment.bookingId()
                        + " source=" + payment.paymentSource()
                        + " sepayId=" + sepayId);
            } else {
                LOG.warning("SePay webhook: matched paymentId=" + payment.id()
                        + " bookingId=" + payment.bookingId()
                        + " but completeOnlinePayment returned false (status may have changed)");
            }
        } catch (Exception e) {
            LOG.log(Level.SEVERE, "SePay webhook complete failed", e);
            writeJson(resp, HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                    "{\"success\":false,\"message\":\"Confirm failed\"}");
            return;
        }

        writeSuccess(resp);
    }

    private void writeSuccess(HttpServletResponse resp) throws IOException {
        writeJson(resp, HttpServletResponse.SC_OK, "{\"success\":true}");
    }

    private void writeJson(HttpServletResponse resp, int status, String json) throws IOException {
        resp.setStatus(status);
        resp.setContentType("application/json;charset=UTF-8");
        resp.setCharacterEncoding("UTF-8");
        try (PrintWriter out = resp.getWriter()) {
            out.print(json);
        }
    }
}
