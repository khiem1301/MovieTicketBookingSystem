package controller;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

import dal.MovieDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.Genre;
import model.entity.Movie;
import utils.AdminPaginationUtil;
// Servlet xử lý trang chủ, hiển thị các bộ phim nổi bật, đang chiếu và sắp chiếu
@WebServlet(urlPatterns = {"/home"})
public class HomeServlet extends HttpServlet {

    private static final int PAGE_SIZE = 4;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        List<Movie> featured    = Collections.emptyList();
        List<Movie> nowShowing  = Collections.emptyList();
        List<Movie> comingSoon  = Collections.emptyList();
        List<Movie> earlyMovies = Collections.emptyList();
        List<Genre> genres      = Collections.emptyList();

        int pageShowing = AdminPaginationUtil.parsePage(req.getParameter("pageShowing"));
        int pageComing  = AdminPaginationUtil.parsePage(req.getParameter("pageComing"));
        int pageEarly   = AdminPaginationUtil.parsePage(req.getParameter("pageEarly"));
        int totalPagesShowing = 1, totalPagesComing = 1, totalPagesEarly = 1;

        String dbError = null;
        try {
            MovieDAO dao = new MovieDAO();
            dao.promoteReleasedMovies();
            featured = dao.getFeaturedMovies(4);

            int totalShowing = dao.countPublicMovies("NOW_SHOWING", null, null, null);
            totalPagesShowing = AdminPaginationUtil.totalPages(totalShowing, PAGE_SIZE);
            pageShowing        = AdminPaginationUtil.clampPage(pageShowing, totalPagesShowing);
            nowShowing = dao.searchPublicMovies("NOW_SHOWING", null, null, null,
                    AdminPaginationUtil.offset(pageShowing, PAGE_SIZE), PAGE_SIZE);

            int totalComing = dao.countPublicMovies("COMING_SOON", null, null, null);
            totalPagesComing = AdminPaginationUtil.totalPages(totalComing, PAGE_SIZE);
            pageComing        = AdminPaginationUtil.clampPage(pageComing, totalPagesComing);
            comingSoon = dao.searchPublicMovies("COMING_SOON", null, null, null,
                    AdminPaginationUtil.offset(pageComing, PAGE_SIZE), PAGE_SIZE);

            int totalEarly = dao.countEarlyShowtimeMovies(null, null, null);
            totalPagesEarly = AdminPaginationUtil.totalPages(totalEarly, PAGE_SIZE);
            pageEarly         = AdminPaginationUtil.clampPage(pageEarly, totalPagesEarly);
            earlyMovies = dao.searchEarlyShowtimeMovies(null, null, null,
                    AdminPaginationUtil.offset(pageEarly, PAGE_SIZE), PAGE_SIZE);

            genres = dao.getAllGenres();
        } catch (Throwable t) {
            // DB chưa cấu hình hoặc không kết nối được — trang vẫn render với data rỗng
            Throwable cause = (t.getCause() != null) ? t.getCause() : t;
            dbError = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            log("HomeServlet: DB unavailable — " + dbError);
        }

        req.setAttribute("featuredMovies",   featured);
        req.setAttribute("nowShowingMovies", nowShowing);
        req.setAttribute("comingSoonMovies", comingSoon);
        req.setAttribute("earlyMovies",      earlyMovies);
        req.setAttribute("genreList",        genres);
        req.setAttribute("dbError",          dbError);

        req.setAttribute("pageShowing",      pageShowing);
        req.setAttribute("totalPagesShowing",totalPagesShowing);
        req.setAttribute("pageComing",       pageComing);
        req.setAttribute("totalPagesComing", totalPagesComing);
        req.setAttribute("pageEarly",        pageEarly);
        req.setAttribute("totalPagesEarly",  totalPagesEarly);

        req.getRequestDispatcher("/WEB-INF/views/common/home.jsp")
           .forward(req, resp);
    }
}
