package controller.admin;

import dal.PromotionDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.Promotion;
import utils.AdminAuthUtil;
import utils.AdminPaginationUtil;

import java.io.IOException;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/promotions"})
public class PromotionListServlet extends HttpServlet {

    private static final String VIEW      = "/WEB-INF/views/admin/promotion-list.jsp";
    private static final int    PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdminOrManager(req, resp)) return;

        String statusFilter = trim(req.getParameter("status"));
        String keyword      = trim(req.getParameter("q"));
        String editId       = trim(req.getParameter("edit"));

        PromotionDAO dao = new PromotionDAO();

        int total      = dao.count(statusFilter, keyword);
        int page       = AdminPaginationUtil.parsePage(req.getParameter("page"));
        int totalPages = AdminPaginationUtil.totalPages(total, PAGE_SIZE);
        page           = AdminPaginationUtil.clampPage(page, totalPages);
        List<Promotion> promotions = dao.findAll(statusFilter, keyword,
                                                 AdminPaginationUtil.offset(page, PAGE_SIZE), PAGE_SIZE);

        Promotion editPromotion = (editId != null)
                ? dao.findById(editId).orElse(null)
                : null;

        req.setAttribute("promotions",        promotions);
        req.setAttribute("editPromotion",    editPromotion);
        req.setAttribute("statusFilter",     statusFilter);
        req.setAttribute("keyword",          keyword);
        req.setAttribute("pgCurrent",        page);
        req.setAttribute("pgTotal",          totalPages);
        req.setAttribute("pgTotalItems",     total);
        req.setAttribute("pgPath",           req.getContextPath() + "/admin/promotions");
        req.setAttribute("pgQueryExtra",     buildQueryExtra(statusFilter, keyword));
        req.setAttribute("flashSuccess",     AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError",       AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));
        // Stats
        req.setAttribute("statRedemptions", dao.sumTotalRedemptions());
        req.setAttribute("statActive",       dao.countActive());
        req.setAttribute("statEndingSoon",   dao.countEndingSoon(7));
        req.setAttribute("statRevenue",      dao.sumRevenueImpact());

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private String buildQueryExtra(String status, String keyword) {
        StringBuilder sb = new StringBuilder();
        if (status  != null && !status.isBlank())  sb.append("&status=").append(status);
        if (keyword != null && !keyword.isBlank()) sb.append("&q=").append(keyword);
        return sb.toString();
    }

    private String trim(String v) { return v == null ? null : v.trim(); }
}
