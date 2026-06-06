package dal;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

/**
 * Lớp cha cho tất cả DAO trong dự án.
 * Cách dùng: public class UserDAO extends BaseDAO { ... }
 */
public abstract class BaseDAO {

    protected Connection getConnection() throws SQLException {
        return DBContext.getConnection();
    }

    protected void close(Connection conn, PreparedStatement ps, ResultSet rs) {
        try { if (rs   != null) rs.close();   } catch (SQLException ignored) {}
        try { if (ps   != null) ps.close();   } catch (SQLException ignored) {}
        try { if (conn != null) conn.close(); } catch (SQLException ignored) {}
    }

    protected void close(Connection conn, PreparedStatement ps) {
        close(conn, ps, null);
    }
}
