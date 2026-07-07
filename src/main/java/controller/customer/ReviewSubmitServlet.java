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
            resp.sendRedirect(redirectBack + "&reviewError=Ban+can+mua+ve+va+xem+phim+nay+truoc");
            return;
        }

        int rating;
        try {
            rating = Integer.parseInt(ratingStr);
        } catch (NumberFormatException e) {
            resp.sendRedirect(redirectBack + "&reviewError=Vui+long+chon+so+sao+danh+gia");
            return;
        }
        if (rating < 1 || rating > 5) {
            resp.sendRedirect(redirectBack + "&reviewError=So+sao+danh+gia+khong+hop+le");
            return;
        }

        try {
            new MovieReviewDAO().upsert(movieId, sessionUser.getId(), rating, content);
        } catch (RuntimeException e) {
            resp.sendRedirect(redirectBack + "&reviewError=Khong+the+luu+danh+gia");
            return;
        }

        resp.sendRedirect(redirectBack + "&reviewSuccess=1#movie-reviews-section");
    }

    private String trim(String v) { return v == null ? null : v.trim(); }
}
