package controller.customer;

import dal.MovieReviewDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.SessionUser;
import utils.SessionUtil;

import java.io.IOException;

/** FR-20 — Xóa đánh giá của chính customer. */
@WebServlet(urlPatterns = {"/reviews/delete"})
public class ReviewDeleteServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String reviewId = trim(req.getParameter("reviewId"));
        String redirectTo = trim(req.getParameter("redirectTo"));
        String fallback = req.getContextPath() + "/reviews/mine";

        if (reviewId == null || reviewId.isBlank()) {
            resp.sendRedirect(fallback);
            return;
        }

        new MovieReviewDAO().delete(reviewId, sessionUser.getId());

        resp.sendRedirect((redirectTo != null && !redirectTo.isBlank())
                ? req.getContextPath() + redirectTo
                : fallback);
    }

    private String trim(String v) { return v == null ? null : v.trim(); }
}
