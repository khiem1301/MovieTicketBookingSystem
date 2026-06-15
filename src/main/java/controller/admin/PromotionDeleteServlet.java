package controller.admin;

import dal.PromotionDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import utils.AdminAuthUtil;

import java.io.IOException;

@WebServlet(urlPatterns = {"/admin/promotions/delete"})
public class PromotionDeleteServlet extends HttpServlet {

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
            boolean deleted = new PromotionDAO().delete(id.trim());
            if (deleted) {
                AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                        "Đã xóa mã giảm giá thành công.");
            } else {
                AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                        "Không thể xóa: mã giảm giá đã được sử dụng hoặc không tồn tại.");
            }
        } catch (RuntimeException e) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Lỗi khi xóa: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/promotions");
    }
}
