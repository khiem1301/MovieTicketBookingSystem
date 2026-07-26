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
    private final MovieReviewDAO reviewDAO = new MovieReviewDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        List<MovieReview> reviews = reviewDAO.findAllOrdered();

        req.setAttribute("reviews", reviews);

        req.getRequestDispatcher("/WEB-INF/views/manager/review-list.jsp").forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        String reviewId = trim(req.getParameter("id"));
        String reason = trim(req.getParameter("reason"));
        boolean sendEmail = "true".equals(req.getParameter("sendEmail"));

        if (reviewId == null || reason == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/reviews?error=reason-required");
            return;
        }

        SessionUser manager = SessionUtil.getLoggedUser(req);
        Optional<MovieReview> reviewOpt = reviewDAO.findById(reviewId);
        boolean deleted = reviewDAO.deleteByManager(reviewId, reason, manager != null ? manager.getId() : null);

        if (deleted && sendEmail && reviewOpt.isPresent()) {
            notifyCustomer(reviewOpt.get(), reason);
        }

        resp.sendRedirect(req.getContextPath() + "/manager/reviews?success=deleted");
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
        return "MANAGER".equals(role);
    }

    private String trim(String value) {
        return (value == null || value.isBlank()) ? null : value.trim();
    }
}
