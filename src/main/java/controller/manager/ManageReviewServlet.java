package controller.manager;

import dal.MovieReviewDAO;
import dal.UserDAO;
import jakarta.mail.MessagingException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.SessionUser;
import model.entity.MovieReview;
import model.entity.User;
import utils.AdminPaginationUtil;
import utils.EmailUtil;
import utils.SessionUtil;

import java.io.IOException;
import java.util.List;
import java.util.Optional;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Manager/Admin duyệt và xóa đánh giá vi phạm của khách hàng. */
@WebServlet(urlPatterns = {"/manager/reviews"})
public class ManageReviewServlet extends HttpServlet {

    private static final Logger LOG = Logger.getLogger(ManageReviewServlet.class.getName());
    private static final int PAGE_SIZE = AdminPaginationUtil.DEFAULT_PAGE_SIZE;
    private final MovieReviewDAO reviewDAO = new MovieReviewDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        String movieTitle = trim(req.getParameter("q"));
        Integer rating = parseRating(req.getParameter("rating"));
        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));

        int total = reviewDAO.countAllFiltered(movieTitle, rating);
        int totalPages = AdminPaginationUtil.totalPages(total, PAGE_SIZE);
        page = AdminPaginationUtil.clampPage(page, totalPages);
        int offset = AdminPaginationUtil.offset(page, PAGE_SIZE);

        List<MovieReview> reviews = reviewDAO.findAllFiltered(movieTitle, rating, offset, PAGE_SIZE);

        req.setAttribute("reviews", reviews);
        req.setAttribute("filterQ", movieTitle);
        req.setAttribute("filterRating", rating);
        req.setAttribute("totalReviews", total);
        req.setAttribute("pgCurrent", page);
        req.setAttribute("pgTotal", totalPages);
        req.setAttribute("pgTotalItems", total);
        req.setAttribute("pgPath", req.getContextPath() + "/manager/reviews");
        req.setAttribute("pgQueryExtra",
                AdminPaginationUtil.queryParam("q", movieTitle)
                        + AdminPaginationUtil.queryParam("rating", rating != null ? String.valueOf(rating) : null));

        req.getRequestDispatcher("/WEB-INF/views/manager/review-list.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        String reviewId = trim(req.getParameter("id"));
        String reason = trim(req.getParameter("reason"));
        boolean sendEmail = "true".equals(req.getParameter("sendEmail"));
        String returnQuery = AdminPaginationUtil.queryParam("page", trim(req.getParameter("page")))
                + AdminPaginationUtil.queryParam("q", trim(req.getParameter("q")))
                + AdminPaginationUtil.queryParam("rating", trim(req.getParameter("rating")));

        if (reviewId == null || reason == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/reviews?error=reason-required" + returnQuery);
            return;
        }

        SessionUser manager = SessionUtil.getLoggedUser(req);
        Optional<MovieReview> reviewOpt = reviewDAO.findById(reviewId);
        boolean deleted = reviewDAO.deleteByManager(reviewId, reason, manager != null ? manager.getId() : null);

        if (deleted && sendEmail && reviewOpt.isPresent()) {
            notifyCustomer(reviewOpt.get(), reason);
        }

        resp.sendRedirect(req.getContextPath() + "/manager/reviews?success=deleted" + returnQuery);
    }

    /** Gửi email thông báo lý do gỡ đánh giá — thất bại không chặn việc xóa. */
    private void notifyCustomer(MovieReview review, String reason) {
        Optional<User> userOpt = new UserDAO().findById(review.getUserId());
        if (userOpt.isEmpty()) return;

        String email = userOpt.get().getEmail();
        if (email == null || email.isBlank() || !EmailUtil.isConfigured()) return;

        try {
            EmailUtil.sendReviewDeletedEmail(email, userOpt.get().getFullName(), review.getMovieTitle(), reason);
        } catch (MessagingException ex) {
            LOG.log(Level.WARNING, "Failed to send review-deleted notification to " + email, ex);
        }
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role) || "ADMIN".equals(role);
    }

    private Integer parseRating(String raw) {
        if (raw == null || raw.isBlank()) return null;
        try {
            int r = Integer.parseInt(raw.trim());
            return (r >= 1 && r <= 5) ? r : null;
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String trim(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }
}
