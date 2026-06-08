package controller.admin;

import dal.VatRuleDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AdminAuthUtil;

import java.io.IOException;

@WebServlet(urlPatterns = {"/admin/vat/cancel"})
public class VatRuleCancelServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        req.setCharacterEncoding("UTF-8");

        String ruleId = trim(req.getParameter("ruleId"));
        if (ruleId == null || ruleId.isBlank()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, "Yêu cầu không hợp lệ.");
            resp.sendRedirect(req.getContextPath() + "/admin/vat");
            return;
        }

        try {
            new VatRuleDAO().cancelScheduled(ruleId);
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                    "Đã hủy quy tắc VAT đã lên lịch.");
        } catch (RuntimeException ex) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể hủy quy tắc. Chỉ hủy được quy tắc chưa đến ngày áp dụng.");
        }

        resp.sendRedirect(req.getContextPath() + "/admin/vat");
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
