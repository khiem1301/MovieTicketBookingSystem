package controller.customer;

import dal.BookingDAO;
import dal.MovieReviewDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.SessionUser;
import model.entity.Movie;
import model.entity.MovieReview;
import utils.AdminPaginationUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * FR-20 — Trang duyệt đánh giá: /reviews?sort=top|latest|popular và /reviews/mine.
 */
@WebServlet(urlPatterns = {"/reviews", "/reviews/mine"})
public class ReviewsServlet extends HttpServlet {

    private static final int MOVIE_PAGE_SIZE  = 8;
    private static final int REVIEW_PAGE_SIZE = 10;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        MovieReviewDAO dao = new MovieReviewDAO();
        boolean isMine = req.getServletPath().endsWith("/mine");
        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));

        List<Movie> movies = Collections.emptyList();
        List<MovieReview> reviews = Collections.emptyList();
        List<Movie> pendingMovies = Collections.emptyList();
        int total = 0;
        String dbError = null;

        try {
            if (isMine) {
                SessionUser sessionUser = SessionUtil.getLoggedUser(req);
                if (sessionUser == null) {
                    resp.sendRedirect(req.getContextPath() + "/login");
                    return;
                }
                total = dao.countByUser(sessionUser.getId());
                int totalPages = AdminPaginationUtil.totalPages(total, REVIEW_PAGE_SIZE);
                page = AdminPaginationUtil.clampPage(page, totalPages);
                reviews = dao.findByUser(sessionUser.getId(),
                        AdminPaginationUtil.offset(page, REVIEW_PAGE_SIZE), REVIEW_PAGE_SIZE);
                req.setAttribute("totalPages", totalPages);

                Set<String> reviewedIds = dao.findReviewedMovieIds(sessionUser.getId());
                pendingMovies = new BookingDAO().findWatchedMovies(sessionUser.getId()).stream()
                        .filter(m -> !reviewedIds.contains(m.getId()))
                        .collect(Collectors.toList());
            } else {
                String sort = blankToNull(req.getParameter("sort"));
                if (sort == null) sort = "top";

                if ("latest".equals(sort)) {
                    total = dao.countLatest();
                    int totalPages = AdminPaginationUtil.totalPages(total, REVIEW_PAGE_SIZE);
                    page = AdminPaginationUtil.clampPage(page, totalPages);
                    reviews = dao.findLatest(
                            AdminPaginationUtil.offset(page, REVIEW_PAGE_SIZE), REVIEW_PAGE_SIZE);
                    req.setAttribute("totalPages", totalPages);
                } else if ("popular".equals(sort)) {
                    total = dao.countReviewedMovies();
                    int totalPages = AdminPaginationUtil.totalPages(total, MOVIE_PAGE_SIZE);
                    page = AdminPaginationUtil.clampPage(page, totalPages);
                    movies = dao.findMostReviewedMovies(
                            AdminPaginationUtil.offset(page, MOVIE_PAGE_SIZE), MOVIE_PAGE_SIZE);
                    req.setAttribute("totalPages", totalPages);
                } else {
                    sort = "top";
                    total = dao.countReviewedMovies();
                    int totalPages = AdminPaginationUtil.totalPages(total, MOVIE_PAGE_SIZE);
                    page = AdminPaginationUtil.clampPage(page, totalPages);
                    movies = dao.findTopRatedMovies(
                            AdminPaginationUtil.offset(page, MOVIE_PAGE_SIZE), MOVIE_PAGE_SIZE);
                    req.setAttribute("totalPages", totalPages);
                }
                req.setAttribute("sort", sort);
            }
        } catch (Throwable t) {
            Throwable cause = (t.getCause() != null) ? t.getCause() : t;
            dbError = cause.getClass().getSimpleName() + ": " + cause.getMessage();
            log("ReviewsServlet: DB unavailable — " + dbError);
        }

        req.setAttribute("isMine",  isMine);
        req.setAttribute("movies",  movies);
        req.setAttribute("reviews", reviews);
        req.setAttribute("pendingMovies", pendingMovies);
        req.setAttribute("page",    page);
        req.setAttribute("dbError", dbError);

        req.getRequestDispatcher("/WEB-INF/views/customer/reviews.jsp").forward(req, resp);
    }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
