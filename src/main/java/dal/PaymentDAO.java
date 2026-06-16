package dal;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Optional;

/**
 * FR-16 — Giao dịch thanh toán (Payments).
 */
public class PaymentDAO {

    public record PaymentRecord(
            String id,
            String bookingId,
            String paymentMethod,
            String paymentSource,
            String transactionCode,
            BigDecimal amount,
            String paymentStatus,
            Timestamp paidAt) {}

    public String insertPendingOnlineVietQR(String bookingId, BigDecimal amount, String transferCode) {
        try (Connection conn = DBContext.getConnection()) {
            return insertPendingOnlineVietQR(conn, bookingId, amount, transferCode);
        } catch (SQLException e) {
            throw new RuntimeException("insertPendingOnlineVietQR failed", e);
        }
    }

    public String insertPendingOnlineVietQR(Connection conn, String bookingId, BigDecimal amount,
                                            String transferCode) throws SQLException {
        String sql = """
                INSERT INTO Payments
                    (booking_id, payment_method, payment_source, transaction_code,
                     amount, payment_status)
                OUTPUT INSERTED.id
                VALUES (?, 'VIETQR', 'ONLINE', ?, ?, 'PENDING')
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            ps.setString(2, transferCode);
            ps.setBigDecimal(3, amount);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    throw new SQLException("Không lấy được payment ID");
                }
                return rs.getString(1);
            }
        }
    }

    public Optional<PaymentRecord> findByTransferCode(String transferCode) {
        String sql = """
                SELECT id, booking_id, payment_method, payment_source, transaction_code,
                       amount, payment_status, paid_at
                FROM Payments
                WHERE transaction_code = ? AND payment_method = 'VIETQR'
                ORDER BY created_at DESC
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, transferCode);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findByTransferCode failed", e);
        }
        return Optional.empty();
    }

    public Optional<PaymentRecord> findLatestPendingVietQR(String bookingId) {
        String sql = """
                SELECT TOP 1 id, booking_id, payment_method, payment_source, transaction_code,
                       amount, payment_status, paid_at
                FROM Payments
                WHERE booking_id = ?
                  AND payment_method = 'VIETQR'
                  AND payment_source = 'ONLINE'
                  AND payment_status = 'PENDING'
                ORDER BY created_at DESC
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return Optional.of(mapRow(rs));
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findLatestPendingVietQR failed", e);
        }
        return Optional.empty();
    }

    public void markSuccess(Connection conn, String paymentId, String externalTransId) throws SQLException {
        String sql = """
                UPDATE Payments
                SET payment_status = 'SUCCESS',
                    paid_at = GETDATE()
                WHERE id = ? AND payment_status = 'PENDING'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, paymentId);
            ps.executeUpdate();
        }
    }

    public void markFailed(Connection conn, String paymentId) throws SQLException {
        String sql = """
                UPDATE Payments SET payment_status = 'FAILED'
                WHERE id = ? AND payment_status = 'PENDING'
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, paymentId);
            ps.executeUpdate();
        }
    }

    private PaymentRecord mapRow(ResultSet rs) throws SQLException {
        return new PaymentRecord(
                rs.getString("id"),
                rs.getString("booking_id"),
                rs.getString("payment_method"),
                rs.getString("payment_source"),
                rs.getString("transaction_code"),
                rs.getBigDecimal("amount"),
                rs.getString("payment_status"),
                rs.getTimestamp("paid_at"));
    }
}
