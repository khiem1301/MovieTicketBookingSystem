package controller.admin;

import dal.VatRuleDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.VatRuleForm;
import utils.AdminAuthUtil;
import utils.VatRuleValidator;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/vat/update"})
public class VatRuleUpdateServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        req.setCharacterEncoding("UTF-8");

        VatRuleForm form = readForm(req);
        List<String> errors = VatRuleValidator.validate(form);

        if (form.getRuleId() == null || form.getRuleId().isBlank()) {
            errors.add(0, "Không xác định được quy tắc cần sửa.");
        }

        String ruleId = form.getRuleId() == null ? "" : form.getRuleId().trim();
        String redirect = buildEditRedirect(req, ruleId);

        if (!errors.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, String.join(" ", errors));
            resp.sendRedirect(redirect);
            return;
        }

        LocalDate start = form.getStartDate().toLocalDate();
        VatRuleDAO dao = new VatRuleDAO();
        // Chỉ chặn trùng ngày với lịch tương lai — hôm nay cho phép thay thế/áp dụng ngay (giống create)
        if (start.isAfter(LocalDate.now()) && dao.existsByStartDate(start, ruleId)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    VatRuleCreateServlet.MSG_DUPLICATE_START_DATE);
            resp.sendRedirect(redirect);
            return;
        }

        try {
            BigDecimal rate = new BigDecimal(form.getVatRate().trim());
            Timestamp startDate = start.equals(LocalDate.now())
                    ? Timestamp.valueOf(LocalDateTime.now())
                    : Timestamp.valueOf(start.atStartOfDay());

            dao.updateScheduled(
                    ruleId,
                    form.getRuleName().trim(),
                    rate,
                    startDate
            );

            String message = start.isAfter(LocalDate.now())
                    ? "Đã cập nhật quy tắc VAT đã lên lịch."
                    : "Đã chuyển quy tắc sang áp dụng từ hôm nay.";
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS, message);
        } catch (VatRuleDAO.DuplicateStartDateException ex) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    VatRuleCreateServlet.MSG_DUPLICATE_START_DATE);
        } catch (RuntimeException ex) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể sửa quy tắc. Chỉ sửa được quy tắc chưa đến ngày áp dụng.");
        }

        resp.sendRedirect(redirect);
    }

    private VatRuleForm readForm(HttpServletRequest req) {
        VatRuleForm form = new VatRuleForm();
        form.setRuleId(trim(req.getParameter("ruleId")));
        form.setRuleName(trim(req.getParameter("ruleName")));
        form.setVatRate(trim(req.getParameter("vatRate")));

        String startDateRaw = trim(req.getParameter("startDate"));
        if (startDateRaw != null && !startDateRaw.isBlank()) {
            form.setStartDate(Date.valueOf(startDateRaw));
        }
        return form;
    }

    private String buildEditRedirect(HttpServletRequest req, String ruleId) {
        String base = req.getContextPath() + "/admin/vat";
        if (ruleId == null || ruleId.isBlank()) {
            return base;
        }
        return base + "?edit=" + ruleId + "#vat-edit-form";
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
