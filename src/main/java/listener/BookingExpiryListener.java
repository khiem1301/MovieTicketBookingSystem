package listener;

import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.logging.Logger;

import dal.BookingDAO;
import jakarta.servlet.ServletContextEvent;
import jakarta.servlet.ServletContextListener;
import jakarta.servlet.annotation.WebListener;

/**
 * Job nền — chuyển đơn ONLINE PENDING quá expired_at sang EXPIRED (giải phóng ghế).
 */
@WebListener
public class BookingExpiryListener implements ServletContextListener {

    private static final Logger LOG = Logger.getLogger(BookingExpiryListener.class.getName());
    private static final long INITIAL_DELAY_MINUTES = 1;
    private static final long PERIOD_MINUTES = 5;

    private ScheduledExecutorService scheduler;

    @Override
    public void contextInitialized(ServletContextEvent sce) {
        scheduler = Executors.newSingleThreadScheduledExecutor(r -> {
            Thread t = new Thread(r, "booking-expiry-job");
            t.setDaemon(true);
            return t;
        });
        scheduler.scheduleAtFixedRate(this::runExpireJob,
                INITIAL_DELAY_MINUTES, PERIOD_MINUTES, TimeUnit.MINUTES);
        LOG.info("Booking expiry job scheduled every " + PERIOD_MINUTES + " minutes");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdownNow();
            scheduler = null;
        }
    }

    private void runExpireJob() {
        try {
            int count = new BookingDAO().expireAllStalePendingOnlineBookings();
            if (count > 0) {
                LOG.info("Expired " + count + " stale pending online booking(s)");
            }
        } catch (Exception e) {
            LOG.log(Level.WARNING, "Booking expiry job failed", e);
        }
    }
}
