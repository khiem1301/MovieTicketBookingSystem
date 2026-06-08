package controller.admin;

import dal.SystemConfigDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AdminAuthUtil;
import utils.ConfigKeys;
import utils.SessionUtil;
import utils.SystemConfigValidator;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

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
        SystemConfigDAO dao = new SystemConfigDAO();

        try {
            for (Map.Entry<String, String> entry : values.entrySet()) {
                dao.updateValue(entry.getKey(), entry.getValue(), adminId);
            }
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                    "Đã lưu cấu hình tích điểm thành công.");
        } catch (RuntimeException ex) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Không thể lưu cấu hình. Vui lòng thử lại sau.");
        }

        resp.sendRedirect(req.getContextPath() + "/admin/config");
    }
}
