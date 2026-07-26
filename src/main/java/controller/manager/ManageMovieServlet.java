package controller.manager;

import dal.GenreDAO;
import dal.MovieDAO;
import model.entity.Movie;
import utils.MovieImageUpload;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.sql.Date;
import java.time.LocalDate;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@WebServlet("/manager/movies")
@MultipartConfig(
        fileSizeThreshold = 1024 * 1024,
        maxFileSize       = 5 * 1024 * 1024,
        maxRequestSize    = 12 * 1024 * 1024
)
public class ManageMovieServlet extends HttpServlet {

    private static final Set<String> VALID_STATUS = Set.of("COMING_SOON", "NOW_SHOWING", "ENDED");
    private static final Set<String> VALID_AGE   = Set.of("P", "K", "T13", "T16", "T18", "C");
    private static final int MAX_GENRES = 4;

    private final MovieDAO movieDAO = new MovieDAO();
    private final GenreDAO genreDAO = new GenreDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        if ("edit".equals(req.getParameter("action"))) {
            String id = req.getParameter("id");
            Movie editing = (id != null) ? movieDAO.getById(id) : null;
            if (editing == null) {
                resp.sendRedirect(req.getContextPath() + "/manager/movies");
                return;
            }
            req.setAttribute("editMovie", editing);
            req.setAttribute("selectedGenreIds", movieDAO.getGenreIds(id));
        }

        loadAndForward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        try {
            String action = req.getParameter("action");

            if ("update".equals(action)) {
                handleUpdate(req, resp);
            } else if ("delete".equals(action)) {
                handleDelete(req, resp);
            } else {
                handleCreate(req, resp);
            }
        } catch (IllegalStateException ex) {
            // Anh vuot qua fileSizeThreshold/maxFileSize cua @MultipartConfig
            resp.sendRedirect(req.getContextPath() + "/manager/movies?error=image-too-large");
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        try {
            Movie movie = parseMovie(req, null);
            List<String> genreIds = parseGenreIds(req);
            String error = validate(movie, null, genreIds);

            if (error != null) {
                forwardWithError(req, resp, error, movie, genreIds, null);
                return;
            }

            movieDAO.create(movie, genreIds);
            resp.sendRedirect(req.getContextPath() + "/manager/movies?success=created");
        } catch (IllegalArgumentException ex) {
            forwardWithError(req, resp, ex.getMessage(), parseMovieTextOnly(req), parseGenreIds(req), null);
        }
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = req.getParameter("id");
        Movie existing = (id != null) ? movieDAO.getById(id) : null;
        if (existing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/movies");
            return;
        }

        try {
            Movie movie = parseMovie(req, existing);
            movie.setId(id);
            List<String> genreIds = parseGenreIds(req);
            String error = validate(movie, id, genreIds);

            if (error != null) {
                forwardWithError(req, resp, error, movie, genreIds, existing);
                return;
            }

            movieDAO.update(movie, genreIds);
            resp.sendRedirect(req.getContextPath() + "/manager/movies?success=updated");
        } catch (IllegalArgumentException ex) {
            Movie partial = parseMovie(req, existing);
            partial.setId(id);
            forwardWithError(req, resp, ex.getMessage(), partial, parseGenreIds(req), existing);
        }
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws IOException {
        String id = req.getParameter("id");
        if (id == null || id.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/manager/movies");
            return;
        }
        boolean deleted = movieDAO.delete(id);
        String param = deleted ? "?success=deleted" : "?error=has-showtimes";
        resp.sendRedirect(req.getContextPath() + "/manager/movies" + param);
    }

    private static final java.util.regex.Pattern URL_PATTERN =
            java.util.regex.Pattern.compile("^https?://.+", java.util.regex.Pattern.CASE_INSENSITIVE);

    private String validate(Movie movie, String excludeId, List<String> genreIds) {
        if (movie.getTitle() == null || movie.getTitle().isBlank()) {
            return "Tên phim không được để trống.";
        }
        if (genreIds != null && genreIds.size() > MAX_GENRES) {
            return "Chỉ được chọn tối đa " + MAX_GENRES + " thể loại.";
        }
        if (movie.getTitle().trim().length() > 255) {
            return "Tên phim tối đa 255 ký tự.";
        }
        if (movie.getSlug() == null || movie.getSlug().isBlank()) {
            return "Slug không được để trống.";
        }
        if (movie.getSlug().trim().length() > 255) {
            return "Slug tối đa 255 ký tự.";
        }
        if (movie.getDurationMinutes() < 60) {
            return "Thời lượng phim tối thiểu 60 phút.";
        }
        if (movie.getDurationMinutes() > 600) {
            return "Thời lượng phim tối đa 600 phút.";
        }
        if (movie.getStatus() == null || !VALID_STATUS.contains(movie.getStatus())) {
            return "Trạng thái phim không hợp lệ.";
        }
        if (excludeId == null && "ENDED".equals(movie.getStatus())) {
            return "Khi tạo phim mới chỉ được chọn \"Sắp chiếu\" hoặc \"Đang chiếu\".";
        }
        if (movie.getAgeRating() == null || movie.getAgeRating().isBlank()) {
            return "Độ tuổi xem không được để trống.";
        }
        if (!VALID_AGE.contains(movie.getAgeRating())) {
            return "Độ tuổi xem không hợp lệ.";
        }
        if (movie.getReleaseDate() == null) {
            return "Ngày phát hành không được để trống.";
        }
        if (excludeId == null && movie.getReleaseDate().toLocalDate().isBefore(LocalDate.now())) {
            return "Ngày phát hành không được là ngày trong quá khứ.";
        }
        boolean released = !movie.getReleaseDate().toLocalDate().isAfter(LocalDate.now());
        if ("COMING_SOON".equals(movie.getStatus()) && released) {
            return "Phim đã đến ngày phát hành, không thể để trạng thái \"Sắp chiếu\".";
        }
        if ("NOW_SHOWING".equals(movie.getStatus()) && !released) {
            return "Phim chưa đến ngày phát hành, không thể để trạng thái \"Đang chiếu\".";
        }
        if (movie.getDirector() == null || movie.getDirector().isBlank()) {
            return "Đạo diễn không được để trống.";
        }
        if (movie.getDirector().length() > 255) {
            return "Đạo diễn tối đa 255 ký tự.";
        }
        if (movie.getLanguage() == null || movie.getLanguage().isBlank()) {
            return "Ngôn ngữ không được để trống.";
        }
        if (movie.getLanguage().length() > 50) {
            return "Ngôn ngữ tối đa 50 ký tự.";
        }
        if (movie.getSubtitle() == null || movie.getSubtitle().isBlank()) {
            return "Phụ đề không được để trống.";
        }
        if (movie.getSubtitle().length() > 50) {
            return "Phụ đề tối đa 50 ký tự.";
        }
        if (movie.getDescription() == null || movie.getDescription().isBlank()) {
            return "Mô tả không được để trống.";
        }
        if (movie.getDescription().length() > 4000) {
            return "Mô tả tối đa 4000 ký tự.";
        }
        if (movie.getTrailerUrl() == null || movie.getTrailerUrl().isBlank()) {
            return "Trailer URL không được để trống.";
        }
        if (movie.getTrailerUrl().trim().length() > 500) {
            return "Trailer URL tối đa 500 ký tự.";
        }
        if (!URL_PATTERN.matcher(movie.getTrailerUrl().trim()).matches()) {
            return "Trailer URL không hợp lệ.";
        }
        if (genreIds == null || genreIds.isEmpty()) {
            return "Vui lòng chọn ít nhất 1 thể loại.";
        }

        boolean dupTitle = excludeId == null
                ? movieDAO.isDuplicateTitle(movie.getTitle())
                : movieDAO.isDuplicateTitleExcluding(movie.getTitle(), excludeId);
        if (dupTitle) {
            return "Phim \"" + movie.getTitle().trim() + "\" đã tồn tại.";
        }

        boolean dupSlug = excludeId == null
                ? movieDAO.isDuplicateSlug(movie.getSlug())
                : movieDAO.isDuplicateSlugExcluding(movie.getSlug(), excludeId);
        if (dupSlug) {
            return "Slug \"" + movie.getSlug().trim() + "\" đã được sử dụng.";
        }

        return null;
    }

    private Movie parseMovie(HttpServletRequest req, Movie existing)
            throws ServletException, IOException {
        Movie m = parseMovieTextOnly(req);
        m.setPosterUrl(resolveImage(req, "posterFile", "existingPosterUrl",
                existing != null ? existing.getPosterUrl() : null, "posters"));
        m.setBackdropUrl(resolveImage(req, "backdropFile", "existingBackdropUrl",
                existing != null ? existing.getBackdropUrl() : null, "backdrops"));
        return m;
    }

    private Movie parseMovieTextOnly(HttpServletRequest req) {
        Movie m = new Movie();
        m.setTitle(req.getParameter("title"));
        m.setSlug(normalizeSlug(req.getParameter("slug")));
        m.setDescription(req.getParameter("description"));
        m.setDurationMinutes(parseInt(req.getParameter("durationMinutes"), 0));
        m.setReleaseDate(parseDate(req.getParameter("releaseDate")));
        m.setTrailerUrl(req.getParameter("trailerUrl"));
        m.setDirector(req.getParameter("director"));
        m.setLanguage(req.getParameter("language"));
        m.setSubtitle(req.getParameter("subtitle"));
        m.setAgeRating(blankToNull(req.getParameter("ageRating")));
        m.setStatus(req.getParameter("status"));
        return m;
    }

    private String resolveImage(HttpServletRequest req, String partName,
                                String existingParamName, String existingUrl, String folder)
            throws ServletException, IOException {
        Part part = req.getPart(partName);
        String uploaded = MovieImageUpload.save(req.getServletContext(), part, folder);
        if (uploaded != null) return uploaded;

        String hiddenExisting = req.getParameter(existingParamName);
        if (hiddenExisting != null && !hiddenExisting.isBlank()) return hiddenExisting.trim();

        return existingUrl;
    }

    private List<String> parseGenreIds(HttpServletRequest req) {
        String[] ids = req.getParameterValues("genreIds");
        if (ids == null) return List.of();
        return Arrays.stream(ids)
                .filter(id -> id != null && !id.isBlank())
                .collect(Collectors.toList());
    }

    private String normalizeSlug(String slug) {
        if (slug == null) return null;
        return slug.trim().toLowerCase().replaceAll("\\s+", "-");
    }

    private int parseInt(String value, int defaultVal) {
        if (value == null || value.isBlank()) return defaultVal;
        try { return Integer.parseInt(value.trim()); }
        catch (NumberFormatException e) { return defaultVal; }
    }

    private Date parseDate(String value) {
        if (value == null || value.isBlank()) return null;
        try { return Date.valueOf(value.trim()); }
        catch (IllegalArgumentException e) { return null; }
    }

    private String blankToNull(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }

    private void forwardWithError(HttpServletRequest req, HttpServletResponse resp,
                                  String error, Movie movie, List<String> genreIds,
                                  Movie existing)
            throws ServletException, IOException {
        req.setAttribute("error", error);
        req.setAttribute("formMovie", movie);
        req.setAttribute("selectedGenreIds", genreIds);
        if (existing != null) req.setAttribute("editMovie", existing);
        loadAndForward(req, resp);
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role);
    }

    private void loadAndForward(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        movieDAO.promoteReleasedMovies();
        req.setAttribute("movieList", movieDAO.getAllForManager());
        req.setAttribute("genreList", genreDAO.getAllActive());
        req.setAttribute("movieIdsWithShowtimes", movieDAO.getMovieIdsWithShowtimes());
        req.getRequestDispatcher("/WEB-INF/views/manager/movie-list.jsp").forward(req, resp);
    }
}
