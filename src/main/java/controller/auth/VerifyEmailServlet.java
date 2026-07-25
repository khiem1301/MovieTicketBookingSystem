package controller.auth;

import dal.PendingRegistrationDAO;
import dal.RoleDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.PendingRegistration;
import model.entity.Role;
import model.entity.User;
import utils.RegisterValidator;

import java.io.IOException;
import java.util.Optional;

/**
 * FR-01 — Sau khi click link email: tạo Users với status ACTIVE.
 */
@WebServlet(urlPatterns = {"/verify-email"})
public class VerifyEmailServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String token = trim(req.getParameter("token"));
        if (token == null || token.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/login?verify=invalid");
            return;
        }

        try {
            PendingRegistrationDAO pendingDAO = new PendingRegistrationDAO();
            Optional<PendingRegistration> found = pendingDAO.findValidByToken(token);
            if (found.isEmpty()) {
                resp.sendRedirect(req.getContextPath() + "/login?verify=invalid");
                return;
            }

            PendingRegistration pending = found.get();
            UserDAO userDAO = new UserDAO();

            if (userDAO.existsByEmail(pending.getEmail())) {
                pendingDAO.deleteById(pending.getId());
                resp.sendRedirect(req.getContextPath() + "/login?verify=already");
                return;
            }
            if (userDAO.existsByPhone(pending.getPhoneNumber())) {
                pendingDAO.deleteById(pending.getId());
                resp.sendRedirect(req.getContextPath() + "/register?verify=phone_taken");
                return;
            }

            Optional<Role> customerRole = new RoleDAO().findByName("CUSTOMER");
            if (customerRole.isEmpty()) {
                resp.sendRedirect(req.getContextPath() + "/login?verify=error");
                return;
            }

            String username = RegisterValidator.generateUsername(
                    userDAO, pending.getEmail(), pending.getPhoneNumber());

            User user = new User();
            user.setRoleId(customerRole.get().getId());
            user.setEmail(pending.getEmail());
            user.setUsername(username);
            user.setPhoneNumber(pending.getPhoneNumber());
            user.setFullName(pending.getFullName());
            user.setDateOfBirth(pending.getDateOfBirth());
            user.setPasswordHash(pending.getPasswordHash());
            user.setStatus("ACTIVE");

            userDAO.insert(user);
            pendingDAO.markUsed(pending.getId());
            pendingDAO.deleteExpired();

            resp.sendRedirect(req.getContextPath() + "/login?verified=1");
        } catch (RuntimeException ex) {
            log("VerifyEmailServlet: error", ex);
            resp.sendRedirect(req.getContextPath() + "/login?verify=error");
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
