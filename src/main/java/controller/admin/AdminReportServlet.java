package controller.admin;

import dal.BookingStatsDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.BookingOverviewStatsDTO;
import model.dto.TopMovieStatsDTO;
import utils.AdminAuthUtil;
import utils.AdminPaginationUtil;
import utils.ReportDateUtil;

import java.io.IOException;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/reports"})
public class AdminReportServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/reports.jsp";
    private static final int PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String range = req.getParameter("range");
        String from = req.getParameter("from");
        String to = req.getParameter("to");

        ReportDateUtil.ResolveResult resolved = ReportDateUtil.resolve(range, from, to);
        ReportDateUtil.DateRange dateRange = resolved.range();

        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));
        BookingStatsDAO statsDAO = new BookingStatsDAO();
        BookingOverviewStatsDTO overview = statsDAO.getOverviewStats(
                dateRange.fromInclusive(), dateRange.toExclusive());

        int topMoviesTotal = statsDAO.countTopMovies(
                dateRange.fromInclusive(), dateRange.toExclusive());
        int totalPages = AdminPaginationUtil.totalPages(topMoviesTotal, PAGE_SIZE);
        page = AdminPaginationUtil.clampPage(page, totalPages);
        List<TopMovieStatsDTO> topMovies = statsDAO.findTopMoviesByTickets(
                dateRange.fromInclusive(), dateRange.toExclusive(),
                AdminPaginationUtil.offset(page, PAGE_SIZE), PAGE_SIZE);

        String pgQueryExtra = AdminPaginationUtil.queryParam("range", dateRange.rangeKey())
                + AdminPaginationUtil.queryParam("from", from)
                + AdminPaginationUtil.queryParam("to", to);

        req.setAttribute("overview", overview);
        req.setAttribute("topMovies", topMovies);
        req.setAttribute("topMoviesTotal", topMoviesTotal);
        req.setAttribute("currentPage", page);
        req.setAttribute("totalPages", totalPages);
        req.setAttribute("rankStart", AdminPaginationUtil.rankStart(page, PAGE_SIZE));
        req.setAttribute("pgCurrent", page);
        req.setAttribute("pgTotal", totalPages);
        req.setAttribute("pgTotalItems", topMoviesTotal);
        req.setAttribute("pgPath", req.getContextPath() + "/admin/reports");
        req.setAttribute("pgQueryExtra", pgQueryExtra);
        req.setAttribute("filterRange", dateRange.rangeKey());
        req.setAttribute("filterFrom", from);
        req.setAttribute("filterTo", to);
        req.setAttribute("rangeLabel", dateRange.label());
        req.setAttribute("dateRangeWarning", resolved.warning());
        req.setAttribute("flashSuccess", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_SUCCESS));
        req.setAttribute("flashError", AdminAuthUtil.consumeFlash(req, AdminAuthUtil.FLASH_ERROR));

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }
}
