package controller.admin;

import dal.PromotionDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AdminAuthUtil;

import java.io.IOException;

@WebServlet(urlPatterns = {"/admin/promotions/toggle"})
public class PromotionToggleServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdminOrManager(req, resp)) return;

        String id = req.getParameter("promotionId");
        if (id == null || id.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/admin/promotions");
            return;
        }

        try {
            new PromotionDAO().toggleStatus(id.trim());
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                    "Đã đổi trạng thái mã giảm giá.");
        } catch (RuntimeException e) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Lỗi khi đổi trạng thái: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/promotions");
    }
}
