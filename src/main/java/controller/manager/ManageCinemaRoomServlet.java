package controller.manager;

import dal.CinemaRoomDAO;
import model.entity.CinemaRoom;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@WebServlet("/manager/rooms")
public class ManageCinemaRoomServlet extends HttpServlet {

    private final CinemaRoomDAO roomDAO = new CinemaRoomDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        List<CinemaRoom> rooms = roomDAO.getAll();
        req.setAttribute("roomList", rooms);

        String selectedId = req.getParameter("room");
        CinemaRoom selected = null;
        if (selectedId != null) {
            selected = roomDAO.getById(selectedId);
        }
        if (selected == null && !rooms.isEmpty()) {
            selected = rooms.get(0);
        }
        req.setAttribute("selectedRoom", selected);

        if (selected != null) {
            req.setAttribute("accessibleSeatCount", roomDAO.countAccessibleSeats(selected.getId()));
        }

        req.setAttribute("roomMetaMap", buildRoomMeta(rooms));
        req.getRequestDispatcher("/WEB-INF/views/manager/cinema-room-list.jsp").forward(req, resp);
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role) || "ADMIN".equals(role);
    }

    /** Metadata hiển thị UI — sẽ thay bằng bảng cấu hình khi backend đầy đủ. */
    private Map<String, Map<String, String>> buildRoomMeta(List<CinemaRoom> rooms) {
        Map<String, Map<String, String>> meta = new HashMap<>();
        for (CinemaRoom room : rooms) {
            meta.put(room.getId(), deriveDisplayMeta(room));
        }
        return meta;
    }

    private Map<String, String> deriveDisplayMeta(CinemaRoom room) {
        Map<String, String> m = new HashMap<>();
        String name = room.getRoomName() != null ? room.getRoomName().toLowerCase() : "";

        if (name.contains("imax")) {
            m.put("tag", "IMAX");
            m.put("projection", "IMAX Dual 4K Laser");
            m.put("audio", "Dolby Atmos 64-Channel");
            m.put("chipProjection", "IMAX 4K Laser");
            m.put("chipAudio", "Dolby Atmos");
        } else if (name.contains("4dx")) {
            m.put("tag", "4DX");
            m.put("projection", "Digital 2K");
            m.put("audio", "7.1 Surround");
            m.put("chipProjection", "Digital 2K");
            m.put("chipAudio", "7.1 Surround");
        } else {
            m.put("tag", "");
            m.put("projection", "Digital 2K");
            m.put("audio", "7.1 Surround");
            m.put("chipProjection", "Digital 2K");
            m.put("chipAudio", "7.1 Surround");
        }

        m.put("screenRatio", "1.90:1");
        m.put("currentShow", "Chưa có suất chiếu");
        m.put("occupancy", "0");

        if ("MAINTENANCE".equals(room.getStatus())) {
            m.put("maintenanceNote", "Bảo trì định kỳ");
            m.put("maintenanceEta", "—");
        }

        return m;
    }
}
