package controller.admin;

import dal.RoleDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.dto.AdminUserForm;
import model.entity.Role;
import model.entity.User;
import utils.AdminAuthUtil;
import utils.PasswordUtil;
import utils.PasswordValidator;
import utils.RegisterValidator;

import java.io.IOException;
import java.sql.Date;
import java.time.DateTimeException;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@WebServlet(urlPatterns = {"/admin/users/create"})
public class UserCreateServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/admin/user-create.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        prepareView(req, new AdminUserForm(), null);
        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdmin(req, resp)) {
            return;
        }

        AdminUserForm form = readForm(req);
        UserDAO userDAO = new UserDAO();
        List<String> errors = validate(form, userDAO);

        if (!errors.isEmpty()) {
            prepareView(req, form, errors);
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        RoleDAO roleDAO = new RoleDAO();
        Optional<Role> role = roleDAO.findByName(form.getRoleName());
        if (role.isEmpty()) {
            errors.add("Vai trò không hợp lệ.");
            prepareView(req, form, errors);
            req.getRequestDispatcher(VIEW).forward(req, resp);
            return;
        }

        User user = new User();
        user.setRoleId(role.get().getId());
        user.setEmail(form.getEmail());
        user.setUsername(form.getUsername());
        user.setPhoneNumber(form.getPhoneNumber());
        user.setFullName(form.getFullName().trim());
        user.setDateOfBirth(form.getDateOfBirth());
        user.setPasswordHash(PasswordUtil.hash(form.getPassword()));
        user.setStatus("ACTIVE");

        try {
            userDAO.insert(user);
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                    "Đã tạo tài khoản " + form.getFullName().trim() + " thành công.");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } catch (RuntimeException ex) {
            log("UserCreateServlet: insert failed", ex);
            errors.add("Không thể tạo tài khoản. Vui lòng kiểm tra lại thông tin.");
            prepareView(req, form, errors);
            req.getRequestDispatcher(VIEW).forward(req, resp);
        }
    }

    private void prepareView(HttpServletRequest req, AdminUserForm form, List<String> errors) {
        req.setAttribute("form", form);
        req.setAttribute("errors", errors != null ? errors : List.of());
        req.setAttribute("assignableRoles", new RoleDAO().findAssignableByAdmin());
        req.setAttribute("passwordHint", PasswordValidator.HINT);
        req.setAttribute("currentYear", LocalDate.now().getYear());
    }

    private AdminUserForm readForm(HttpServletRequest req) {
        AdminUserForm form = new AdminUserForm();
        form.setEmail(trim(req.getParameter("email")));
        form.setUsername(trim(req.getParameter("username")));
        form.setPhoneNumber(trim(req.getParameter("phoneNumber")));
        form.setFullName(trim(req.getParameter("fullName")));
        form.setRoleName(trim(req.getParameter("roleName")));
        form.setPassword(req.getParameter("password"));

        Integer day = parseInt(req.getParameter("dobDay"));
        Integer month = parseInt(req.getParameter("dobMonth"));
        Integer year = parseInt(req.getParameter("dobYear"));
        form.setDobDay(day);
        form.setDobMonth(month);
        form.setDobYear(year);

        if (day != null && month != null && year != null) {
            try {
                form.setDateOfBirth(Date.valueOf(LocalDate.of(year, month, day)));
            } catch (DateTimeException ignored) {
                form.setDateOfBirth(null);
            }
        }
        return form;
    }

    private List<String> validate(AdminUserForm form, UserDAO userDAO) {
        List<String> errors = new ArrayList<>();

        if (form.getFullName() == null || form.getFullName().isBlank()) {
            errors.add("Họ tên không được để trống.");
        } else if (form.getFullName().trim().length() > 255) {
            errors.add("Họ tên không được vượt quá 255 ký tự.");
        }

        if (form.getDobDay() == null || form.getDobMonth() == null || form.getDobYear() == null) {
            errors.add("Ngày sinh không được để trống.");
        } else if (form.getDateOfBirth() == null) {
            errors.add("Ngày sinh không hợp lệ.");
        } else if (form.getDateOfBirth().toLocalDate().isAfter(LocalDate.now())) {
            errors.add("Ngày sinh không được là ngày trong tương lai.");
        }

        Optional<String> emailError = RegisterValidator.validateEmail(form.getEmail(), userDAO);
        if (emailError.isPresent()) {
            errors.add(emailError.get());
        } else {
            form.setEmail(form.getEmail().trim().toLowerCase());
        }

        Optional<String> usernameError = RegisterValidator.validateUsername(form.getUsername(), userDAO);
        if (usernameError.isPresent()) {
            errors.add(usernameError.get());
        } else {
            form.setUsername(form.getUsername().trim().toLowerCase());
        }

        Optional<String> phoneError = RegisterValidator.validatePhone(form.getPhoneNumber(), userDAO);
        if (phoneError.isPresent()) {
            errors.add(phoneError.get());
        } else {
            form.setPhoneNumber(RegisterValidator.normalizePhone(form.getPhoneNumber().trim()));
        }

        if (form.getRoleName() == null
                || (!"STAFF".equals(form.getRoleName()) && !"MANAGER".equals(form.getRoleName()))) {
            errors.add("Chỉ được tạo tài khoản Staff hoặc Manager.");
        }

        PasswordValidator.validateSingle(form.getPassword()).ifPresent(errors::add);

        return errors;
    }

    private Integer parseInt(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        try {
            return Integer.valueOf(raw.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
