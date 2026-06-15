package controller.customer;

import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.json.JSONArray;
import org.json.JSONObject;

import dal.BookingDAO;
import dal.PricingRuleDAO;
import dal.SeatDAO;
import dal.SeatHoldDAO;
import dal.ShowtimeDAO;
import dal.UserDAO;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import model.dto.SessionUser;
import model.entity.PricingRule;
import model.entity.Seat;
import model.entity.Showtime;
import model.entity.User;
import utils.PricingCalculator;
import utils.SeatAvailabilityValidator;
import utils.SeatHoldException;
import utils.SessionUtil;

/**
 * FR-12 / FR-13 / FR-14 — Màn chọn ghế online tại /checkout?showtimeId=
 * GET  → sơ đồ ghế + panel tóm tắt
 * GET  ?action=seats&showtimeId=X → JSON refresh ghế
 * POST action=hold → đồng bộ SeatHolds ngay khi chọn/bỏ ghế (JSON)
 * POST (form) → FR-14 createOnlineBooking → redirect /payment
 */
@WebServlet("/checkout")
public class CheckoutServlet extends HttpServlet {

    private static final String VIEW = "/WEB-INF/views/customer/checkout.jsp";

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        String action = req.getParameter("action");
        String showtimeId = req.getParameter("showtimeId");

        if ("seats".equals(action) && showtimeId != null && !showtimeId.isBlank()) {
            serveSeatsJson(req, resp, showtimeId.trim());
            return;
        }

        if (showtimeId == null || showtimeId.isBlank()) {
            resp.sendRedirect(req.getContextPath() + "/movies");
            return;
        }

        showtimeId = showtimeId.trim();
        forwardCheckoutPage(req, resp, showtimeId, null);
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp)
            throws ServletException, IOException {

        req.setCharacterEncoding("UTF-8");
        String action = trim(req.getParameter("action"));

        if ("hold".equals(action)) {
            serveHoldSync(req, resp);
            return;
        }

        String showtimeId = trim(req.getParameter("showtimeId"));
        String[] rawSeatIds = req.getParameterValues("seatIds");

        if (isBlank(showtimeId)) {
            resp.sendRedirect(req.getContextPath() + "/movies");
            return;
        }

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.sendRedirect(req.getContextPath() + "/login?redirect="
                    + encodeRedirect(req, showtimeId));
            return;
        }

        Showtime showtime = new ShowtimeDAO().getShowtimeById(showtimeId);
        if (showtime == null || "CANCELLED".equals(showtime.getStatus())
                || "SOLD_OUT".equals(showtime.getStatus())) {
            forwardCheckoutPage(req, resp, showtimeId, "Suất chiếu không khả dụng.");
            return;
        }

        Timestamp now = new Timestamp(System.currentTimeMillis());
        if (showtime.getStartTime() != null && showtime.getStartTime().before(now)) {
            forwardCheckoutPage(req, resp, showtimeId, "Suất chiếu đã bắt đầu hoặc kết thúc.");
            return;
        }

        if (rawSeatIds == null || rawSeatIds.length == 0) {
            forwardCheckoutPage(req, resp, showtimeId, "Vui lòng chọn ít nhất một ghế.");
            return;
        }

        List<String> seatIds = SeatHoldDAO.distinctSeatIds(Arrays.asList(rawSeatIds));

        User user = new UserDAO().findById(sessionUser.getId()).orElse(null);
        if (user == null) {
            forwardCheckoutPage(req, resp, showtimeId, "Không tìm thấy tài khoản.");
            return;
        }

        Optional<String> ageError = SeatAvailabilityValidator.validateAge(
                showtime.getMovieAgeRating(), user.getDateOfBirth());
        if (ageError.isPresent()) {
            forwardCheckoutPage(req, resp, showtimeId, ageError.get());
            return;
        }

        try {
            BookingDAO bookingDAO = new BookingDAO();
            String bookingId = bookingDAO.createOnlineBooking(showtimeId, user.getId(), seatIds);
            model.entity.Booking booking = bookingDAO.getById(bookingId);
            if (booking == null || booking.getExpiredAt() == null) {
                forwardCheckoutPage(req, resp, showtimeId, "Không thể tạo đơn đặt vé.");
                return;
            }

            HttpSession session = req.getSession();
            session.setAttribute("checkoutDraft", Map.of(
                    "bookingId", bookingId,
                    "showtimeId", showtimeId,
                    "seatIds", new ArrayList<>(seatIds),
                    "expiredAt", booking.getExpiredAt().getTime()
            ));

            resp.sendRedirect(req.getContextPath() + "/payment?bookingId=" + bookingId);

        } catch (SeatHoldException e) {
            forwardCheckoutPage(req, resp, showtimeId, e.getMessage());
        } catch (RuntimeException e) {
            log("CheckoutServlet createOnlineBooking error", e);
            forwardCheckoutPage(req, resp, showtimeId,
                    "Không thể tạo đơn. Vui lòng thử lại sau giây lát.");
        }
    }

    private void forwardCheckoutPage(HttpServletRequest req, HttpServletResponse resp,
                                   String showtimeId, String errorMessage)
            throws ServletException, IOException {

        Showtime showtime = new ShowtimeDAO().getShowtimeById(showtimeId);

        if (showtime == null || "CANCELLED".equals(showtime.getStatus())) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        Timestamp now = new Timestamp(System.currentTimeMillis());
        if (showtime.getStartTime() != null && showtime.getStartTime().before(now)) {
            req.getRequestDispatcher("/WEB-INF/views/error/404.jsp").forward(req, resp);
            return;
        }

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        String userId = sessionUser != null ? sessionUser.getId() : null;

        List<PricingRule> pricingRules = new PricingRuleDAO().getActiveRules();
        BigDecimal effectivePrice = PricingCalculator.calculateEffectivePrice(showtime, pricingRules);
        showtime.setEffectivePrice(effectivePrice);

        SeatDAO seatDAO = new SeatDAO();
        List<Seat> seats = userId != null
                ? seatDAO.getSeatsForShowtime(showtimeId, userId)
                : seatDAO.getSeatsForShowtime(showtimeId);
        recalcSeatPrices(seats, effectivePrice);

        Map<String, List<Seat>> seatsByRow = groupByRow(seats);
        List<SeatTypeLegendItem> seatTypeLegend = buildSeatTypeLegend(seats);

        boolean soldOut = "SOLD_OUT".equals(showtime.getStatus());

        req.setAttribute("showtime", showtime);
        req.setAttribute("seatsByRow", seatsByRow);
        req.setAttribute("seatTypeLegend", seatTypeLegend);
        req.setAttribute("effectivePrice", effectivePrice);
        req.setAttribute("soldOut", soldOut);
        req.setAttribute("readOnly", soldOut);

        if (errorMessage != null) {
            req.setAttribute("errorMessage", errorMessage);
        } else {
            String queryError = trim(req.getParameter("error"));
            if (!isBlank(queryError)) {
                req.setAttribute("errorMessage", queryError);
            }
        }

        String queryInfo = trim(req.getParameter("info"));
        if (!isBlank(queryInfo)) {
            req.setAttribute("infoMessage", queryInfo);
        } else if (userId != null) {
            BookingDAO bookingDAO = new BookingDAO();
            String pendingId = bookingDAO.findActiveOnlinePendingBookingId(showtimeId, userId);
            if (pendingId != null) {
                req.setAttribute("pendingBookingId", pendingId);
                req.setAttribute("infoMessage",
                        "Bạn có đơn đang chờ thanh toán. "
                                + "Vui lòng hoàn tất hoặc hủy đơn để chọn ghế khác.");
            }
        }

        if (userId != null && req.getAttribute("pendingBookingId") == null) {
            new SeatHoldDAO().getActiveHoldExpiry(showtimeId, userId).ifPresent(expiry ->
                    req.setAttribute("holdExpiresAt", expiry.getTime()));
        }

        req.getRequestDispatcher(VIEW).forward(req, resp);
    }

    /** POST action=hold — giữ ghế ngay khi user chọn/bỏ trên sơ đồ. */
    private void serveHoldSync(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");

        String showtimeId = trim(req.getParameter("showtimeId"));
        String[] rawSeatIds = req.getParameterValues("seatIds");

        SessionUser sessionUser = SessionUtil.getLoggedUser(req);
        if (sessionUser == null) {
            resp.setStatus(401);
            resp.getWriter().write("{\"ok\":false,\"error\":\"Chưa đăng nhập\"}");
            return;
        }

        if (isBlank(showtimeId)) {
            resp.setStatus(400);
            resp.getWriter().write("{\"ok\":false,\"error\":\"Thiếu showtimeId\"}");
            return;
        }

        Showtime showtime = new ShowtimeDAO().getShowtimeById(showtimeId);
        if (showtime == null || "CANCELLED".equals(showtime.getStatus())
                || "SOLD_OUT".equals(showtime.getStatus())) {
            resp.setStatus(400);
            resp.getWriter().write("{\"ok\":false,\"error\":\"Suất chiếu không khả dụng\"}");
            return;
        }

        Timestamp now = new Timestamp(System.currentTimeMillis());
        if (showtime.getStartTime() != null && showtime.getStartTime().before(now)) {
            resp.setStatus(400);
            resp.getWriter().write("{\"ok\":false,\"error\":\"Suất chiếu đã bắt đầu\"}");
            return;
        }

        User user = new UserDAO().findById(sessionUser.getId()).orElse(null);
        if (user == null) {
            resp.setStatus(400);
            resp.getWriter().write("{\"ok\":false,\"error\":\"Không tìm thấy tài khoản\"}");
            return;
        }

        if (new BookingDAO().findActiveOnlinePendingBookingId(showtimeId, user.getId()) != null) {
            resp.setStatus(409);
            resp.getWriter().write("{\"ok\":false,\"error\":\"Bạn có đơn đang chờ thanh toán. Hãy hủy hoặc hoàn tất đơn trước.\"}");
            return;
        }

        Optional<String> ageError = SeatAvailabilityValidator.validateAge(
                showtime.getMovieAgeRating(), user.getDateOfBirth());
        if (ageError.isPresent()) {
            resp.setStatus(403);
            resp.getWriter().write("{\"ok\":false,\"error\":\"" + jsonEscape(ageError.get()) + "\"}");
            return;
        }

        List<String> seatIds = rawSeatIds != null && rawSeatIds.length > 0
                ? SeatHoldDAO.distinctSeatIds(Arrays.asList(rawSeatIds))
                : List.of();

        try {
            SeatHoldDAO holdDAO = new SeatHoldDAO();
            Timestamp expiresAt = holdDAO.syncHolds(showtimeId, user.getId(), seatIds);

            JSONObject result = new JSONObject();
            result.put("ok", true);
            if (expiresAt != null) {
                result.put("expiresAt", expiresAt.getTime());
            }
            resp.getWriter().write(result.toString());

        } catch (SeatHoldException e) {
            resp.setStatus(409);
            JSONObject err = new JSONObject();
            err.put("ok", false);
            err.put("error", e.getMessage());
            resp.getWriter().write(err.toString());
        } catch (RuntimeException e) {
            resp.setStatus(500);
            JSONObject err = new JSONObject();
            err.put("ok", false);
            err.put("error", "Không thể giữ ghế");
            resp.getWriter().write(err.toString());
        }
    }

    private String jsonEscape(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private void serveSeatsJson(HttpServletRequest req, HttpServletResponse resp,
                                String showtimeId) throws IOException {
        resp.setContentType("application/json; charset=UTF-8");
        try {
            Showtime showtime = new ShowtimeDAO().getShowtimeById(showtimeId);
            if (showtime == null) {
                resp.setStatus(404);
                resp.getWriter().write("{\"error\":\"Showtime not found\"}");
                return;
            }

            BigDecimal effectivePrice = PricingCalculator.calculateEffectivePrice(
                    showtime, new PricingRuleDAO().getActiveRules());

            SessionUser sessionUser = SessionUtil.getLoggedUser(req);
            String userId = sessionUser != null ? sessionUser.getId() : null;

            SeatDAO seatDAO = new SeatDAO();
            List<Seat> seats = userId != null
                    ? seatDAO.getSeatsForShowtime(showtimeId, userId)
                    : seatDAO.getSeatsForShowtime(showtimeId);
            recalcSeatPrices(seats, effectivePrice);

            Map<String, List<Seat>> byRow = groupByRow(seats);
            JSONArray rows = new JSONArray();
            for (Map.Entry<String, List<Seat>> entry : byRow.entrySet()) {
                JSONObject row = new JSONObject();
                row.put("rowName", entry.getKey());
                JSONArray seatsArr = new JSONArray();
                for (Seat s : entry.getValue()) {
                    JSONObject so = new JSONObject();
                    so.put("id", s.getId());
                    so.put("seatCode", s.getSeatCode());
                    so.put("seatColumn", s.getSeatColumn());
                    so.put("typeName", s.getSeatTypeName() == null ? "STANDARD" : s.getSeatTypeName());
                    so.put("ticketPrice", s.getTicketPrice() == null ? BigDecimal.ZERO : s.getTicketPrice());
                    so.put("available", s.isAvailable());
                    so.put("heldByMe", s.isHeldByCurrentUser());
                    seatsArr.put(so);
                }
                row.put("seats", seatsArr);
                rows.put(row);
            }
            resp.getWriter().write(rows.toString());
        } catch (RuntimeException e) {
            resp.setStatus(500);
            resp.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
        }
    }

    private void recalcSeatPrices(List<Seat> seats, BigDecimal effectivePrice) {
        if (effectivePrice == null) return;
        for (Seat seat : seats) {
            BigDecimal multiplier = seat.getPriceMultiplier() != null
                    ? seat.getPriceMultiplier() : BigDecimal.ONE;
            seat.setTicketPrice(effectivePrice.multiply(multiplier).setScale(0, RoundingMode.HALF_UP));
        }
    }

    private Map<String, List<Seat>> groupByRow(List<Seat> seats) {
        Map<String, List<Seat>> map = new LinkedHashMap<>();
        for (Seat s : seats) {
            map.computeIfAbsent(s.getSeatRow(), k -> new ArrayList<>()).add(s);
        }
        return map;
    }

    private List<SeatTypeLegendItem> buildSeatTypeLegend(List<Seat> seats) {
        Map<String, SeatTypeLegendItem> map = new LinkedHashMap<>();
        for (Seat seat : seats) {
            String typeName = seat.getSeatTypeName() != null ? seat.getSeatTypeName() : "STANDARD";
            map.computeIfAbsent(typeName, k -> new SeatTypeLegendItem(
                    typeName,
                    seat.getPriceMultiplier(),
                    seat.getTicketPrice()
            ));
        }
        return new ArrayList<>(map.values());
    }

    private String encodeRedirect(HttpServletRequest req, String showtimeId) {
        try {
            return java.net.URLEncoder.encode(
                    req.getContextPath() + "/checkout?showtimeId=" + showtimeId, "UTF-8");
        } catch (java.io.UnsupportedEncodingException e) {
            return req.getContextPath() + "/checkout?showtimeId=" + showtimeId;
        }
    }

    private boolean isBlank(String s) { return s == null || s.isBlank(); }

    private String trim(String v) { return v == null ? null : v.trim(); }

    public static class SeatTypeLegendItem {
        private final String typeName;
        private final BigDecimal priceMultiplier;
        private final BigDecimal samplePrice;

        public SeatTypeLegendItem(String typeName, BigDecimal priceMultiplier, BigDecimal samplePrice) {
            this.typeName = typeName;
            this.priceMultiplier = priceMultiplier;
            this.samplePrice = samplePrice;
        }

        public String getTypeName() { return typeName; }
        public BigDecimal getPriceMultiplier() { return priceMultiplier; }
        public BigDecimal getSamplePrice() { return samplePrice; }
    }
}
