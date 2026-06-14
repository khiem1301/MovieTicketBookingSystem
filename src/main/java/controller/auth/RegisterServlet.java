package controller.auth;

import dal.PasswordResetTokenDAO;
import dal.RoleDAO;
import dal.UserDAO;
import jakarta.mail.MessagingException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.RegisterForm;
import model.entity.Role;
import model.entity.User;
import utils.AuthPageUtil;
import utils.EmailUtil;
import utils.PasswordUtil;
import utils.RegisterValidator;
import utils.SessionUtil;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.sql.Date;
import java.util.List;
import java.util.Optional;

/**
 * FR-01 — Customer registration with date_of_birth validation and email verification.
 */
@WebServlet(urlPatterns = {"/register"})
public class RegisterServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/auth/register.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        req.setAttribute("form", new RegisterForm());
        AuthPageUtil.prepareOAuthAttributes(req);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        if (SessionUtil.getLoggedUser(req) != null) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        RegisterForm form = readForm(req);
        UserDAO userDAO = new UserDAO();
        List<String> errors = RegisterValidator.validate(form, userDAO);

        if (!errors.isEmpty()) {
            forwardView(req, resp, form, errors);
            return;
        }

        Optional<Role> customerRole = new RoleDAO().findByName("CUSTOMER");
        if (customerRole.isEmpty()) {
            forwardView(req, resp, form, List.of("Không tìm thấy vai trò khách hàng trong hệ thống."));
            return;
        }

        String username = RegisterValidator.generateUsername(
                userDAO, form.getEmail(), form.getPhoneNumber());

        User user = new User();
        user.setRoleId(customerRole.get().getId());
        user.setEmail(form.getEmail());
        user.setUsername(username);
        user.setPhoneNumber(form.getPhoneNumber());
        user.setFullName(form.getFullName().trim());
        user.setDateOfBirth(form.getDateOfBirth());
        user.setPasswordHash(PasswordUtil.hash(form.getPassword()));
        user.setStatus("INACTIVE");

        try {
            String userId = userDAO.insert(user);
            handleEmailVerification(req, resp, userId, form);
        } catch (RuntimeException ex) {
            log("RegisterServlet: DB error", ex);
            forwardView(req, resp, form,
                    List.of("Không thể tạo tài khoản. Vui lòng thử lại sau."));
        }
    }

    private void handleEmailVerification(HttpServletRequest req, HttpServletResponse resp,
                                         String userId, RegisterForm form) throws IOException {
        PasswordResetTokenDAO tokenDAO = new PasswordResetTokenDAO();
        tokenDAO.invalidateUnusedForUser(userId);
        String token = tokenDAO.insert(userId, EmailUtil.verificationExpiryMinutes());
        String verifyUrl = EmailUtil.buildVerifyUrl(req.getContextPath(), token);

        boolean emailSent = false;
        if (EmailUtil.isConfigured()) {
            try {
                EmailUtil.sendVerificationEmail(form.getEmail(), form.getFullName(), verifyUrl);
                emailSent = true;
            } catch (MessagingException ex) {
                log("RegisterServlet: send verification email failed", ex);
            }
        }

        String encodedEmail = URLEncoder.encode(form.getEmail(), StandardCharsets.UTF_8);
        String redirect = req.getContextPath() + "/register/pending?email=" + encodedEmail
                + "&sent=" + (emailSent ? "1" : "0");
        if (!emailSent) {
            String encodedUrl = URLEncoder.encode(verifyUrl, StandardCharsets.UTF_8);
            redirect += "&devLink=" + encodedUrl;
        }
        resp.sendRedirect(redirect);
    }

    private RegisterForm readForm(HttpServletRequest req) {
        RegisterForm form = new RegisterForm();
        form.setFullName(trim(req.getParameter("fullName")));
        form.setEmail(trim(req.getParameter("email")));
        form.setPhoneNumber(trim(req.getParameter("phoneNumber")));
        form.setPassword(req.getParameter("password"));
        form.setConfirmPassword(req.getParameter("confirmPassword"));

        String dobRaw = trim(req.getParameter("dateOfBirth"));
        if (dobRaw != null && !dobRaw.isBlank()) {
            form.setDateOfBirth(Date.valueOf(dobRaw));
        }
        return form;
    }

    private void forwardView(HttpServletRequest req, HttpServletResponse resp,
                             RegisterForm form, List<String> errors)
            throws ServletException, IOException {
        req.setAttribute("form", form);
        req.setAttribute("errors", errors);
        AuthPageUtil.prepareOAuthAttributes(req);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
