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
        return insertPendingVietQR(conn, bookingId, amount, transferCode, "ONLINE");
    }

    /** VietQR tại quầy (booking OFFLINE) — vẫn nhận SePay webhook giống online. */
    public String insertPendingOfflineVietQR(String bookingId, BigDecimal amount, String transferCode) {
        try (Connection conn = DBContext.getConnection()) {
            return insertPendingVietQR(conn, bookingId, amount, transferCode, "OFFLINE");
        } catch (SQLException e) {
            throw new RuntimeException("insertPendingOfflineVietQR failed", e);
        }
    }

    private String insertPendingVietQR(Connection conn, String bookingId, BigDecimal amount,
                                       String transferCode, String paymentSource) throws SQLException {
        String sql = """
                INSERT INTO Payments
                    (booking_id, payment_method, payment_source, transaction_code,
                     amount, payment_status)
                OUTPUT INSERTED.id
                VALUES (?, 'VIETQR', ?, ?, ?, 'PENDING')
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            ps.setString(2, paymentSource);
            ps.setString(3, transferCode);
            ps.setBigDecimal(4, amount);
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

    /**
     * SePay webhook: tìm payment VietQR PENDING (ONLINE customer hoặc OFFLINE quầy)
     * có transaction_code nằm trong nội dung CK và khớp số tiền.
     */
    public Optional<PaymentRecord> findPendingVietQRByTransferContent(String transferContentOrCode,
                                                                      BigDecimal amount) {
        if (transferContentOrCode == null || transferContentOrCode.isBlank() || amount == null) {
            return Optional.empty();
        }
        String haystack = normalizeTransferText(transferContentOrCode);
        long amountHalfUp = amount.setScale(0, java.math.RoundingMode.HALF_UP).longValue();
        long amountFloor = amount.setScale(0, java.math.RoundingMode.DOWN).longValue();
        BigDecimal amtHalf = BigDecimal.valueOf(amountHalfUp);
        BigDecimal amtFloor = BigDecimal.valueOf(amountFloor);

        // Lọc gần đúng theo số tiền ở SQL để tránh bỏ sót ngoài TOP N
        String sql = """
                SELECT TOP 100 id, booking_id, payment_method, payment_source, transaction_code,
                       amount, payment_status, paid_at
                FROM Payments
                WHERE payment_method = 'VIETQR'
                  AND payment_status = 'PENDING'
                  AND (
                        ROUND(amount, 0) IN (?, ?)
                     OR CAST(FLOOR(amount) AS DECIMAL(18,0)) IN (?, ?)
                  )
                ORDER BY created_at DESC
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setBigDecimal(1, amtHalf);
            ps.setBigDecimal(2, amtFloor);
            ps.setBigDecimal(3, amtHalf);
            ps.setBigDecimal(4, amtFloor);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PaymentRecord row = mapRow(rs);
                    String code = row.transactionCode();
                    if (code == null || code.isBlank()) {
                        continue;
                    }
                    String normalizedCode = normalizeTransferText(code);
                    if (normalizedCode.isBlank()) {
                        continue;
                    }
                    if (haystack.contains(normalizedCode)) {
                        return Optional.of(row);
                    }
                    // Match phần đuôi ≥ 8 ký tự (SePay cắt/ghép memo)
                    if (normalizedCode.length() >= 8) {
                        String tail = normalizedCode.substring(Math.max(0, normalizedCode.length() - 10));
                        if (tail.length() >= 8 && haystack.contains(tail)) {
                            return Optional.of(row);
                        }
                    }
                }
            }
        } catch (SQLException e) {
            throw new RuntimeException("findPendingVietQRByTransferContent failed", e);
        }
        return Optional.empty();
    }

    private static String normalizeTransferText(String raw) {
        if (raw == null) {
            return "";
        }
        return raw.trim().toUpperCase().replaceAll("[^A-Z0-9]", "");
    }

    public void markSuccess(Connection conn, String paymentId, String externalTransId) throws SQLException {
        // Giữ nguyên transaction_code (= nội dung CK) để audit; không ghi đè bằng SEPAY-id
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

    /** Đánh FAILED các VietQR PENDING cũ của booking trước khi tạo QR mới. */
    public void failStalePendingVietQR(String bookingId) {
        String sql = """
                UPDATE Payments
                SET payment_status = 'FAILED'
                WHERE booking_id = ?
                  AND payment_method = 'VIETQR'
                  AND payment_status = 'PENDING'
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, bookingId);
            ps.executeUpdate();
        } catch (SQLException e) {
            throw new RuntimeException("failStalePendingVietQR failed", e);
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
