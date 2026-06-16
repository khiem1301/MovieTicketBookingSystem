package controller.admin;

import dal.BookingStatsDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.RevenuePeriodStatsDTO;
import utils.AdminAuthUtil;
import utils.ReportDateUtil;
import utils.ReportExportUtil;

import java.io.IOException;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/reports/export"})
public class AdminReportExportServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String range = req.getParameter("range");
        String from = req.getParameter("from");
        String to = req.getParameter("to");
        String groupBy = ReportExportUtil.normalizeGroupBy(req.getParameter("groupBy"));

        ReportDateUtil.ResolveResult resolved = ReportDateUtil.resolve(range, from, to);
        ReportDateUtil.DateRange dateRange = resolved.range();

        List<RevenuePeriodStatsDTO> rows = new BookingStatsDAO().findRevenueByPeriod(
                dateRange.fromInclusive(), dateRange.toExclusive(), groupBy);

        byte[] csv = ReportExportUtil.buildCsvBytes(rows, dateRange.label(), groupBy);
        String filename = ReportExportUtil.buildFilename(groupBy, dateRange.rangeKey());

        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        resp.setContentLength(csv.length);
        resp.getOutputStream().write(csv);
        resp.getOutputStream().flush();
    }
}
