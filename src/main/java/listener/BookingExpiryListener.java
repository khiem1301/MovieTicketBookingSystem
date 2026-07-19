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
 * Job nền — chuyển đơn ONLINE PENDING quá {@code expired_at} sang EXPIRED
 * (giải phóng ghế, hoàn lượt voucher). Chạy mỗi 5 phút khi Tomcat đang chạy.
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
        scheduler.scheduleAtFixedRate(this::runExpireJob, INITIAL_DELAY_MINUTES, PERIOD_MINUTES, TimeUnit.MINUTES);
        LOG.info("BookingExpiryListener started (every " + PERIOD_MINUTES + " minutes)");
    }

    @Override
    public void contextDestroyed(ServletContextEvent sce) {
        if (scheduler != null) {
            scheduler.shutdownNow();
            LOG.info("BookingExpiryListener stopped");
        }
    }

    private void runExpireJob() {
        try {
            int n = new BookingDAO().expireAllStaleOnlinePendingBookings();
            if (n > 0) {
                LOG.info("BookingExpiryListener expired " + n + " stale PENDING booking(s)");
            }
        } catch (Exception e) {
            LOG.log(Level.WARNING, "BookingExpiryListener failed", e);
        }
    }
}
