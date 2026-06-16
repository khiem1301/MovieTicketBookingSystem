package controller.admin;

import dal.BookingStatsDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.TopMovieStatsDTO;
import model.dto.TopShowtimeStatsDTO;
import utils.AdminAuthUtil;
import utils.ReportDateUtil;
import utils.ReportExportUtil;
import utils.TicketStatsViewUtil;

import java.io.IOException;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/reports/export-tickets"})
public class AdminReportExportTicketsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        String range = req.getParameter("range");
        String from = req.getParameter("from");
        String to = req.getParameter("to");
        String viewBy = TicketStatsViewUtil.normalizeViewBy(req.getParameter("viewBy"));

        ReportDateUtil.ResolveResult resolved = ReportDateUtil.resolve(range, from, to);
        ReportDateUtil.DateRange dateRange = resolved.range();
        BookingStatsDAO statsDAO = new BookingStatsDAO();

        byte[] csv;
        if (TicketStatsViewUtil.isShowtimeView(viewBy)) {
            List<TopShowtimeStatsDTO> rows = statsDAO.findTicketStatsByShowtime(
                    dateRange.fromInclusive(), dateRange.toExclusive(),
                    0, BookingStatsDAO.EXPORT_ROW_LIMIT);
            csv = ReportExportUtil.buildShowtimeTicketCsvBytes(rows, dateRange.label());
        } else {
            List<TopMovieStatsDTO> rows = statsDAO.findTopMoviesByTickets(
                    dateRange.fromInclusive(), dateRange.toExclusive(),
                    0, BookingStatsDAO.EXPORT_ROW_LIMIT);
            csv = ReportExportUtil.buildMovieTicketCsvBytes(rows, dateRange.label());
        }

        String filename = ReportExportUtil.buildTicketFilename(viewBy, dateRange.rangeKey());

        resp.setCharacterEncoding("UTF-8");
        resp.setContentType("text/csv; charset=UTF-8");
        resp.setHeader("Content-Disposition", "attachment; filename=\"" + filename + "\"");
        resp.setContentLength(csv.length);
        resp.getOutputStream().write(csv);
        resp.getOutputStream().flush();
    }
}
