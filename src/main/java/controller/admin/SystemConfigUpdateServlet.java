package controller.admin;

import dal.SystemConfigDAO;
import dal.SystemConfigLogDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.SystemConfig;
import model.entity.SystemConfigLog;
import utils.AdminAuthUtil;
import utils.ConfigKeys;
import utils.SessionUtil;
import utils.SystemConfigValidator;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@WebServlet(urlPatterns = {"/admin/config/update"})
public class SystemConfigUpdateServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        req.setCharacterEncoding("UTF-8");

        Map<String, String> submitted = new LinkedHashMap<>();
        for (String key : ConfigKeys.LOYALTY_KEYS) {
            submitted.put(key, req.getParameter(key));
        }

        Map<String, String> values = SystemConfigValidator.normalizeLoyaltyValues(submitted);
        List<String> errors = SystemConfigValidator.validateLoyaltyConfig(values);

        if (!errors.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, String.join(" ", errors));
            resp.sendRedirect(req.getContextPath() + "/admin/config");
            return;
        }

        String adminId = SessionUtil.getLoggedUser(req).getId();
        SystemConfigDAO configDao = new SystemConfigDAO();
        Map<String, String> previous = loadCurrentValues(configDao);

        if (values.equals(previous)) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không có thay đổi nào để lưu.");
            resp.sendRedirect(req.getContextPath() + "/admin/config");
            return;
        }

        try {
            SystemConfigLog log = buildLog(previous, values, adminId);
            new SystemConfigLogDAO().insert(log);

            for (Map.Entry<String, String> entry : values.entrySet()) {
                configDao.updateValue(entry.getKey(), entry.getValue(), adminId);
            }
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                    "Đã lưu cấu hình tích điểm thành công.");
        } catch (RuntimeException ex) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể lưu cấu hình. Vui lòng thử lại sau.");
        }

        resp.sendRedirect(req.getContextPath() + "/admin/config");
    }

    private Map<String, String> loadCurrentValues(SystemConfigDAO dao) {
        return dao.findByKeys(ConfigKeys.LOYALTY_KEYS).stream()
                .collect(Collectors.toMap(
                        SystemConfig::getConfigKey,
                        c -> c.getConfigValue() == null ? "" : c.getConfigValue().trim(),
                        (a, b) -> b,
                        LinkedHashMap::new
                ));
    }

    private SystemConfigLog buildLog(Map<String, String> previous, Map<String, String> values, String adminId) {
        SystemConfigLog log = new SystemConfigLog();
        log.setEarnRate(values.get(ConfigKeys.LOYALTY_EARN_RATE));
        log.setRedeemRate(values.get(ConfigKeys.LOYALTY_REDEEM_RATE));
        log.setMinRedeem(values.get(ConfigKeys.LOYALTY_MIN_REDEEM));
        log.setMaxRedeemPerOrder(values.get(ConfigKeys.LOYALTY_MAX_REDEEM_PER_ORDER));
        log.setPreviousEarnRate(previous.get(ConfigKeys.LOYALTY_EARN_RATE));
        log.setPreviousRedeemRate(previous.get(ConfigKeys.LOYALTY_REDEEM_RATE));
        log.setPreviousMinRedeem(previous.get(ConfigKeys.LOYALTY_MIN_REDEEM));
        log.setPreviousMaxRedeemPerOrder(previous.get(ConfigKeys.LOYALTY_MAX_REDEEM_PER_ORDER));
        log.setUpdatedBy(adminId);
        return log;
    }
}
