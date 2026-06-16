package dal;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * FR-17 — Phát hành vé điện tử sau thanh toán online.
 */
public class TicketDAO {

    public record BookingSeatRow(String bookingSeatId, String seatCode) {}

    public List<BookingSeatRow> findBookingSeats(Connection conn, String bookingId) throws SQLException {
        String sql = """
                SELECT bs.id, se.seat_code
                FROM BookingSeats bs
                JOIN Seats se ON se.id = bs.seat_id
                WHERE bs.booking_id = ?
                ORDER BY se.seat_row, se.seat_column
                """;
        List<BookingSeatRow> rows = new ArrayList<>();
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    rows.add(new BookingSeatRow(rs.getString("id"), rs.getString("seat_code")));
                }
            }
        }
        return rows;
    }

    public void issueTicketsForBooking(Connection conn, String bookingId, String bookingCode)
            throws SQLException {
        List<BookingSeatRow> seats = findBookingSeats(conn, bookingId);
        String insertSql = """
                INSERT INTO Tickets (booking_seat_id, ticket_code, qr_code, is_printed)
                SELECT ?, ?, ?, 0
                WHERE NOT EXISTS (
                    SELECT 1 FROM Tickets WHERE booking_seat_id = ?
                )
                """;
        try (PreparedStatement ps = conn.prepareStatement(insertSql)) {
            for (BookingSeatRow seat : seats) {
                String ticketCode = buildTicketCode(bookingCode, seat.seatCode());
                ps.setString(1, seat.bookingSeatId());
                ps.setString(2, ticketCode);
                ps.setString(3, ticketCode);
                ps.setString(4, seat.bookingSeatId());
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private String buildTicketCode(String bookingCode, String seatCode) {
        String base = (bookingCode != null ? bookingCode : "BK")
                + "-" + (seatCode != null ? seatCode : "X");
        base = base.replaceAll("[^A-Za-z0-9\\-]", "");
        if (base.length() > 90) {
            base = base.substring(0, 90);
        }
        return base + "-" + UUID.randomUUID().toString().substring(0, 6).toUpperCase();
    }
}
