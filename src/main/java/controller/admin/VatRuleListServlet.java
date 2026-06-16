package controller.admin;

import dal.VatRuleDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.VatRule;
import utils.AdminAuthUtil;
import utils.AdminPaginationUtil;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@WebServlet(urlPatterns = {"/admin/vat"})
public class VatRuleListServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/vat-list.jsp";
    private static final int PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        VatRuleDAO dao = new VatRuleDAO();
        Optional<VatRule> currentRule = dao.findEffectiveNow();
        List<VatRule> scheduledList = dao.findScheduledList();

        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));
        int historyTotal = dao.countHistory();
        int totalPages = AdminPaginationUtil.totalPages(historyTotal, PAGE_SIZE);
        page = AdminPaginationUtil.clampPage(page, totalPages);
        List<VatRule> history = dao.findHistory(AdminPaginationUtil.offset(page, PAGE_SIZE), PAGE_SIZE);

        String editId = trim(req.getParameter("edit"));
        VatRule editRule = resolveEditRule(dao, editId);

        req.setAttribute("currentRule", currentRule.orElse(null));
        req.setAttribute("scheduledList", scheduledList);
        req.setAttribute("editRule", editRule);
        req.setAttribute("history", history);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("historyTotal", historyTotal);
        req.setAttribute("pgCurrent", page);
        req.setAttribute("pgTotal", totalPages);
        req.setAttribute("pgTotalItems", historyTotal);
        req.setAttribute("pgPath", req.getContextPath() + "/admin/vat");
        req.setAttribute("pgQueryExtra", AdminPaginationUtil.queryParam("edit", editId));
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
