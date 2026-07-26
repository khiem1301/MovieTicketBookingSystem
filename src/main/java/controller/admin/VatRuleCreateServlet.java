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

@WebServlet(urlPatterns = {"/admin/vat/create"})
public class VatRuleCreateServlet extends HttpServlet {

    public static final String MSG_DUPLICATE_START_DATE =
            "Không thể lên lịch 2 quy tắc VAT trong cùng một ngày. Hãy chọn ngày khác hoặc hủy quy tắc trùng ngày.";

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        req.setCharacterEncoding("UTF-8");

        VatRuleForm form = readForm(req);
        List<String> errors = VatRuleValidator.validate(form);

        if (!errors.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, String.join(" ", errors));
            resp.sendRedirect(req.getContextPath() + "/admin/vat");
            return;
        }

        LocalDate start = form.getStartDate().toLocalDate();
        VatRuleDAO dao = new VatRuleDAO();

        if (start.isAfter(LocalDate.now()) && dao.existsByStartDate(start, null)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, MSG_DUPLICATE_START_DATE);
            resp.sendRedirect(req.getContextPath() + "/admin/vat");
            return;
        }

        try {
            BigDecimal rate = new BigDecimal(form.getVatRate().trim());
            Timestamp startDate = start.equals(LocalDate.now())
                    ? Timestamp.valueOf(LocalDateTime.now())
                    : Timestamp.valueOf(start.atStartOfDay());

            dao.createAndActivate(form.getRuleName().trim(), rate, startDate);

            String rateText = rate.stripTrailingZeros().toPlainString() + "%";
            String message = start.isAfter(LocalDate.now())
                    ? "Đã lên lịch thuế suất VAT " + rateText + " — áp dụng từ " + start + "."
                    : "Đã áp dụng thuế suất VAT mới: " + rateText + ".";
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS, message);
        } catch (VatRuleDAO.DuplicateStartDateException ex) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, MSG_DUPLICATE_START_DATE);
        } catch (RuntimeException ex) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể lưu quy tắc VAT. Vui lòng thử lại sau.");
        }

        resp.sendRedirect(req.getContextPath() + "/admin/vat");
    }

    private VatRuleForm readForm(HttpServletRequest req) {
        VatRuleForm form = new VatRuleForm();
        form.setRuleName(trim(req.getParameter("ruleName")));
        form.setVatRate(trim(req.getParameter("vatRate")));

        String startDateRaw = trim(req.getParameter("startDate"));
        if (startDateRaw != null && !startDateRaw.isBlank()) {
            form.setStartDate(Date.valueOf(startDateRaw));
        }
        return form;
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
