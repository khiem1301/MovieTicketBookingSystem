package controller.admin;

import dal.VatRuleDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.VatRule;
import utils.AdminAuthUtil;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@WebServlet(urlPatterns = {"/admin/vat"})
public class VatRuleListServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/vat-list.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        VatRuleDAO dao = new VatRuleDAO();
        Optional<VatRule> currentRule = dao.findEffectiveNow();
        List<VatRule> scheduledList = dao.findScheduledList();
        List<VatRule> history = dao.findHistory();

        VatRule editRule = resolveEditRule(dao, trim(req.getParameter("edit")));

        req.setAttribute("currentRule", currentRule.orElse(null));
        req.setAttribute("scheduledList", scheduledList);
        req.setAttribute("editRule", editRule);
        req.setAttribute("history", history);
        req.setAttribute("defaultStartDate", LocalDate.now().toString());
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private VatRule resolveEditRule(VatRuleDAO dao, String editId) {
        if (editId == null || editId.isBlank()) {
            return null;
        }
        return dao.findById(editId)
                .filter(dao::isScheduledEditable)
                .orElse(null);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
