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
// Servlet xử lý trang chủ, hiển thị các bộ phim nổi bật, đang chiếu và sắp chiếu
@WebServlet(urlPatterns = {"/home"})
public class HomeServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        List<Movie> featured    = Collections.emptyList();
        List<Movie> nowShowing  = Collections.emptyList();
        List<Movie> comingSoon  = Collections.emptyList();
        List<Movie> earlyMovies = Collections.emptyList();
        List<Genre> genres      = Collections.emptyList();

        String dbError = null;
        try {
            MovieDAO dao = new MovieDAO();
            featured   = dao.getFeaturedMovies(4);
            nowShowing  = dao.getMoviesByStatus("NOW_SHOWING", 8);
            comingSoon  = dao.getMoviesByStatus("COMING_SOON", 8);
            earlyMovies = dao.getEarlyShowtimeMovies(8);
            genres      = dao.getAllGenres();
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

        req.getRequestDispatcher("/WEB-INF/views/common/home.jsp")
           .forward(req, resp);
    }
}
