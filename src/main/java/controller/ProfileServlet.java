package controller;

import dal.BookingDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.Part;
import model.entity.User;
import utils.AvatarUpload;
import utils.ProfileSecurityUtil;
import utils.ProfileValidator;
import utils.RegisterValidator;
import utils.SessionUtil;

import java.io.IOException;
import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * FR-04 / FR-05 — Trang tài khoản: xem/sửa profile + card bảo mật đổi mật khẩu.
 */
@WebServlet(urlPatterns = {"/profile"})
@MultipartConfig(
        fileSizeThreshold = 512 * 1024,
        maxFileSize = 2 * 1024 * 1024,
        maxRequestSize = 4 * 1024 * 1024
)
public class ProfileServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/common/profile.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        forwardProfileView(req, resp, null);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");

        if (SessionUtil.getLoggedUser(req) == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/profile");
            return;
        }

        String userId = SessionUtil.getLoggedUser(req).getId();
        UserDAO userDAO = new UserDAO();
        Optional<User> current = userDAO.findById(userId);
        if (current.isEmpty()) {
            resp.sendRedirect(req.getContextPath() + "/login");
            return;
        }

        String fullName = trim(req.getParameter("fullName"));
        String phoneRaw = trim(req.getParameter("phoneNumber"));
        String dobRaw = trim(req.getParameter("dateOfBirth"));

        Date dateOfBirth = null;
        List<String> errors = new ArrayList<>();
        if (dobRaw == null || dobRaw.isBlank()) {
            errors.add("Ngày sinh không được để trống.");
        } else {
            try {
                dateOfBirth = Date.valueOf(dobRaw);
            } catch (IllegalArgumentException ex) {
                errors.add("Ngày sinh không hợp lệ.");
            }
        }

        if (errors.isEmpty()) {
            errors.addAll(ProfileValidator.validate(fullName, phoneRaw, dateOfBirth, userId, userDAO));
        }

        String normalizedPhone = phoneRaw != null && !phoneRaw.isBlank()
                ? RegisterValidator.normalizePhone(phoneRaw)
                : phoneRaw;

        String avatarUrl = current.get().getAvatarUrl();
        Part avatarPart = req.getPart("avatar");
        if (avatarPart != null && avatarPart.getSize() > 0) {
            try {
                String saved = AvatarUpload.save(req.getServletContext(), avatarPart);
                if (saved != null) {
                    avatarUrl = saved;
                }
            } catch (IllegalArgumentException ex) {
                errors.add(ex.getMessage());
            } catch (IOException ex) {
                log("ProfileServlet: avatar upload failed", ex);
                errors.add("Không thể lưu ảnh đại diện. Vui lòng thử lại.");
            }
        }

        if (!errors.isEmpty()) {
            User formUser = cloneForForm(current.get(), fullName, normalizedPhone, dateOfBirth, avatarUrl);
            forwardProfileView(req, resp, formUser, errors);
            return;
        }

        try {
            userDAO.updateProfile(userId, fullName.trim(), normalizedPhone, dateOfBirth, avatarUrl);
            Optional<User> updated = userDAO.findById(userId);
            if (updated.isEmpty()) {
                throw new IllegalStateException("User not found after update");
            }
            SessionUtil.refreshLoggedUser(req, updated.get());
            resp.sendRedirect(req.getContextPath() + "/profile?saved=1");
        } catch (RuntimeException ex) {
            log("ProfileServlet: update failed", ex);
            User formUser = cloneForForm(current.get(), fullName, normalizedPhone, dateOfBirth, avatarUrl);
            forwardProfileView(req, resp, formUser,
                    List.of("Không thể cập nhật thông tin. Vui lòng thử lại sau."));
        }
    }

    private void forwardProfileView(HttpServletRequest req, HttpServletResponse resp, User userOverride)
            throws ServletException, IOException {
        forwardProfileView(req, resp, userOverride, null);
    }

    private void forwardProfileView(HttpServletRequest req, HttpServletResponse resp,
                                    User userOverride, List<String> profileErrors)
            throws ServletException, IOException {

        if (SessionUtil.getLoggedUser(req) == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect=/profile");
            return;
        }

        String userId = SessionUtil.getLoggedUser(req).getId();
        User user = userOverride;
        if (user == null) {
            Optional<User> found = new UserDAO().findById(userId);
            if (found.isEmpty()) {
                resp.sendRedirect(req.getContextPath() + "/login");
                return;
            }
            user = found.get();
        }

        req.setAttribute("user", user);
        req.setAttribute("avatarPublicUrl",
                AvatarUpload.toPublicUrl(req.getContextPath(), user.getAvatarUrl()));
        req.setAttribute("bookingCount", new BookingDAO().countConfirmedByUserId(user.getId()));
        req.setAttribute("securityVerified", ProfileSecurityUtil.isVerified(req));

        if (profileErrors != null && !profileErrors.isEmpty()) {
            req.setAttribute("profileErrors", profileErrors);
        }

        Object flashErrors = req.getSession().getAttribute("passwordChangeErrors");
        if (flashErrors instanceof List<?> list && !list.isEmpty()) {
            req.setAttribute("passwordChangeErrors", list);
            req.getSession().removeAttribute("passwordChangeErrors");
        }

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    private User cloneForForm(User base, String fullName, String phone, Date dob, String avatarUrl) {
        User u = new User();
        u.setId(base.getId());
        u.setRoleId(base.getRoleId());
        u.setRoleName(base.getRoleName());
        u.setEmail(base.getEmail());
        u.setUsername(base.getUsername());
        u.setFullName(fullName != null ? fullName : base.getFullName());
        u.setPhoneNumber(phone != null ? phone : base.getPhoneNumber());
        u.setDateOfBirth(dob != null ? dob : base.getDateOfBirth());
        u.setAvatarUrl(avatarUrl != null ? avatarUrl : base.getAvatarUrl());
        u.setLoyaltyPoints(base.getLoyaltyPoints());
        u.setStatus(base.getStatus());
        return u;
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }
}
