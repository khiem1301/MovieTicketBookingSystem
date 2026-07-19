package controller.customer;

import dal.BookingDAO;
import dal.MovieReviewDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.SessionUser;
import utils.SessionUtil;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

/** FR-20 — Gửi/cập nhật đánh giá phim (1–5 sao + nhận xét) từ trang chi tiết phim. */
@WebServlet(urlPatterns = {"/reviews/submit"})
public class ReviewSubmitServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String movieId = trim(req.getParameter("movieId"));
        String ratingStr = trim(req.getParameter("rating"));
        String content = trim(req.getParameter("content"));

        if (movieId == null || movieId.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/movies");
            return;
        }

        String redirectBack = req.getContextPath() + "/showtimes?movieId=" + movieId;

        if (!new BookingDAO().hasWatchedMovie(sessionUser.getId(), movieId)) {
            redirectWithError(resp, redirectBack, "Bạn cần mua vé và xem phim này trước khi đánh giá.");
            return;
        }

        MovieReviewDAO reviewDAO = new MovieReviewDAO();
        if (reviewDAO.countDeletionsByUserAndMovie(sessionUser.getId(), movieId)
                >= MovieReviewDAO.DELETION_BAN_THRESHOLD) {
            redirectWithError(resp, redirectBack,
                    "Bạn đã bị xóa đánh giá phim này quá nhiều lần nên không thể đánh giá lại.");
            return;
        }

        int rating;
        try {
            rating = Integer.parseInt(ratingStr);
        } catch (NumberFormatException e) {
            redirectWithError(resp, redirectBack, "Vui lòng chọn số sao đánh giá.");
            return;
        }
        if (rating < 1 || rating > 5) {
            redirectWithError(resp, redirectBack, "Số sao đánh giá không hợp lệ.");
            return;
        }
        if (content != null && content.length() > 2000) {
            redirectWithError(resp, redirectBack, "Nhận xét tối đa 2000 ký tự.");
            return;
        }

        try {
            reviewDAO.upsert(movieId, sessionUser.getId(), rating, content);
        } catch (RuntimeException e) {
            redirectWithError(resp, redirectBack, "Không thể lưu đánh giá. Vui lòng thử lại.");
            return;
        }

        resp.sendRedirect(redirectBack + "&reviewSuccess=1#movie-reviews-section");
    }

    private String trim(String v) { return v == null ? null : v.trim(); }

    private void redirectWithError(HttpServletResponse resp, String redirectBack, String message)
            throws IOException {
        resp.sendRedirect(redirectBack + "&reviewError="
                + URLEncoder.encode(message, StandardCharsets.UTF_8));
    }
}
