package controller.manager;

import dal.SeatTypeDAO;
import model.entity.SeatType;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

@WebServlet("/manager/seat-types")
public class ManageSeatTypeServlet extends HttpServlet {

    /** Hệ số giá: 1 chữ số phần nguyên, 2 chữ số phần thập phân (0.01 – 9.99). */
    private static final Pattern PRICE_MULTIPLIER_PATTERN = Pattern.compile("^[0-9]\\.[0-9]{2}$");

    private final SeatTypeDAO seatTypeDAO = new SeatTypeDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        if ("edit".equals(req.getParameter("action"))) {
            String id = req.getParameter("id");
            SeatType editing = (id != null) ? seatTypeDAO.getById(id) : null;
            if (editing != null) req.setAttribute("editSeatType", editing);
        }

        loadAndForward(req, resp);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        req.setCharacterEncoding("UTF-8");
        String action = req.getParameter("action");
        if ("update".equals(action)) {
            handleUpdate(req, resp);
        } else if ("delete".equals(action)) {
            handleDelete(req, resp);
        } else {
            handleCreate(req, resp);
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String typeName = req.getParameter("typeName");
        String multiplierStr = req.getParameter("priceMultiplier");
        String description = req.getParameter("description");
        String seatSpanStr = req.getParameter("seatSpan");

        ParsedInput parsed = parseAndValidate(typeName, multiplierStr, seatSpanStr);
        if (parsed.error != null) {
            forwardWithError(req, resp, parsed.error, typeName, multiplierStr, description, seatSpanStr, null);
            return;
        }
        if (seatTypeDAO.isDuplicate(typeName)) {
            forwardWithError(req, resp, "Loại ghế \"" + typeName.trim() + "\" đã tồn tại.",
                    typeName, multiplierStr, description, seatSpanStr, null);
            return;
        }

        seatTypeDAO.create(typeName, parsed.multiplier, description, parsed.seatSpan);
        resp.sendRedirect(req.getContextPath() + "/manager/seat-types?success=created");
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = req.getParameter("id");
        String typeName = req.getParameter("typeName");
        String multiplierStr = req.getParameter("priceMultiplier");
        String description = req.getParameter("description");
        String seatSpanStr = req.getParameter("seatSpan");

        SeatType editing = (id != null) ? seatTypeDAO.getById(id) : null;
        if (editing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/seat-types");
            return;
        }

        ParsedInput parsed = parseAndValidate(typeName, multiplierStr, seatSpanStr);
        if (parsed.error != null) {
            forwardWithError(req, resp, parsed.error, typeName, multiplierStr, description, seatSpanStr, editing);
            return;
        }
        if (seatTypeDAO.isDuplicateExcluding(typeName, id)) {
            forwardWithError(req, resp, "Loại ghế \"" + typeName.trim() + "\" đã tồn tại.",
                    typeName, multiplierStr, description, seatSpanStr, editing);
            return;
        }

        seatTypeDAO.update(id, typeName, parsed.multiplier, description, parsed.seatSpan);
        resp.sendRedirect(req.getContextPath() + "/manager/seat-types?success=updated");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String id = req.getParameter("id");
        SeatType existing = (id != null) ? seatTypeDAO.getById(id) : null;
        if (existing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/seat-types");
            return;
        }

        try {
            seatTypeDAO.delete(id);
            resp.sendRedirect(req.getContextPath() + "/manager/seat-types?success=deleted");
        } catch (IllegalStateException e) {
            resp.sendRedirect(req.getContextPath() + "/manager/seat-types?error=in_use");
        }
    }

    private ParsedInput parseAndValidate(String typeName, String multiplierStr, String seatSpanStr) {
        ParsedInput result = new ParsedInput();

        if (typeName == null || typeName.trim().isEmpty()) {
            result.error = "Tên loại ghế không được để trống.";
            return result;
        }
        if (typeName.trim().length() > 50) {
            result.error = "Tên loại ghế không quá 50 ký tự.";
            return result;
        }
        if (multiplierStr == null || multiplierStr.trim().isEmpty()) {
            result.error = "Hệ số giá không được để trống.";
            return result;
        }
        String trimmedMultiplier = multiplierStr.trim();
        if (!PRICE_MULTIPLIER_PATTERN.matcher(trimmedMultiplier).matches()) {
            result.error = "Hệ số giá phải có 1 chữ số phần nguyên và 2 chữ số phần thập phân (VD: 1.50).";
            return result;
        }
        try {
            BigDecimal m = new BigDecimal(trimmedMultiplier);
            if (m.compareTo(BigDecimal.ZERO) <= 0) {
                result.error = "Hệ số giá phải lớn hơn 0.";
                return result;
            }
            result.multiplier = m;
        } catch (NumberFormatException e) {
            result.error = "Hệ số giá không hợp lệ.";
            return result;
        }

        result.seatSpan = parseSeatSpan(seatSpanStr);
        if (result.seatSpan < 0) {
            result.error = "Kích thước ghế phải là 1 ô hoặc 2 ô liền nhau.";
            return result;
        }

        return result;
    }

    /** @return 1 hoặc 2; -1 nếu không hợp lệ */
    private static int parseSeatSpan(String seatSpanStr) {
        if (seatSpanStr == null || seatSpanStr.isBlank()) {
            return 1;
        }
        try {
            int span = Integer.parseInt(seatSpanStr.trim());
            if (span == 1 || span == 2) return span;
        } catch (NumberFormatException ignored) {
            // fall through
        }
        return -1;
    }

    private void forwardWithError(HttpServletRequest req, HttpServletResponse resp, String error,
                                  String typeName, String multiplierStr, String description,
                                  String seatSpanStr, SeatType editSeatType)
            throws ServletException, IOException {
        req.setAttribute("error", error);
        req.setAttribute("inputTypeName", typeName);
        req.setAttribute("inputMultiplier", multiplierStr);
        req.setAttribute("inputDescription", description);
        req.setAttribute("inputSeatSpan", seatSpanStr);
        if (editSeatType != null) req.setAttribute("editSeatType", editSeatType);
        loadAndForward(req, resp);
    }

    private void loadAndForward(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<SeatType> list = seatTypeDAO.getAll();
        req.setAttribute("seatTypeList", list);

        Map<String, Integer> usageMap = new HashMap<>();
        for (SeatType st : list) {
            usageMap.put(st.getId(), seatTypeDAO.countUsedIn(st.getId()));
        }
        req.setAttribute("usageMap", usageMap);
        req.getRequestDispatcher("/WEB-INF/views/manager/seat-type-list.jsp").forward(req, resp);
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role) || "ADMIN".equals(role);
    }

    private static final class ParsedInput {
        String error;
        BigDecimal multiplier;
        int seatSpan = 1;
    }
}
