package dal;

import model.entity.ShowtimeIncident;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Optional;

public class ShowtimeIncidentDAO {

    public Optional<ShowtimeIncident> findByShowtimeId(String showtimeId) {
        String sql = """
                SELECT id, showtime_id, description, refund_points_rate,
                       compensation_discount_type, compensation_discount_value,
                       compensation_valid_days, processed_at, created_by, created_at
                FROM ShowtimeIncidents
                WHERE showtime_id = ?
                """;
        try (Connection conn = DBContext.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, showtimeId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) return Optional.of(mapRow(rs));
            }
        } catch (SQLException e) {
            throw new RuntimeException("findByShowtimeId failed", e);
        }
        return Optional.empty();
    }

    public void insert(Connection conn, ShowtimeIncident incident) throws SQLException {
        String sql = """
                INSERT INTO ShowtimeIncidents (
                    id, showtime_id, description, refund_points_rate,
                    compensation_discount_type, compensation_discount_value,
                    compensation_valid_days, processed_at, created_by
                ) VALUES (NEWID(), ?, ?, ?, ?, ?, ?, ?, ?)
                """;
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, incident.getShowtimeId());
            ps.setString(2, incident.getDescription());
            ps.setBigDecimal(3, incident.getRefundPointsRate() != null
                    ? incident.getRefundPointsRate() : BigDecimal.ONE);
            ps.setString(4, incident.getCompensationDiscountType() != null
                    ? incident.getCompensationDiscountType() : "FIXED_AMOUNT");
            ps.setBigDecimal(5, incident.getCompensationDiscountValue() != null
                    ? incident.getCompensationDiscountValue() : new BigDecimal("10000"));
            ps.setInt(6, incident.getCompensationValidDays() > 0
                    ? incident.getCompensationValidDays() : 30);
            if (incident.getProcessedAt() != null) {
                ps.setTimestamp(7, incident.getProcessedAt());
            } else {
                ps.setTimestamp(7, new Timestamp(System.currentTimeMillis()));
            }
            ps.setString(8, incident.getCreatedBy());
            ps.executeUpdate();
        }
    }

    private ShowtimeIncident mapRow(ResultSet rs) throws SQLException {
        ShowtimeIncident i = new ShowtimeIncident();
        i.setId(rs.getString("id"));
        i.setShowtimeId(rs.getString("showtime_id"));
        i.setDescription(rs.getString("description"));
        i.setRefundPointsRate(rs.getBigDecimal("refund_points_rate"));
        i.setCompensationDiscountType(rs.getString("compensation_discount_type"));
        i.setCompensationDiscountValue(rs.getBigDecimal("compensation_discount_value"));
        i.setCompensationValidDays(rs.getInt("compensation_valid_days"));
        i.setProcessedAt(rs.getTimestamp("processed_at"));
        i.setCreatedBy(rs.getString("created_by"));
        i.setCreatedAt(rs.getTimestamp("created_at"));
        return i;
    }
}
