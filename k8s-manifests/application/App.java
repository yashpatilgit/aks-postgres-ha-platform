import java.sql.*;
import java.time.Instant;

public class App {

    private static final int MAX_RETRIES = 5;

    private static int successfulTransactions = 0;
    private static int retryCount = 0;
    private static int failedTransactions = 0;

    public static void main(String[] args) throws Exception {

        String host = requireEnv("PGHOST");
        String port = requireEnv("PGPORT");
        String database = requireEnv("PGDATABASE");
        String username = requireEnv("PGUSER");
        String password = requireEnv("PGPASSWORD");

        String jdbcUrl =
                "jdbc:postgresql://" + host + ":" + port + "/" + database +
                "?connectTimeout=2&socketTimeout=5&tcpKeepAlive=true";

        System.out.println("==============================================");
        System.out.println(" PostgreSQL Resilient Transaction Monitor");
        System.out.println("==============================================");
        System.out.println("Database Host : " + host);
        System.out.println("Database      : " + database);
        System.out.println("Started       : " + Instant.now());
        System.out.println("==============================================");

        Class.forName("org.postgresql.Driver");

        waitForDatabase(jdbcUrl, username, password);

        createTable(jdbcUrl, username, password);

        while (true) {
            executeTransaction(jdbcUrl, username, password);
            Thread.sleep(1000);
        }
    }

    private static String requireEnv(String name) {
        String value = System.getenv(name);

        if (value == null || value.isBlank()) {
            throw new IllegalStateException(
                    "Required environment variable missing: " + name);
        }

        return value;
    }

    private static void waitForDatabase(
            String jdbcUrl,
            String username,
            String password) throws InterruptedException {

        System.out.println("[STARTUP] Waiting for PostgreSQL...");

        while (true) {
            try (Connection connection =
                         DriverManager.getConnection(
                                 jdbcUrl, username, password)) {

                System.out.println(
                        "[STARTUP] PostgreSQL connection established");
                return;

            } catch (SQLException e) {

                System.out.println(
                        "[STARTUP] Database unavailable: "
                                + e.getMessage());

                Thread.sleep(2000);
            }
        }
    }

    private static void createTable(
            String jdbcUrl,
            String username,
            String password) {

        String sql =
                "CREATE TABLE IF NOT EXISTS reliability_events (" +
                "id BIGSERIAL PRIMARY KEY, " +
                "event_time TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP, " +
                "event_type VARCHAR(30) NOT NULL, " +
                "message TEXT NOT NULL)";

        try (Connection connection =
                     DriverManager.getConnection(
                             jdbcUrl, username, password);
             Statement statement = connection.createStatement()) {

            statement.executeUpdate(sql);

            System.out.println(
                    "[DB] reliability_events table ready");

        } catch (SQLException e) {

            System.out.println(
                    "[DB] Table initialization failed: "
                            + e.getMessage());
        }
    }

    private static void executeTransaction(
            String jdbcUrl,
            String username,
            String password) {

        for (int attempt = 1; attempt <= MAX_RETRIES; attempt++) {

            try (Connection connection =
                         DriverManager.getConnection(
                                 jdbcUrl, username, password)) {

                connection.setAutoCommit(false);

                String sql =
                        "INSERT INTO reliability_events " +
                        "(event_type, message) VALUES (?, ?)";

                try (PreparedStatement statement =
                             connection.prepareStatement(sql)) {

                    statement.setString(
                            1, "SUCCESS");

                    statement.setString(
                            2,
                            "Application transaction completed");

                    statement.executeUpdate();

                    connection.commit();

                    successfulTransactions++;

                    System.out.printf(
                            "[SUCCESS] transaction=%d | retries=%d | time=%s%n",
                            successfulTransactions,
                            retryCount,
                            Instant.now());

                    return;
                }

            } catch (SQLException e) {

                if (attempt < MAX_RETRIES) {

                    retryCount++;

                    long delay =
                            Math.min(
                                    500L * (1L << (attempt - 1)),
                                    4000L);

                    System.out.printf(
                            "[RETRY] attempt=%d/%d | delay=%dms | error=%s%n",
                            attempt,
                            MAX_RETRIES,
                            delay,
                            e.getMessage());

                    try {
                        Thread.sleep(delay);
                    } catch (InterruptedException interrupted) {
                        Thread.currentThread().interrupt();
                        return;
                    }

                } else {

                    failedTransactions++;

                    System.out.printf(
                            "[FAILURE] attempts=%d | failures=%d | time=%s | error=%s%n",
                            MAX_RETRIES,
                            failedTransactions,
                            Instant.now(),
                            e.getMessage());
                }
            }
        }
    }
}