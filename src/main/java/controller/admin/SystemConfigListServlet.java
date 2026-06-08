package controller.admin;

import dal.SystemConfigDAO;
import dal.VatRuleDAO;
import model.entity.VatRule;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.SystemConfig;
import utils.AdminAuthUtil;
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

        VatRule currentVatRule = new VatRuleDAO().findCurrentActive().orElse(null);

        req.setAttribute("configs", configs);
        req.setAttribute("lastUpdated", lastUpdated);
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
