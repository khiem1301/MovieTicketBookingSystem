package controller.admin;

import dal.SystemConfigDAO;
import dal.SystemConfigLogDAO;
import dal.VatRuleDAO;
import model.entity.VatRule;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.SystemConfig;
import model.entity.SystemConfigLog;
import utils.AdminAuthUtil;
import utils.AdminPaginationUtil;
import utils.ConfigKeys;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@WebServlet(urlPatterns = {"/admin/config"})
public class SystemConfigListServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/config-list.jsp";
    private static final int PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        SystemConfigDAO dao = new SystemConfigDAO();
        List<SystemConfig> loaded = dao.findByKeys(ConfigKeys.LOYALTY_KEYS);
        List<SystemConfig> configs = orderByKeys(loaded);

        SystemConfig lastUpdated = configs.stream()
                .filter(c -> c.getUpdatedAt() != null)
                .max((a, b) -> a.getUpdatedAt().compareTo(b.getUpdatedAt()))
                .orElse(null);

        VatRule currentVatRule = new VatRuleDAO().findEffectiveNow().orElse(null);

        int historyPage = AdminPaginationUtil.parsePage(req.getParameter("page"));
        List<SystemConfigLog> loyaltyHistory = List.of();
        int historyTotal = 0;
        int historyTotalPages = 1;
        boolean historyTableMissing = false;
        try {
            SystemConfigLogDAO logDAO = new SystemConfigLogDAO();
            historyTotal = logDAO.countLoyaltyHistory();
            historyTotalPages = AdminPaginationUtil.totalPages(historyTotal, PAGE_SIZE);
            historyPage = AdminPaginationUtil.clampPage(historyPage, historyTotalPages);
            loyaltyHistory = logDAO.findLoyaltyHistory(
                    AdminPaginationUtil.offset(historyPage, PAGE_SIZE), PAGE_SIZE);
        } catch (RuntimeException ex) {
            historyTableMissing = true;
        }

        req.setAttribute("configs", configs);
        req.setAttribute("lastUpdated", lastUpdated);
        req.setAttribute("loyaltyHistory", loyaltyHistory);
        req.setAttribute("historyTableMissing", historyTableMissing);
        req.setAttribute("historyCurrentPage", historyPage);
        req.setAttribute("historyTotalPages", historyTotalPages);
        req.setAttribute("historyTotal", historyTotal);
        req.setAttribute("pgCurrent", historyPage);
        req.setAttribute("pgTotal", historyTotalPages);
        req.setAttribute("pgTotalItems", historyTotal);
        req.setAttribute("pgPath", req.getContextPath() + "/admin/config");
        req.setAttribute("pgQueryExtra", "");
        req.setAttribute("currentVatRule", currentVatRule);
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private List<SystemConfig> orderByKeys(List<SystemConfig> loaded) {
        Map<String, SystemConfig> byKey = loaded.stream()
                .collect(Collectors.toMap(SystemConfig::getConfigKey, Function.identity()));
        List<SystemConfig> ordered = new ArrayList<>();
        for (String key : ConfigKeys.LOYALTY_KEYS) {
            SystemConfig config = byKey.get(key);
            if (config != null) {
                ordered.add(config);
            }
        }
        return ordered;
    }
}
