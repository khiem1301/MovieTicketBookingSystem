package controller.admin;

import dal.PromotionDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.Promotion;
import utils.AdminAuthUtil;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

@WebServlet(urlPatterns = {"/admin/promotions/save"})
public class PromotionSaveServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        if (!AdminAuthUtil.requireAdminOrManager(req, resp)) return;

        String id            = trim(req.getParameter("promotionId"));
        String code          = trim(req.getParameter("code"));
        String title         = trim(req.getParameter("title"));
        String description   = trim(req.getParameter("description"));
        String discountType  = trim(req.getParameter("discountType"));
        String discountValStr = trim(req.getParameter("discountValue"));
        String maxDiscStr    = trim(req.getParameter("maxDiscountAmount"));
        String minOrderStr   = trim(req.getParameter("minOrderAmount"));
        String startDateStr  = trim(req.getParameter("startDate"));
        String endDateStr    = trim(req.getParameter("endDate"));
        String usageLimitStr = trim(req.getParameter("usageLimit"));

        boolean isUpdate = (id != null && !id.isBlank());
        List<String> errors = new ArrayList<>();

        // ── Validate code ────────────────────────────────────────────────
        if (code == null || code.isBlank()) {
            errors.add("Mã voucher không được để trống.");
        } else if (code.length() > 50) {
            errors.add("Mã voucher tối đa 50 ký tự.");
        } else if (!code.matches("[A-Za-z0-9_\\-]+")) {
            errors.add("Mã voucher chỉ chứa chữ cái, số, gạch ngang và gạch dưới.");
        }

        // ── Validate title ───────────────────────────────────────────────
        if (title == null || title.isBlank()) {
            errors.add("Tiêu đề không được để trống.");
        } else if (title.length() > 255) {
            errors.add("Tiêu đề tối đa 255 ký tự.");
        }

        // ── Validate discountType ────────────────────────────────────────
        if (!"PERCENTAGE".equals(discountType) && !"FIXED_AMOUNT".equals(discountType)) {
            errors.add("Loại giảm giá không hợp lệ.");
        }

        // ── Validate discountValue ───────────────────────────────────────
        BigDecimal discountValue = null;
        if (discountValStr == null || discountValStr.isBlank()) {
            errors.add("Giá trị giảm giá không được để trống.");
        } else {
            try {
                discountValue = new BigDecimal(discountValStr);
                if (discountValue.compareTo(BigDecimal.ZERO) <= 0) {
                    errors.add("Giá trị giảm giá phải lớn hơn 0.");
                } else if ("PERCENTAGE".equals(discountType)
                        && discountValue.compareTo(new BigDecimal("100")) > 0) {
                    errors.add("Phần trăm giảm giá không được vượt quá 100.");
                }
            } catch (NumberFormatException e) {
                errors.add("Giá trị giảm giá không hợp lệ.");
            }
        }

        // ── Validate maxDiscountAmount (tuỳ chọn) ───────────────────────
        BigDecimal maxDiscount = null;
        if (maxDiscStr != null && !maxDiscStr.isBlank()) {
            try {
                maxDiscount = new BigDecimal(maxDiscStr);
                if (maxDiscount.compareTo(BigDecimal.ZERO) <= 0) {
                    errors.add("Giảm tối đa phải lớn hơn 0.");
                }
            } catch (NumberFormatException e) {
                errors.add("Giảm tối đa không hợp lệ.");
            }
        }

        // ── Validate minOrderAmount (tuỳ chọn) ──────────────────────────
        BigDecimal minOrder = null;
        if (minOrderStr != null && !minOrderStr.isBlank()) {
            try {
                minOrder = new BigDecimal(minOrderStr);
                if (minOrder.compareTo(BigDecimal.ZERO) <= 0) {
                    errors.add("Đơn hàng tối thiểu phải lớn hơn 0.");
                }
            } catch (NumberFormatException e) {
                errors.add("Đơn hàng tối thiểu không hợp lệ.");
            }
        }

        // ── Validate dates ───────────────────────────────────────────────
        Timestamp startDate = null, endDate = null;
        if (startDateStr == null || startDateStr.isBlank()) {
            errors.add("Ngày bắt đầu không được để trống.");
        } else {
            try {
                startDate = Timestamp.valueOf(LocalDate.parse(startDateStr).atStartOfDay());
            } catch (Exception e) {
                errors.add("Ngày bắt đầu không hợp lệ.");
            }
        }
        if (endDateStr == null || endDateStr.isBlank()) {
            errors.add("Ngày kết thúc không được để trống.");
        } else {
            try {
                endDate = Timestamp.valueOf(LocalDate.parse(endDateStr).atTime(23, 59, 59));
            } catch (Exception e) {
                errors.add("Ngày kết thúc không hợp lệ.");
            }
        }
        if (startDate != null && endDate != null && !endDate.after(startDate)) {
            errors.add("Ngày kết thúc phải sau ngày bắt đầu.");
        }

        // ── Validate usageLimit (tuỳ chọn) ──────────────────────────────
        Integer usageLimit = null;
        if (usageLimitStr != null && !usageLimitStr.isBlank()) {
            try {
                usageLimit = Integer.parseInt(usageLimitStr);
                if (usageLimit <= 0) errors.add("Giới hạn sử dụng phải lớn hơn 0.");
            } catch (NumberFormatException e) {
                errors.add("Giới hạn sử dụng phải là số nguyên.");
            }
        }

        // ── Kiểm tra trùng code ──────────────────────────────────────────
        if (errors.isEmpty() && code != null && !code.isBlank()) {
            if (new PromotionDAO().codeExists(code, isUpdate ? id : null)) {
                errors.add("Mã voucher '" + code.toUpperCase() + "' đã tồn tại.");
            }
        }

        if (!errors.isEmpty()) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR, String.join(" ", errors));
            String redirect = req.getContextPath() + "/admin/promotions"
                            + (isUpdate ? "?edit=" + id + "#promo-edit-form" : "");
            resp.sendRedirect(redirect);
            return;
        }

        // ── Lưu ─────────────────────────────────────────────────────────
        Promotion p = new Promotion();
        if (isUpdate) p.setId(id);
        p.setCode(code.toUpperCase());
        p.setTitle(title);
        p.setDescription(description);
        p.setDiscountType(discountType);
        p.setDiscountValue(discountValue);
        p.setMaxDiscountAmount(maxDiscount);
        p.setMinOrderAmount(minOrder);
        p.setStartDate(startDate);
        p.setEndDate(endDate);
        p.setUsageLimit(usageLimit);

        try {
            PromotionDAO dao = new PromotionDAO();
            if (isUpdate) {
                dao.update(p);
                AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                        "Cập nhật mã giảm giá thành công.");
            } else {
                dao.create(p);
                AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_SUCCESS,
                        "Tạo mã giảm giá thành công.");
            }
        } catch (RuntimeException e) {
            AdminAuthUtil.setFlash(req, AdminAuthUtil.FLASH_ERROR,
                    "Đã xảy ra lỗi: " + e.getMessage());
        }
        resp.sendRedirect(req.getContextPath() + "/admin/promotions");
    }

    private String trim(String v) { return v == null ? null : v.trim(); }
}
