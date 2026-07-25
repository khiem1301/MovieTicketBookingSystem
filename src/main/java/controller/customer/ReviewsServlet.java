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

    private static final int MOVIE_PAGE_SIZE = 8;
    /** Public /reviews?sort=latest */
    private static final int REVIEW_PAGE_SIZE = 10;
    /** /reviews/mine — cột phải "Đánh giá của bạn". */
    private static final int MINE_REVIEW_PAGE_SIZE = 6;
    /** /reviews/mine — cột trái "Phim bạn có thể đánh giá". */
    private static final int PENDING_PAGE_SIZE = 5;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        MovieReviewDAO dao = new MovieReviewDAO();
        boolean isMine = req.getServletPath().endsWith("/mine");
        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));

        List<Movie> movies = Collections.emptyList();
        List<MovieReview> reviews = Collections.emptyList();
        List<Movie> pendingMovies = Collections.emptyList();
        List<Movie> allPending = Collections.emptyList();
        List<MovieReview> allMyReviews = null;
        int total = 0;
        int pendingTotal = 0;
        String dbError = null;

        try {
            if (isMine) {
                SessionUser sessionUser = SessionUtil.getLoggedUser(req);
                if (sessionUser == null) {
                    resp.sendRedirect(req.getContextPath() + "/login");
                    return;
                }
                // Lấy full list rồi slice chung theo page (2 cột dùng chung phân trang)
                total = dao.countByUser(sessionUser.getId());
                if (total > 0) {
                    allMyReviews = dao.findByUser(sessionUser.getId(), 0, total);
                } else {
                    allMyReviews = Collections.emptyList();
                }

                Set<String> reviewedIds = dao.findReviewedMovieIds(sessionUser.getId());
                allPending = new BookingDAO().findWatchedMovies(sessionUser.getId()).stream()
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
            if (isMine) {
                allMyReviews = Collections.emptyList();
                allPending = Collections.emptyList();
            }
        }

        // /reviews/mine — 2 cột dùng chung ?page=
        // Trái 5/trang, phải 6/trang; totalPages = max(2 bên)
        if (isMine) {
            if (allMyReviews == null) allMyReviews = Collections.emptyList();
            total = allMyReviews.size();
            pendingTotal = allPending.size();

            int reviewPages = AdminPaginationUtil.totalPages(total, MINE_REVIEW_PAGE_SIZE);
            int pendingPages = AdminPaginationUtil.totalPages(pendingTotal, PENDING_PAGE_SIZE);
            int totalPages = Math.max(reviewPages, pendingPages);

            page = AdminPaginationUtil.clampPage(
                    AdminPaginationUtil.parsePage(req.getParameter("page")), totalPages);

            reviews = pageOf(allMyReviews, page, MINE_REVIEW_PAGE_SIZE);
            pendingMovies = pageOf(allPending, page, PENDING_PAGE_SIZE);
            req.setAttribute("totalPages", totalPages);
        }

        req.setAttribute("isMine", isMine);
        req.setAttribute("movies", movies);
        req.setAttribute("reviews", reviews);
        req.setAttribute("pendingMovies", pendingMovies);
        req.setAttribute("pendingTotal", pendingTotal);
        req.setAttribute("total", total);
        req.setAttribute("page", page);
        req.setAttribute("dbError", dbError);

        req.getRequestDispatcher("/WEB-INF/views/customer/reviews.jsp").forward(req, resp);
    }

    private static <T> List<T> pageOf(List<T> all, int page, int pageSize) {
        if (all == null || all.isEmpty()) return Collections.emptyList();
        int from = Math.max(0, (page - 1) * pageSize);
        if (from >= all.size()) return Collections.emptyList();
        int to = Math.min(from + pageSize, all.size());
        return all.subList(from, to);
    }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
