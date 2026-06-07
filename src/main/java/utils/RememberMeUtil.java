package utils;

import dal.UserDAO;
import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import model.entity.User;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Optional;

/**
 * Signed remember-me token for auto-login without storing server-side state.
 */
public final class RememberMeUtil {

    public static final String COOKIE_TOKEN = "epcine_remember_token";
    private static final int MAX_AGE_SECONDS = 30 * 24 * 60 * 60;
    private static final String HMAC_ALGO = "HmacSHA256";
    private static final String SECRET = "epcine-remember-me-secret-v1";

    private RememberMeUtil() {}

    public static void issueToken(HttpServletResponse response, String userId) {
        long expiry = System.currentTimeMillis() + (MAX_AGE_SECONDS * 1000L);
        String payload = userId + "|" + expiry;
        String signature = sign(payload);
        String token = Base64.getUrlEncoder().withoutPadding()
                .encodeToString((payload + "|" + signature).getBytes(StandardCharsets.UTF_8));

        Cookie cookie = new Cookie(COOKIE_TOKEN, token);
        cookie.setPath("/");
        cookie.setMaxAge(MAX_AGE_SECONDS);
        cookie.setHttpOnly(true);
        response.addCookie(cookie);
    }

    public static void clearToken(HttpServletResponse response) {
        Cookie cookie = new Cookie(COOKIE_TOKEN, "");
        cookie.setPath("/");
        cookie.setMaxAge(0);
        cookie.setHttpOnly(true);
        response.addCookie(cookie);
    }

    public static Optional<String> parseUserId(HttpServletRequest request) {
        String token = readCookie(request);
        if (token == null) {
            return Optional.empty();
        }

        try {
            String decoded = new String(Base64.getUrlDecoder().decode(token), StandardCharsets.UTF_8);
            String[] parts = decoded.split("\\|", 3);
            if (parts.length != 3) {
                return Optional.empty();
            }

            String userId = parts[0];
            long expiry = Long.parseLong(parts[1]);
            String signature = parts[2];

            if (System.currentTimeMillis() > expiry) {
                return Optional.empty();
            }

            String payload = userId + "|" + expiry;
            if (!sign(payload).equals(signature)) {
                return Optional.empty();
            }

            return Optional.of(userId);
        } catch (IllegalArgumentException | ArrayIndexOutOfBoundsException ex) {
            return Optional.empty();
        }
    }

    public static boolean tryAutoLogin(HttpServletRequest request, HttpServletResponse response) {
        if (SessionUtil.getLoggedUser(request) != null) {
            return true;
        }

        Optional<String> userId = parseUserId(request);
        if (userId.isEmpty()) {
            return false;
        }

        try {
            Optional<User> found = new UserDAO().findById(userId.get());
            if (found.isEmpty()) {
                clearToken(response);
                return false;
            }

            User user = found.get();
            if (!"ACTIVE".equals(user.getStatus())) {
                clearToken(response);
                return false;
            }

            SessionUtil.setLoggedIn(request, user);
            SessionUtil.markHadLogin(response);
            return true;
        } catch (RuntimeException ex) {
            return false;
        }
    }

    private static String readCookie(HttpServletRequest request) {
        Cookie[] cookies = request.getCookies();
        if (cookies == null) {
            return null;
        }
        for (Cookie cookie : cookies) {
            if (COOKIE_TOKEN.equals(cookie.getName())) {
                String value = cookie.getValue();
                return (value != null && !value.isBlank()) ? value : null;
            }
        }
        return null;
    }

    private static String sign(String payload) {
        try {
            Mac mac = Mac.getInstance(HMAC_ALGO);
            mac.init(new SecretKeySpec(SECRET.getBytes(StandardCharsets.UTF_8), HMAC_ALGO));
            byte[] raw = mac.doFinal(payload.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(raw);
        } catch (Exception ex) {
            throw new IllegalStateException("Cannot sign remember-me token", ex);
        }
    }
}
