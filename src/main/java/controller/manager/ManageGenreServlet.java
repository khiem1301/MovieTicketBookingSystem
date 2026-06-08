package controller.manager;

import dal.GenreDAO;
import model.entity.Genre;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

@WebServlet("/manager/genres")
public class ManageGenreServlet extends HttpServlet {

    private final GenreDAO genreDAO = new GenreDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        if ("edit".equals(req.getParameter("action"))) {
            String id = req.getParameter("id");
            Genre editing = (id != null) ? genreDAO.getById(id) : null;
            if (editing != null) {
                if (genreDAO.hasLinkedMovies(id)) {
                    req.setAttribute("error",
                            "Không thể sửa thể loại \"" + editing.getGenreName()
                                    + "\" vì đang có phim sử dụng.");
                } else {
                    req.setAttribute("editGenre", editing);
                }
            }
        }

        loadAndForward(req, resp);
    }

    // POST action=create | update | delete
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) { resp.sendRedirect(req.getContextPath() + "/home"); return; }

        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");

        switch (action != null ? action : "") {
            case "update" -> handleUpdate(req, resp);
            case "delete" -> handleDelete(req, resp);
            default       -> handleCreate(req, resp);
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String name = req.getParameter("genreName");

        if (name == null || name.trim().isEmpty()) {
            req.setAttribute("error", "Tên thể loại không được để trống.");
            req.setAttribute("inputValue", name);
            loadAndForward(req, resp);
            return;
        }
        if (genreDAO.isDuplicate(name)) {
            req.setAttribute("error", "Thể loại \"" + name.trim() + "\" đã tồn tại.");
            req.setAttribute("inputValue", name.trim());
            loadAndForward(req, resp);
            return;
        }

        genreDAO.create(name);
        resp.sendRedirect(req.getContextPath() + "/manager/genres?success=created");
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id   = req.getParameter("id");
        String name = req.getParameter("genreName");

        Genre editing = (id != null) ? genreDAO.getById(id) : null;
        if (editing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/genres");
            return;
        }

        if (name == null || name.trim().isEmpty()) {
            req.setAttribute("error", "Tên thể loại không được để trống.");
            req.setAttribute("inputValue", name);
            req.setAttribute("editGenre", editing);
            loadAndForward(req, resp);
            return;
        }
        if (genreDAO.isDuplicateExcluding(name, id)) {
            req.setAttribute("error", "Thể loại \"" + name.trim() + "\" đã tồn tại.");
            req.setAttribute("inputValue", name.trim());
            req.setAttribute("editGenre", editing);
            loadAndForward(req, resp);
            return;
        }
        if (genreDAO.hasLinkedMovies(id)) {
            req.setAttribute("error",
                    "Không thể sửa thể loại \"" + editing.getGenreName()
                            + "\" vì đang có phim sử dụng.");
            req.setAttribute("editGenre", editing);
            req.setAttribute("inputValue", name != null ? name.trim() : editing.getGenreName());
            loadAndForward(req, resp);
            return;
        }

        genreDAO.update(id, name);
        resp.sendRedirect(req.getContextPath() + "/manager/genres?success=updated");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = req.getParameter("id");
        Genre genre = (id != null) ? genreDAO.getById(id) : null;
        if (genre == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/genres");
            return;
        }
        if (genreDAO.hasLinkedMovies(id)) {
            req.setAttribute("error",
                    "Không thể xóa thể loại \"" + genre.getGenreName()
                            + "\" vì đang có phim sử dụng.");
            loadAndForward(req, resp);
            return;
        }

        genreDAO.delete(id);
        resp.sendRedirect(req.getContextPath() + "/manager/genres?success=deleted");
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role) || "ADMIN".equals(role);
    }

    private void loadAndForward(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("genreList", genreDAO.getAll());
        req.setAttribute("genreIdsInUse", genreDAO.getGenreIdsInUse());
        req.getRequestDispatcher("/WEB-INF/views/manager/genre-list.jsp").forward(req, resp);
    }
}
