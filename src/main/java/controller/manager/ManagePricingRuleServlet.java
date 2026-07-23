package controller.manager;

import dal.PricingRuleDAO;
import model.dto.SessionUser;
import model.entity.PricingRule;
import utils.AdminPaginationUtil;
import utils.PricingRuleValidator;
import utils.SessionUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

/**
 * FR-49 — Quản lý quy tắc giá động (CRUD).
 */
@WebServlet("/admin/pricing-rules")
public class ManagePricingRuleServlet extends HttpServlet {

    private static final int PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;
    private final PricingRuleDAO pricingRuleDAO = new PricingRuleDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        if ("edit".equals(req.getParameter("action"))) {
            String id = trim(req.getParameter("id"));
            Optional<PricingRule> found = pricingRuleDAO.findById(id);
            if (found.isPresent()) {
                PricingRule edit = found.get();
                req.setAttribute("editRule", edit);
                req.setAttribute("selectedDays", PricingRuleValidator.daySetFromCsv(edit.getDayOfWeek()));
            }
        }

        loadAndForward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");

        switch (action != null ? action : "") {
            case "update" -> handleUpdate(req, resp);
            case "toggle-status" -> handleToggleStatus(req, resp);
            case "delete" -> handleDelete(req, resp);
            default -> handleCreate(req, resp);
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        PricingRuleValidator.Result parsed = parseForm(req);
        if (!parsed.isValid()) {
            forwardWithErrors(req, resp, parsed.getErrors(), null);
            return;
        }

        SessionUser user = SessionUtil.getLoggedUser(req);
        if (user == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        PricingRule rule = parsed.getRule();
        rule.setCreatedBy(user.getId());
        pricingRuleDAO.insert(rule);
        resp.sendRedirect(req.getContextPath() + "/admin/pricing-rules?success=created");
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = trim(req.getParameter("id"));
        Optional<PricingRule> existing = pricingRuleDAO.findById(id);
        if (existing.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/admin/pricing-rules");
            return;
        }

        PricingRuleValidator.Result parsed = parseForm(req);
        if (!parsed.isValid()) {
            forwardWithErrors(req, resp, parsed.getErrors(), existing.get());
            return;
        }

        PricingRule rule = parsed.getRule();
        rule.setId(id);
        pricingRuleDAO.update(rule);
        resp.sendRedirect(req.getContextPath() + "/admin/pricing-rules?success=updated");
    }

    private void handleToggleStatus(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String id = trim(req.getParameter("id"));
        Optional<PricingRule> found = pricingRuleDAO.findById(id);
        if (found.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/admin/pricing-rules");
            return;
        }
        PricingRule rule = found.get();
        String next = "ACTIVE".equals(rule.getStatus()) ? "INACTIVE" : "ACTIVE";
        pricingRuleDAO.updateStatus(id, next);
        resp.sendRedirect(req.getContextPath() + "/admin/pricing-rules?success=status-updated"
                + filterQuery(req));
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String id = trim(req.getParameter("id"));
        if (id == null || pricingRuleDAO.findById(id).isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/admin/pricing-rules");
            return;
        }
        pricingRuleDAO.delete(id);
        resp.sendRedirect(req.getContextPath() + "/admin/pricing-rules?success=deleted"
                + filterQuery(req));
    }

    private PricingRuleValidator.Result parseForm(HttpServletRequest req) {
        return PricingRuleValidator.parseAndValidate(
                req.getParameter("ruleName"),
                req.getParameter("conditionType"),
                req.getParameterValues("days"),
                req.getParameter("timeFrom"),
                req.getParameter("timeTo"),
                req.getParameter("dateFrom"),
                req.getParameter("dateTo"),
                req.getParameter("adjustmentType"),
                req.getParameter("adjustmentValue"),
                req.getParameter("priority"),
                req.getParameter("status"));
    }

    private void forwardWithErrors(HttpServletRequest req, HttpServletResponse resp,
                                   List<String> errors, PricingRule editRule)
            throws ServletException, IOException {
        req.setAttribute("errors", errors);
        preserveFormInput(req);
        if (editRule != null) {
            req.setAttribute("editRule", editRule);
            req.setAttribute("selectedDays", PricingRuleValidator.daySetFromCsv(
                    req.getParameterValues("days") != null
                            ? String.join(",", req.getParameterValues("days"))
                            : editRule.getDayOfWeek()));
        } else if (req.getParameterValues("days") != null) {
            req.setAttribute("selectedDays",
                    PricingRuleValidator.daySetFromCsv(String.join(",", req.getParameterValues("days"))));
        }
        loadAndForward(req, resp);
    }

    private void preserveFormInput(HttpServletRequest req) {
        req.setAttribute("inputRuleName", req.getParameter("ruleName"));
        req.setAttribute("inputConditionType", req.getParameter("conditionType"));
        req.setAttribute("inputTimeFrom", req.getParameter("timeFrom"));
        req.setAttribute("inputTimeTo", req.getParameter("timeTo"));
        req.setAttribute("inputDateFrom", req.getParameter("dateFrom"));
        req.setAttribute("inputDateTo", req.getParameter("dateTo"));
        req.setAttribute("inputAdjustmentType", req.getParameter("adjustmentType"));
        req.setAttribute("inputAdjustmentValue", req.getParameter("adjustmentValue"));
        req.setAttribute("inputPriority", req.getParameter("priority"));
        req.setAttribute("inputStatus", req.getParameter("status"));
    }

    private void loadAndForward(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String keyword = trim(req.getParameter("keyword"));
        String status = trim(req.getParameter("status"));
        if (status != null && !"ACTIVE".equals(status) && !"INACTIVE".equals(status)) {
            status = null;
        }
        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));

        int total = pricingRuleDAO.countFiltered(keyword, status);
        int totalPages = AdminPaginationUtil.totalPages(total, PAGE_SIZE);
        page = AdminPaginationUtil.clampPage(page, totalPages);
        int offset = AdminPaginationUtil.offset(page, PAGE_SIZE);

        List<PricingRule> rules = pricingRuleDAO.findFiltered(keyword, status, offset, PAGE_SIZE);

        req.setAttribute("rules", rules);
        req.setAttribute("filterKeyword", keyword);
        req.setAttribute("filterStatus", status);
        req.setAttribute("totalRules", total);
        req.setAttribute("pgCurrent", page);
        req.setAttribute("pgTotal", totalPages);
        req.setAttribute("pgTotalItems", total);
        req.setAttribute("pgPath", req.getContextPath() + "/admin/pricing-rules");
        req.setAttribute("pgQueryExtra",
                AdminPaginationUtil.queryParam("keyword", keyword)
                        + AdminPaginationUtil.queryParam("status", status));

        req.getRequestDispatcher("/WEB-INF/views/admin/pricing-rule-list.jsp").forward(req, resp);
    }

    private String filterQuery(HttpServletRequest req) {
        return AdminPaginationUtil.queryParam("page", trim(req.getParameter("page")))
                + AdminPaginationUtil.queryParam("keyword", trim(req.getParameter("keyword")))
                + AdminPaginationUtil.queryParam("status", trim(req.getParameter("status")));
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "ADMIN".equals(role);
    }

    private String trim(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }
}
