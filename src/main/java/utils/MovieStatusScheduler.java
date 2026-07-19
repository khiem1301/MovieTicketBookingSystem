package utils;

import dal.MovieDAO;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

/** Tự động chuyển phim COMING_SOON -> NOW_SHOWING khi tới ngày phát hành. */
@WebListener
public class MovieStatusScheduler implements ServletContextListener {

    private static final Logger LOGGER = Logger.getLogger(MovieStatusScheduler.class.getName());
    private static final long INTERVAL_MINUTES = 15;

    private ScheduledExecutorService executor;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        executor = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "movie-status-scheduler");
            t.setDaemon(true);
            return t;
        });
        executor.scheduleAtFixedRate(this::runSync, 0, INTERVAL_MINUTES, TimeUnit.MINUTES);
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (executor != null) executor.shutdownNow();
    }

    private void runSync() {
        try {
            int updated = new MovieDAO().promoteReleasedMovies();
            if (updated > 0) {
                LOGGER.info(() -> "MovieStatusScheduler: promoted " + updated + " movie(s) to NOW_SHOWING");
            }
        } catch (Exception e) {
            LOGGER.log(Level.WARNING, "MovieStatusScheduler: sync failed", e);
        }
    }
}
