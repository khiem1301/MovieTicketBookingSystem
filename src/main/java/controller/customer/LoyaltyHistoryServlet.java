package controller.customer;

import dal.LoyaltyDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.SessionUser;
import utils.SessionUtil;

import java.io.IOException;
import java.util.List;

/** FR-44 — Lịch sử điểm tích luỹ của khách hàng. */
@WebServlet({"/loyalty", "/customer/loyalty-history"})
public class LoyaltyHistoryServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/loyalty-history.jsp";
    private static final int PAGE_SIZE = 10;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        SessionUser user = SessionUtil.getLoggedUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        int page = 1;
        try { page = Math.max(1, Integer.parseInt(req.getParameter("page"))); }
        catch (Exception ignored) {}

        LoyaltyDAO dao = new LoyaltyDAO();
        int total = dao.countHistory(user.getId());
        int totalPages = Math.max(1, (int) Math.ceil((double) total / PAGE_SIZE));
        page = Math.min(page, totalPages);

        List<?> items = dao.getHistory(user.getId(), (page - 1) * PAGE_SIZE, PAGE_SIZE);

        int loyaltyPoints = dao.getLoyaltyBalance(user.getId());

        req.setAttribute("items", items);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("total", total);
        req.setAttribute("loyaltyPoints", loyaltyPoints);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }
}
