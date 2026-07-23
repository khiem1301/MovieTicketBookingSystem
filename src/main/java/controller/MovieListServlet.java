package controller;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.List;

import dal.GenreDAO;
import dal.MovieDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.Genre;
import model.entity.Movie;
import utils.AdminPaginationUtil;

@WebServlet(urlPatterns = {"/movies"})
public class MovieListServlet extends HttpServlet {

    private static final int PAGE_SIZE = 12;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String status     = blankToNull(req.getParameter("status"));
        String genreId     = blankToNull(req.getParameter("genre"));
        String keyword     = blankToNull(req.getParameter("q"));
        String ageRating   = blankToNull(req.getParameter("ageRating"));

        List<Movie> nowShowing  = Collections.emptyList();
        List<Movie> comingSoon  = Collections.emptyList();
        List<Movie> earlyMovies = Collections.emptyList();
        List<Genre> genres     = Collections.emptyList();
        Genre selectedGenre    = null;
        String dbError         = null;

        int pageShowing = AdminPaginationUtil.parsePage(req.getParameter("pageShowing"));
        int pageComing  = AdminPaginationUtil.parsePage(req.getParameter("pageComing"));
        int pageEarly   = AdminPaginationUtil.parsePage(req.getParameter("pageEarly"));
        int totalShowing = 0, totalComing = 0, totalEarly = 0;
        int totalPagesShowing = 1, totalPagesComing = 1, totalPagesEarly = 1;

        try {
            MovieDAO dao = new MovieDAO();
            dao.promoteReleasedMovies();

            if (status == null || "NOW_SHOWING".equals(status)) {
                totalShowing     = dao.countPublicMovies("NOW_SHOWING", genreId, keyword, ageRating);
                totalPagesShowing = AdminPaginationUtil.totalPages(totalShowing, PAGE_SIZE);
                pageShowing       = AdminPaginationUtil.clampPage(pageShowing, totalPagesShowing);
                nowShowing = dao.searchPublicMovies("NOW_SHOWING", genreId, keyword, ageRating,
                        AdminPaginationUtil.offset(pageShowing, PAGE_SIZE), PAGE_SIZE);
            }
            if (status == null || "COMING_SOON".equals(status)) {
                totalComing      = dao.countPublicMovies("COMING_SOON", genreId, keyword, ageRating);
                totalPagesComing = AdminPaginationUtil.totalPages(totalComing, PAGE_SIZE);
                pageComing        = AdminPaginationUtil.clampPage(pageComing, totalPagesComing);
                comingSoon = dao.searchPublicMovies("COMING_SOON", genreId, keyword, ageRating,
                        AdminPaginationUtil.offset(pageComing, PAGE_SIZE), PAGE_SIZE);
            }
            if (status == null || "EARLY".equals(status)) {
                totalEarly      = dao.countEarlyShowtimeMovies(genreId, keyword, ageRating);
                totalPagesEarly = AdminPaginationUtil.totalPages(totalEarly, PAGE_SIZE);
                pageEarly         = AdminPaginationUtil.clampPage(pageEarly, totalPagesEarly);
                earlyMovies = dao.searchEarlyShowtimeMovies(genreId, keyword, ageRating,
                        AdminPaginationUtil.offset(pageEarly, PAGE_SIZE), PAGE_SIZE);
            }
            genres = dao.getAllGenres();
            if (genreId != null) {
                selectedGenre = new GenreDAO().getById(genreId);
            }
        } catch (Throwable t) {
            Throwable cause = (t.getCause() != null) ? t.getCause() : t;
            dbError = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            log("MovieListServlet: DB unavailable — " + dbError);
        }

        String filterQuery = buildFilterQuery(status, genreId, ageRating, keyword);

        req.setAttribute("nowShowingMovies", nowShowing);
        req.setAttribute("comingSoonMovies", comingSoon);
        req.setAttribute("earlyMovies",      earlyMovies);
        req.setAttribute("genreList",        genres);
        req.setAttribute("selectedGenre",    selectedGenre);
        req.setAttribute("activeStatus",     status);
        req.setAttribute("searchKeyword",    keyword);
        req.setAttribute("selectedAgeRating",ageRating);
        req.setAttribute("dbError",          dbError);
        req.setAttribute("filterQuery",      filterQuery);

        req.setAttribute("pageShowing",      pageShowing);
        req.setAttribute("totalPagesShowing",totalPagesShowing);
        req.setAttribute("pageComing",       pageComing);
        req.setAttribute("totalPagesComing", totalPagesComing);
        req.setAttribute("pageEarly",        pageEarly);
        req.setAttribute("totalPagesEarly",  totalPagesEarly);

        req.getRequestDispatcher("/WEB-INF/views/common/movies.jsp")
           .forward(req, resp);
    }

    /** Query string chung (không gồm tham số trang) để giữ lại bộ lọc khi chuyển trang. */
    private String buildFilterQuery(String status, String genreId, String ageRating, String keyword) {
        StringBuilder sb = new StringBuilder();
        if (status != null)     sb.append("&status=").append(enc(status));
        if (genreId != null)    sb.append("&genre=").append(enc(genreId));
        if (ageRating != null)  sb.append("&ageRating=").append(enc(ageRating));
        if (keyword != null)    sb.append("&q=").append(enc(keyword));
        return sb.toString();
    }

    private String enc(String v) { return URLEncoder.encode(v, StandardCharsets.UTF_8); }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
