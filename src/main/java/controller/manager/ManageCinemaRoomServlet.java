package controller.manager;

import dal.CinemaRoomDAO;
import dal.SeatDAO;
import dal.SeatTypeDAO;
import model.entity.CinemaRoom;
import model.entity.Seat;
import utils.AdminPaginationUtil;
import utils.SeatLayoutJsonUtil;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.Set;

@WebServlet(urlPatterns = {
        "/manager/rooms",
        "/manager/rooms/create",
        "/manager/rooms/detail",
        "/manager/rooms/update",
        "/manager/rooms/save-layout",
        "/manager/rooms/delete"
})
public class ManageCinemaRoomServlet extends HttpServlet {

    private static final Set<String> VALID_ROOM_STATUS = Set.of("ACTIVE", "INACTIVE");
    private static final int PAGE_SIZE = 8;

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

        String path = req.getServletPath();
        if (path.endsWith("/create")) {
            handleCreateForm(req, resp);
        } else if (path.endsWith("/detail")) {
            handleDetail(req, resp);
        } else if (path.endsWith("/update") || path.endsWith("/save-layout") || path.endsWith("/delete")) {
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

        if ("/manager/rooms".equals(path) || path.endsWith("/create")) {
            handleCreate(req, resp);
        } else if (path.endsWith("/update")) {
            handleUpdate(req, resp);
        } else if (path.endsWith("/save-layout")) {
            handleSaveLayout(req, resp);
        } else if (path.endsWith("/delete")) {
            handleDelete(req, resp);
        } else {
            resp.sendRedirect(req.getContextPath() + "/manager/rooms");
        }
    }

    private void handleCreateForm(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        req.setAttribute("seatTypeList", seatTypeDAO.getAll());
        if (req.getParameter("error") != null) {
            req.setAttribute("error", req.getParameter("error"));
        }
        if (req.getParameter("roomName") != null) {
            req.setAttribute("inputRoomName", req.getParameter("roomName"));
        }
        req.getRequestDispatcher("/WEB-INF/views/manager/cinema-room-create.jsp").forward(req, resp);
    }

    private void handleCreate(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {
        String roomName = req.getParameter("roomName");
        String layoutJson = req.getParameter("layoutJson");
        String ctx = req.getContextPath();

        if (roomName == null || roomName.trim().isEmpty()) {
            resp.sendRedirect(ctx + "/manager/rooms/create?error=" + enc("Tên phòng không được để trống."));
            return;
        }
        roomName = roomName.trim();
        if (roomName.length() > 100) {
            resp.sendRedirect(ctx + "/manager/rooms/create?error=" + enc("Tên phòng không quá 100 ký tự.")
                    + "&roomName=" + enc(roomName));
            return;
        }
        if (roomDAO.existsByName(roomName)) {
            resp.sendRedirect(ctx + "/manager/rooms/create?error=" + enc("Tên phòng đã tồn tại trong hệ thống.")
                    + "&roomName=" + enc(roomName));
            return;
        }
        if (layoutJson == null || layoutJson.isBlank()) {
            resp.sendRedirect(ctx + "/manager/rooms/create?error=" + enc("Vui lòng thiết kế layout ghế trước khi lưu.")
                    + "&roomName=" + enc(roomName));
            return;
        }

        List<Seat> seats;
        try {
            Map<String, String> typeMap = seatTypeDAO.getTypeKeyToIdMap();
            seats = SeatLayoutJsonUtil.parseSeats("TEMP", layoutJson, typeMap);
        } catch (IllegalArgumentException ex) {
            resp.sendRedirect(ctx + "/manager/rooms/create?error=" + enc(ex.getMessage())
                    + "&roomName=" + enc(roomName));
            return;
        }

        if (seats == null || seats.isEmpty()) {
            resp.sendRedirect(ctx + "/manager/rooms/create?error="
                    + enc("Phải đặt ít nhất 1 ghế trên layout trước khi tạo phòng.")
                    + "&roomName=" + enc(roomName));
            return;
        }

        java.sql.Connection conn = null;
        try {
            conn = dal.DBContext.getConnection();
            conn.setAutoCommit(false);
            String newId = roomDAO.create(conn, roomName);
            for (Seat seat : seats) {
                seat.setRoomId(newId);
            }
            seatDAO.saveLayout(conn, newId, seats);
            conn.commit();
            resp.sendRedirect(ctx + "/manager/rooms/detail?id=" + newId + "&success=created");
        } catch (Exception ex) {
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignored) { }
            }
            resp.sendRedirect(ctx + "/manager/rooms/create?error="
                    + enc("Không thể tạo phòng. Vui lòng thử lại.")
                    + "&roomName=" + enc(roomName));
        } finally {
            if (conn != null) {
                try {
                    conn.setAutoCommit(true);
                    conn.close();
                } catch (Exception ignored) { }
            }
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
                resp.sendRedirect(listUrl(req, ctx, roomId, "error=" + enc("Trạng thái phòng không hợp lệ.")));
                return;
            }
            if ("INACTIVE".equals(status)) {
                int upcoming = roomDAO.countUpcomingShowtimes(roomId);
                if (upcoming > 0) {
                    String msg = "Phòng còn " + upcoming + " suất chiếu sắp tới, không thể đổi trạng thái.";
                    String back = req.getParameter("from");
                    if ("detail".equals(back)) {
                        resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc(msg)));
                    } else {
                        resp.sendRedirect(listUrl(req, ctx, roomId, "error=" + enc(msg)));
                    }
                    return;
                }
            }
            roomDAO.updateStatus(roomId, status);
            String back = req.getParameter("from");
            if ("detail".equals(back)) {
                resp.sendRedirect(detailUrl(ctx, roomId, "success=status_updated"));
            } else {
                resp.sendRedirect(listUrl(req, ctx, roomId, "success=status_updated"));
            }
            return;
        }

        resp.sendRedirect(ctx + "/manager/rooms");
    }

    private void handleDelete(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        String ctx = req.getContextPath();
        String roomId = req.getParameter("roomId");
        String from = req.getParameter("from");
        CinemaRoom room = (roomId != null) ? roomDAO.getById(roomId) : null;

        if (room == null) {
            resp.sendRedirect(ctx + "/manager/rooms");
            return;
        }

        if (!roomDAO.isMistakenRoomDeletable(roomId)) {
            String msg = "Chỉ xóa được phòng tạo nhầm — phòng đã có suất chiếu hoặc dữ liệu đặt ghế. "
                    + "Hãy dùng Ngưng hoạt động nếu không muốn dùng nữa.";
            if ("detail".equals(from)) {
                resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc(msg)));
            } else {
                resp.sendRedirect(listUrl(req, ctx, roomId, "error=" + enc(msg)));
            }
            return;
        }

        try {
            roomDAO.deleteMistakenRoom(roomId);
            resp.sendRedirect(listUrl(req, ctx, null, "success=deleted"));
        } catch (IllegalStateException ex) {
            String msg = ex.getMessage() != null ? ex.getMessage()
                    : "Không thể xóa phòng này.";
            if ("detail".equals(from)) {
                resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc(msg)));
            } else {
                resp.sendRedirect(listUrl(req, ctx, roomId, "error=" + enc(msg)));
            }
        } catch (RuntimeException ex) {
            String msg = "Không thể xóa phòng. Vui lòng thử lại.";
            if ("detail".equals(from)) {
                resp.sendRedirect(detailUrl(ctx, roomId, "error=" + enc(msg)));
            } else {
                resp.sendRedirect(listUrl(req, ctx, roomId, "error=" + enc(msg)));
            }
        }
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
        String statusFilter = normalizeListStatus(req.getParameter("status"));
        int page = AdminPaginationUtil.parsePage(req.getParameter("page"));

        int totalItems = roomDAO.countByStatus(statusFilter);
        int totalPages = AdminPaginationUtil.totalPages(totalItems, PAGE_SIZE);
        page = AdminPaginationUtil.clampPage(page, totalPages);
        int offset = AdminPaginationUtil.offset(page, PAGE_SIZE);

        List<CinemaRoom> rooms = roomDAO.findPaged(statusFilter, offset, PAGE_SIZE);
        req.setAttribute("roomList", rooms);
        req.setAttribute("deletableRoomIds", roomDAO.findMistakenDeletableIds());
        req.setAttribute("statusFilter", statusFilter);
        req.setAttribute("pgCurrent", page);
        req.setAttribute("pgTotal", totalPages);
        req.setAttribute("pgTotalItems", totalItems);
        req.setAttribute("pgRankStart", AdminPaginationUtil.rankStart(page, PAGE_SIZE));
        req.setAttribute("pgQueryExtra",
                AdminPaginationUtil.queryParam("status",
                        "ALL".equals(statusFilter) ? null : statusFilter));
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
        req.setAttribute("seatTypeList", seatTypeDAO.getAll());
        req.setAttribute("activeSeatCount", room.getCapacity());
        req.setAttribute("dbSeatCount", dbSeats.size());
        req.setAttribute("layoutJson", layoutJson);
        req.setAttribute("accessibleSeatCount", roomDAO.countAccessibleSeats(room.getId()));
        req.setAttribute("canDeleteRoom", roomDAO.isMistakenRoomDeletable(room.getId()));
        if (req.getParameter("error") != null) {
            req.setAttribute("error", req.getParameter("error"));
        }
        req.getRequestDispatcher("/WEB-INF/views/manager/cinema-room-detail.jsp").forward(req, resp);
    }

    private boolean isAuthorized(HttpServletRequest req) {
        Object role = req.getSession().getAttribute("userRole");
        return "MANAGER".equals(role);
    }

    private static String detailUrl(String ctx, String roomId, String query) {
        return ctx + "/manager/rooms/detail?id=" + roomId + "&" + query;
    }

    /** Giữ page/status khi quay lại danh sách sau toggle/xóa. */
    private static String listUrl(HttpServletRequest req, String ctx, String roomId, String query) {
        StringBuilder url = new StringBuilder(ctx).append("/manager/rooms?");
        String page = trim(req.getParameter("returnPage"));
        if (page == null || page.isBlank()) {
            page = trim(req.getParameter("page"));
        }
        String status = trim(req.getParameter("returnStatus"));
        if (status == null || status.isBlank()) {
            status = trim(req.getParameter("status"));
        }
        if (page != null && !page.isBlank()) {
            url.append("page=").append(enc(page)).append('&');
        }
        if (status != null && !status.isBlank() && !"ALL".equalsIgnoreCase(status)) {
            url.append("status=").append(enc(status)).append('&');
        }
        if (roomId != null && !roomId.isBlank()) {
            url.append("room=").append(enc(roomId)).append('&');
        }
        url.append(query);
        return url.toString();
    }

    private static String normalizeListStatus(String raw) {
        if (raw == null || raw.isBlank()) return "ALL";
        String s = raw.trim().toUpperCase();
        if ("ACTIVE".equals(s) || "INACTIVE".equals(s)) return s;
        return "ALL";
    }

    private static String trim(String value) {
        return value == null ? null : value.trim();
    }

    private static String enc(String msg) {
        return java.net.URLEncoder.encode(msg, java.nio.charset.StandardCharsets.UTF_8);
    }
}
