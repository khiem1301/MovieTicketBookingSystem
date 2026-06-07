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

import java.io.IOException;
import java.sql.Date;
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
        List<String> errors = validate(form);

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
        user.setFullName(form.getFullName());
        user.setDateOfBirth(form.getDateOfBirth());
        user.setPasswordHash(PasswordUtil.hash(form.getPassword()));
        user.setStatus("ACTIVE");

        try {
            new UserDAO().insert(user);
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                    "Đã tạo tài khoản " + form.getFullName() + " thành công.");
            resp.sendRedirect(req.getContextPath() + "/admin/users");
        } catch (RuntimeException ex) {
            errors.add("Không thể tạo tài khoản. Vui lòng kiểm tra lại thông tin.");
            prepareView(req, form, errors);
            req.getRequestDispatcher(VIEW).forward(req, resp);
        }
    }

    private void prepareView(HttpServletRequest req, AdminUserForm form, List<String> errors) {
        req.setAttribute("form", form);
        req.setAttribute("errors", errors != null ? errors : List.of());
        req.setAttribute("assignableRoles", new RoleDAO().findAssignableByAdmin());
    }

    private AdminUserForm readForm(HttpServletRequest req) {
        AdminUserForm form = new AdminUserForm();
        form.setEmail(trim(req.getParameter("email")));
        form.setUsername(trim(req.getParameter("username")));
        form.setPhoneNumber(trim(req.getParameter("phoneNumber")));
        form.setFullName(trim(req.getParameter("fullName")));
        form.setRoleName(trim(req.getParameter("roleName")));
        form.setPassword(req.getParameter("password"));

        String dobRaw = trim(req.getParameter("dateOfBirth"));
        if (dobRaw != null && !dobRaw.isBlank()) {
            form.setDateOfBirth(Date.valueOf(dobRaw));
        }
        return form;
    }

    private List<String> validate(AdminUserForm form) {
        List<String> errors = new ArrayList<>();

        if (form.getFullName() == null || form.getFullName().isBlank()) {
            errors.add("Họ tên không được để trống.");
        }
        if (form.getDateOfBirth() == null) {
            errors.add("Ngày sinh không được để trống.");
        } else if (form.getDateOfBirth().toLocalDate().isAfter(LocalDate.now())) {
            errors.add("Ngày sinh không được là ngày trong tương lai.");
        }

        boolean hasEmail = form.getEmail() != null && !form.getEmail().isBlank();
        boolean hasUsername = form.getUsername() != null && !form.getUsername().isBlank();
        boolean hasPhone = form.getPhoneNumber() != null && !form.getPhoneNumber().isBlank();
        if (!hasEmail && !hasUsername && !hasPhone) {
            errors.add("Cần nhập ít nhất một trong: email, tên đăng nhập hoặc số điện thoại.");
        }

        UserDAO userDAO = new UserDAO();
        if (hasEmail && userDAO.existsByEmail(form.getEmail())) {
            errors.add("Email đã được sử dụng.");
        }
        if (hasUsername && userDAO.existsByUsername(form.getUsername())) {
            errors.add("Tên đăng nhập đã được sử dụng.");
        }
        if (hasPhone && userDAO.existsByPhone(form.getPhoneNumber())) {
            errors.add("Số điện thoại đã được sử dụng.");
        }

        if (form.getRoleName() == null
                || (!"STAFF".equals(form.getRoleName()) && !"MANAGER".equals(form.getRoleName()))) {
            errors.add("Chỉ được tạo tài khoản Staff hoặc Manager.");
        }

        if (form.getPassword() == null || form.getPassword().length() < 8) {
            errors.add("Mật khẩu phải có ít nhất 8 ký tự.");
        }

        return errors;
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
