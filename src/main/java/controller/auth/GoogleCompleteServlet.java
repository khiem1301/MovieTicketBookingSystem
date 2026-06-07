package controller.auth;

import dal.RoleDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.GoogleSignupInfo;
import model.entity.Role;
import model.entity.User;
import utils.AuthRedirectUtil;
import utils.GoogleOAuthSession;
import utils.PasswordUtil;
import utils.RegisterValidator;
import utils.SessionUtil;

import java.io.IOException;
import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Thu thập ngày sinh (bắt buộc FR-01) sau khi đăng ký / đăng nhập Google lần đầu.
 */
@WebServlet(urlPatterns = {"/register/google-complete"})
public class GoogleCompleteServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/auth/google-complete.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        GoogleSignupInfo pending = GoogleOAuthSession.getPendingSignup(req);
        if (pending == null) {
            resp.sendRedirect(req.getContextPath() + "/login?google=session_expired");
            return;
        }

        req.setAttribute("pending", pending);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        GoogleSignupInfo pending = GoogleOAuthSession.getPendingSignup(req);
        if (pending == null) {
            resp.sendRedirect(req.getContextPath() + "/login?google=session_expired");
            return;
        }

        String phone = trim(req.getParameter("phoneNumber"));
        String dobRaw = trim(req.getParameter("dateOfBirth"));
        List<String> errors = new ArrayList<>();

        Date dateOfBirth = null;
        if (dobRaw == null || dobRaw.isBlank()) {
            errors.add("Ngày sinh không được để trống.");
        } else {
            dateOfBirth = Date.valueOf(dobRaw);
            if (dateOfBirth.toLocalDate().isAfter(LocalDate.now())) {
                errors.add("Ngày sinh không được là ngày trong tương lai.");
            }
        }

        if (phone != null && !phone.isBlank()) {
            phone = phone.startsWith("+84") ? "0" + phone.substring(3) : phone;
            if (new UserDAO().existsByPhone(phone)) {
                errors.add("Số điện thoại đã được sử dụng.");
            }
        } else {
            phone = null;
        }

        if (!errors.isEmpty()) {
            req.setAttribute("pending", pending);
            req.setAttribute("errors", errors);
            req.setAttribute("phoneNumber", phone);
            req.setAttribute("dateOfBirth", dobRaw);
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        try {
            UserDAO userDAO = new UserDAO();
            if (userDAO.existsByEmail(pending.getEmail())) {
                GoogleOAuthSession.clearPendingSignup(req);
                resp.sendRedirect(req.getContextPath() + "/login?google=exists");
                return;
            }

            Optional<Role> customerRole = new RoleDAO().findByName("CUSTOMER");
            if (customerRole.isEmpty()) {
                throw new IllegalStateException("CUSTOMER role missing");
            }

            User user = new User();
            user.setRoleId(customerRole.get().getId());
            user.setEmail(pending.getEmail());
            user.setUsername(RegisterValidator.generateUsername(userDAO, pending.getEmail(), phone));
            user.setPhoneNumber(phone);
            user.setFullName(pending.getName() != null ? pending.getName() : pending.getEmail());
            user.setDateOfBirth(dateOfBirth);
            user.setAvatarUrl(pending.getPicture());
            user.setPasswordHash(PasswordUtil.hash(UUID.randomUUID().toString()));
            user.setStatus("ACTIVE");

            userDAO.insert(user);

            Optional<User> created = userDAO.findByEmail(pending.getEmail());
            if (created.isEmpty()) {
                throw new IllegalStateException("User not found after insert");
            }

            User saved = created.get();
            userDAO.updateLastLoginAt(saved.getId());
            SessionUtil.setLoggedIn(req, saved);
            SessionUtil.markHadLogin(resp);
            GoogleOAuthSession.clearPendingSignup(req);

            String target = AuthRedirectUtil.resolvePostLoginRedirect(
                    req, saved.getRoleName(), pending.getRedirect());
            resp.sendRedirect(target);
        } catch (RuntimeException ex) {
            log("GoogleCompleteServlet failed", ex);
            req.setAttribute("pending", pending);
            req.setAttribute("errors", List.of("Không thể tạo tài khoản. Vui lòng thử lại sau."));
            req.getRequestDispatcher(VIEW).forward(req, resp);
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
