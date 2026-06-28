package controller.manager;

import dal.CinemaRoomDAO;
import dal.SeatDAO;
import dal.SeatTypeDAO;
import model.entity.CinemaRoom;
import model.entity.Seat;
import utils.SeatLayoutJsonUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@WebServlet(urlPatterns = {
        "/manager/rooms",
        "/manager/rooms/detail",
        "/manager/rooms/update",
        "/manager/rooms/save-layout"
})
public class ManageCinemaRoomServlet extends HttpServlet {

    private static final Set<String> VALID_ROOM_STATUS = Set.of("ACTIVE", "MAINTENANCE", "INACTIVE");

    private final CinemaRoomDAO roomDAO = new CinemaRoomDAO();
    private final SeatTypeDAO seatTypeDAO = new SeatTypeDAO();
    private final SeatDAO seatDAO = new SeatDAO();

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        if (req.getServletPath().endsWith("/detail")) {
            handleDetail(req, resp);
        } else if (req.getServletPath().endsWith("/update") || req.getServletPath().endsWith("/save-layout")) {
            resp.sendRedirect(req.getContextPath() + "/manager/rooms");
        } else {
            handleList(req, resp);
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        if (!isAuthorized(req)) {
            resp.sendRedirect(req.getContextPath() + "/home");
            return;
        }

        req.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();

        if ("/manager/rooms".equals(path)) {
            handleCreate(req, resp);
        } else if (path.endsWith("/update")) {
            handleUpdate(req, resp);
        } else if (path.endsWith("/save-layout")) {
            handleSaveLayout(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/manager/rooms");
        }
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String roomName = req.getParameter("roomName");
        String ctx = req.getContextPath();

        if (roomName == null || roomName.trim().isEmpty()) {
            resp.sendRedirect(ctx + "/manager/rooms?error=" + enc("Tên phòng không được để trống."));
            return;
        }
        if (roomName.trim().length() > 100) {
            resp.sendRedirect(ctx + "/manager/rooms?error=" + enc("Tên phòng không quá 100 ký tự."));
            return;
        }
        if (roomDAO.existsByName(roomName)) {
            resp.sendRedirect(ctx + "/manager/rooms?error=" + enc("Tên phòng đã tồn tại trong hệ thống."));
            return;
        }

        try {
            String newId = roomDAO.create(roomName);
            resp.sendRedirect(ctx + "/manager/rooms/detail?id=" + newId + "&success=created");
        } catch (RuntimeException ex) {
            resp.sendRedirect(ctx + "/manager/rooms?error=" + enc("Không thể tạo phòng. Vui lòng thử lại."));
        }
    }

    private void handleUpdate(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String ctx = req.getContextPath();
        String roomId = req.getParameter("roomId");
        String action = req.getParameter("action");
        CinemaRoom room = (roomId != null) ? roomDAO.getById(roomId) : null;

        if (room == null) {
            resp.sendRedirect(ctx + "/manager/rooms");
            return;
        }

        if ("rename".equals(action)) {
            String roomName = req.getParameter("roomName");
            if (roomName == null || roomName.trim().isEmpty()) {
                resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc("Tên phòng không được để trống.")));
                return;
            }
            if (roomName.trim().length() > 100) {
                resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc("Tên phòng không quá 100 ký tự.")));
                return;
            }
            if (roomDAO.existsByNameExcluding(roomName, roomId)) {
                resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc("Tên phòng đã tồn tại trong hệ thống.")));
                return;
            }
            roomDAO.updateName(roomId, roomName);
            resp.sendRedirect(detailUrl(ctx, roomId, "success=updated"));
            return;
        }

        if ("toggle".equals(action)) {
            String status = req.getParameter("status");
            if (status == null || !VALID_ROOM_STATUS.contains(status)) {
                resp.sendRedirect(listUrl(ctx, roomId, "error=" + enc("Trạng thái phòng không hợp lệ.")));
                return;
            }
            if ("MAINTENANCE".equals(status) || "INACTIVE".equals(status)) {
                int upcoming = roomDAO.countUpcomingShowtimes(roomId);
                if (upcoming > 0) {
                    String msg = "Phòng còn " + upcoming + " suất chiếu sắp tới, không thể đổi trạng thái.";
                    String back = req.getParameter("from");
                    if ("detail".equals(back)) {
                        resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc(msg)));
                    } else {
                        resp.sendRedirect(listUrl(ctx, roomId, "error=" + enc(msg)));
                    }
                    return;
                }
            }
            roomDAO.updateStatus(roomId, status);
            String back = req.getParameter("from");
            if ("detail".equals(back)) {
                resp.sendRedirect(detailUrl(ctx, roomId, "success=status_updated"));
            } else {
                resp.sendRedirect(listUrl(ctx, roomId, "success=status_updated"));
            }
            return;
        }

        resp.sendRedirect(ctx + "/manager/rooms");
    }

    private void handleSaveLayout(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String ctx = req.getContextPath();
        String roomId = req.getParameter("roomId");
        String layoutJson = req.getParameter("layoutJson");

        CinemaRoom room = (roomId != null) ? roomDAO.getById(roomId) : null;
        if (room == null) {
            resp.sendRedirect(ctx + "/manager/rooms");
            return;
        }
        if (layoutJson == null || layoutJson.isBlank()) {
            resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc("Dữ liệu layout không hợp lệ.")));
            return;
        }

        try {
            Map<String, String> typeMap = seatTypeDAO.getTypeKeyToIdMap();
            List<Seat> seats = SeatLayoutJsonUtil.parseSeats(roomId, layoutJson, typeMap);
            seatDAO.saveLayout(roomId, seats);
            resp.sendRedirect(detailUrl(ctx, roomId, "success=layout_saved"));
        } catch (IllegalArgumentException ex) {
            resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc(ex.getMessage())));
        } catch (RuntimeException ex) {
            String msg = "Không thể lưu layout. Vui lòng thử lại.";
            if (ex.getCause() instanceof java.sql.SQLException) {
                msg = "Không thể lưu layout — ghế có thể đang được đặt vé hoặc giữ chỗ. "
                        + "Giữ nguyên mã ghế đã bán và thử lại.";
            }
            resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc(msg)));
        }
    }

    private void handleList(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        List<CinemaRoom> rooms = roomDAO.getAll();
        req.setAttribute("roomList", rooms);

        String selectedId = req.getParameter("room");
        if (selectedId == null) selectedId = req.getParameter("roomId");
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
        if (req.getParameter("error") != null) {
            req.setAttribute("error", req.getParameter("error"));
        }
        req.getRequestDispatcher("/WEB-INF/views/manager/cinema-room-list.jsp").forward(req, resp);
    }

    private void handleDetail(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String id = req.getParameter("id");
        CinemaRoom room = (id != null) ? roomDAO.getById(id) : null;

        if (room == null) {
            resp.sendRedirect(req.getContextPath() + "/manager/rooms");
            return;
        }

        List<Seat> dbSeats = seatDAO.getSeatsByRoom(room.getId());
        String layoutJson = dbSeats.isEmpty() ? null : SeatLayoutJsonUtil.buildLayoutJson(dbSeats);

        req.setAttribute("room", room);
        req.setAttribute("roomMeta", deriveDisplayMeta(room));
        req.setAttribute("seatTypeList", seatTypeDAO.getAll());
        req.setAttribute("activeSeatCount", room.getCapacity());
        req.setAttribute("dbSeatCount", dbSeats.size());
        req.setAttribute("layoutJson", layoutJson);
        req.setAttribute("accessibleSeatCount", roomDAO.countAccessibleSeats(room.getId()));
        if (req.getParameter("error") != null) {
            req.setAttribute("error", req.getParameter("error"));
        }
        req.getRequestDispatcher("/WEB-INF/views/manager/cinema-room-detail.jsp").forward(req, resp);
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role) || "ADMIN".equals(role);
    }

    private Map<String, Map<String, String>> buildRoomMeta(List<CinemaRoom> rooms) {
        Map<String, Map<String, String>> meta = new HashMap<>();
        for (CinemaRoom room : rooms) {
            meta.put(room.getId(), deriveDisplayMeta(room));
        }
        return meta;
    }

    Map<String, String> deriveDisplayMeta(CinemaRoom room) {
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

    private static String detailUrl(String ctx, String roomId, String query) {
        return ctx + "/manager/rooms/detail?id=" + roomId + "&" + query;
    }

    private static String listUrl(String ctx, String roomId, String query) {
        return ctx + "/manager/rooms?room=" + roomId + "&" + query;
    }

    private static String enc(String msg) {
        return java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8);
    }
}
