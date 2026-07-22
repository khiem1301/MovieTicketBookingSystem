package utils;

import java.util.Locale;
import java.util.Map;

/**
 * Shared seat-type color palette — must stay in sync with
 * {@code webapp/js/seat-type-colors.js} (manager + customer).
 *
 * <p>#e50914 is reserved for the "selected seat" state on the customer map,
 * so no seat-type color (preset or generated) may use that red / nearby hues.
 */
public final class SeatTypeColorUtil {

    /** Brand red used only for selected seats / UI accents — never for seat types. */
    public static final String RESERVED_SELECTION_COLOR = "#e50914";

    private static final Map<String, String> PRESET_COLORS = Map.of(
            "regular", "#cccccc",
            "vip", "#ffd700",
            "couple", "#ff4d94",
            "sweetbox", "#0072d7"
    );

    /** Hues in [0..FORBIDDEN_HIGH] U [FORBIDDEN_LOW..360) are too close to selection red. */
    private static final int FORBIDDEN_HUE_HIGH = 20;
    private static final int FORBIDDEN_HUE_LOW = 345;
    /** Safe hue span excluding the forbidden red band: 25 .. 344 → 320 degrees. */
    private static final int SAFE_HUE_START = 25;
    private static final int SAFE_HUE_SPAN = 320;

    private SeatTypeColorUtil() {}

    public static String normalizeType(String name) {
        if (name == null || name.isBlank()) return "regular";
        return name.trim().toLowerCase(Locale.ROOT);
    }

    public static String colorForType(String typeName) {
        String key = normalizeType(typeName);
        String preset = PRESET_COLORS.get(key);
        if (preset != null) return preset;

        int hash = 0;
        for (int i = 0; i < key.length(); i++) {
            hash = key.charAt(i) + ((hash << 5) - hash);
        }
        int hue = SAFE_HUE_START + (Math.abs(hash) % SAFE_HUE_SPAN);
        return "hsl(" + hue + ", 52%, 48%)";
    }

    public static String textColorFor(String background) {
        return isLightColor(background) ? "#222222" : "#ffffff";
    }

    public static boolean isLightColor(String color) {
        if (color == null || color.isBlank()) return false;
        String c = color.trim().toLowerCase(Locale.ROOT);
        if (c.startsWith("hsl")) {
            String nums = c.replaceAll("[^0-9.,]", "");
            String[] parts = nums.split(",");
            if (parts.length >= 3) {
                try {
                    return Double.parseDouble(parts[2].trim()) > 55;
                } catch (NumberFormatException ignored) {
                    return false;
                }
            }
            return false;
        }
        String hex = c.startsWith("#") ? c.substring(1) : c;
        if (hex.length() == 3) {
            hex = "" + hex.charAt(0) + hex.charAt(0)
                    + hex.charAt(1) + hex.charAt(1)
                    + hex.charAt(2) + hex.charAt(2);
        }
        if (hex.length() != 6) return false;
        try {
            int r = Integer.parseInt(hex.substring(0, 2), 16);
            int g = Integer.parseInt(hex.substring(2, 4), 16);
            int b = Integer.parseInt(hex.substring(4, 6), 16);
            return (0.299 * r + 0.587 * g + 0.114 * b) > 160;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    /** True if hue is in the band reserved for selection red. */
    public static boolean isForbiddenSelectionHue(int hue) {
        int h = ((hue % 360) + 360) % 360;
        return h <= FORBIDDEN_HUE_HIGH || h >= FORBIDDEN_HUE_LOW;
    }
}
