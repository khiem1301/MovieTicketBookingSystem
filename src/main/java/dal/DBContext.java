package edu.fpt.swp391.movieticketbooking.dal;

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;

public class DBContext {

    private static final String CONFIG_FILE = "database.properties";
    private static final String JDBC_URL;

    private static final String USERNAME;
    private static final String PASSWORD;

    static {
        Properties props = loadProperties();

        String server = props.getProperty("db.server", "MORGAN");
        String port = props.getProperty("db.port", "1433");
        String database = props.getProperty("db.name", "MovieTicketBookingSystem");

        USERNAME = props.getProperty("db.username", "sa");
        PASSWORD = props.getProperty("db.password", "123");

        JDBC_URL = String.format(
                "jdbc:sqlserver://%s:%s;databaseName=%s;encrypt=true;trustServerCertificate=true;",
                server, port, database
        );

        try {
            Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        } catch (ClassNotFoundException e) {
            throw new ExceptionInInitializerError("SQL Server JDBC Driver not found: " + e.getMessage());
        }
    }

    private DBContext() {
    }

    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(JDBC_URL, USERNAME, PASSWORD);
    }

    private static Properties loadProperties() {
        Properties props = new Properties();

        try (InputStream input = DBContext.class.getClassLoader().getResourceAsStream(CONFIG_FILE)) {
            if (input != null) {
                props.load(input);
            }
        } catch (IOException e) {
            throw new ExceptionInInitializerError("Failed to load " + CONFIG_FILE + ": " + e.getMessage());
        }

        return props;
    }
}
