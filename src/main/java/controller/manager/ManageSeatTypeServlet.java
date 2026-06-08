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

@WebServlet("/manager/seat-types")
public class ManageSeatTypeServlet extends HttpServlet {

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
        if ("update".equals(req.getParameter("action"))) {
            handleUpdate(req, resp);
        } else {
            handleCreate(req, resp);
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String typeName = req.getParameter("typeName");
        String multiplierStr = req.getParameter("priceMultiplier");
        String description = req.getParameter("description");

        String error = validate(typeName, multiplierStr, null);
        if (error != null) {
            forwardWithError(req, resp, error, typeName, multiplierStr, description, null);
            return;
        }
        if (seatTypeDAO.isDuplicate(typeName)) {
            forwardWithError(req, resp, "Loại ghế \"" + typeName.trim() + "\" đã tồn tại.",
                    typeName, multiplierStr, description, null);
            return;
        }

        seatTypeDAO.create(typeName, new BigDecimal(multiplierStr.trim()), description);
        resp.sendRedirect(req.getContextPath() + "/manager/seat-types?success=created");
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = req.getParameter("id");
        String typeName = req.getParameter("typeName");
        String multiplierStr = req.getParameter("priceMultiplier");
        String description = req.getParameter("description");

        SeatType editing = (id != null) ? seatTypeDAO.getById(id) : null;
        if (editing == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/seat-types");
            return;
        }

        String error = validate(typeName, multiplierStr, id);
        if (error != null) {
            forwardWithError(req, resp, error, typeName, multiplierStr, description, editing);
            return;
        }
        if (seatTypeDAO.isDuplicateExcluding(typeName, id)) {
            forwardWithError(req, resp, "Loại ghế \"" + typeName.trim() + "\" đã tồn tại.",
                    typeName, multiplierStr, description, editing);
            return;
        }

        seatTypeDAO.update(id, typeName, new BigDecimal(multiplierStr.trim()), description);
        resp.sendRedirect(req.getContextPath() + "/manager/seat-types?success=updated");
    }

    private String validate(String typeName, String multiplierStr, String excludeId) {
        if (typeName == null || typeName.trim().isEmpty()) {
            return "Tên loại ghế không được để trống.";
        }
        if (typeName.trim().length() > 50) {
            return "Tên loại ghế không quá 50 ký tự.";
        }
        if (multiplierStr == null || multiplierStr.trim().isEmpty()) {
            return "Hệ số giá phải lớn hơn 0.";
        }
        try {
            BigDecimal m = new BigDecimal(multiplierStr.trim());
            if (m.compareTo(BigDecimal.ZERO) <= 0) {
                return "Hệ số giá phải lớn hơn 0.";
            }
        } catch (NumberFormatException e) {
            return "Hệ số giá không hợp lệ.";
        }
        return null;
    }

    private void forwardWithError(HttpServletRequest req, HttpServletResponse resp, String error,
                                  String typeName, String multiplierStr, String description,
                                  SeatType editSeatType) throws ServletException, IOException {
        req.setAttribute("error", error);
        req.setAttribute("inputTypeName", typeName);
        req.setAttribute("inputMultiplier", multiplierStr);
        req.setAttribute("inputDescription", description);
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
}
