package utils;

import dal.ShowtimeDAO;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Đồng bộ trạng thái suất chiếu theo thời gian thực:
 * SCHEDULED → SHOWING → FINISHED (không đụng CANCELLED).
 */
@WebListener
public class ShowtimeStatusScheduler implements ServletContextListener {

    private static final Logger LOGGER = Logger.getLogger(ShowtimeStatusScheduler.class.getName());
    private static final long INTERVAL_MINUTES = 5;

    private ScheduledExecutorService executor;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        executor = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "showtime-status-scheduler");
            t.setDaemon(true);
            return t;
        });
        executor.scheduleAtFixedRate(this::runSync, 0, INTERVAL_MINUTES, TimeUnit.MINUTES);
        LOGGER.info("ShowtimeStatusScheduler started (every " + INTERVAL_MINUTES + " min)");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (executor != null) executor.shutdownNow();
    }

    private void runSync() {
        try {
            int updated = new ShowtimeDAO().autoSyncStatuses();
            if (updated > 0) {
                LOGGER.info(() -> "ShowtimeStatusScheduler: synced " + updated + " showtime row(s)");
            }
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "ShowtimeStatusScheduler: sync failed", e);
        }
    }
}
