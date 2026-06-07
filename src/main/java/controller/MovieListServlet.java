package controller;

import java.io.IOException;
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

@WebServlet(urlPatterns = {"/movies"})
public class MovieListServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String status  = blankToNull(req.getParameter("status"));
        String genreId = blankToNull(req.getParameter("genre"));
        String keyword = blankToNull(req.getParameter("q"));

        List<Movie> nowShowing  = Collections.emptyList();
        List<Movie> comingSoon  = Collections.emptyList();
        List<Movie> earlyMovies = Collections.emptyList();
        List<Genre> genres     = Collections.emptyList();
        Genre selectedGenre    = null;
        String dbError         = null;

        try {
            MovieDAO dao = new MovieDAO();
            if (status == null || "NOW_SHOWING".equals(status)) {
                nowShowing = dao.searchPublicMovies("NOW_SHOWING", genreId, keyword);
            }
            if (status == null || "COMING_SOON".equals(status)) {
                comingSoon = dao.searchPublicMovies("COMING_SOON", genreId, keyword);
            }
            if (status == null || "EARLY".equals(status)) {
                earlyMovies = dao.searchEarlyShowtimeMovies(genreId, keyword);
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

        req.setAttribute("nowShowingMovies", nowShowing);
        req.setAttribute("comingSoonMovies", comingSoon);
        req.setAttribute("earlyMovies",      earlyMovies);
        req.setAttribute("genreList",        genres);
        req.setAttribute("selectedGenre",    selectedGenre);
        req.setAttribute("activeStatus",     status);
        req.setAttribute("searchKeyword",    keyword);
        req.setAttribute("dbError",          dbError);

        req.getRequestDispatcher("/WEB-INF/views/common/movies.jsp")
           .forward(req, resp);
    }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
