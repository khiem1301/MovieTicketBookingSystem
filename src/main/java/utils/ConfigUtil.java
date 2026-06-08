package utils;

import dal.SystemConfigDAO;
import model.entity.SystemConfig;

import java.util.Optional;

public final class ConfigUtil {

    private ConfigUtil() {}

    public static String getString(String key, String defaultValue) {
        try {
            Optional<SystemConfig> found = new SystemConfigDAO().findByKey(key);
            if (found.isPresent()) {
                String value = found.get().getConfigValue();
                if (value != null && !value.isBlank()) {
                    return value.trim();
                }
            }
        } catch (RuntimeException ex) {
            // DB unavailable — fall back to default
        }
        return defaultValue;
    }

    public static int getInt(String key, int defaultValue) {
        String raw = getString(key, null);
        if (raw == null) {
            return defaultValue;
        }
        try {
            return Integer.parseInt(raw.trim());
        } catch (NumberFormatException ex) {
            return defaultValue;
        }
    }
}
