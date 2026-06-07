package utils;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Properties;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public final class GoogleOAuthUtil {

    private static final Logger LOG = Logger.getLogger(GoogleOAuthUtil.class.getName());
    private static final String PROPS_FILE = "google.properties";
    private static final String AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
    private static final String TOKEN_URL = "https://oauth2.googleapis.com/token";
    private static final String USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo";
    private static final String SCOPE = "openid email profile";

    private GoogleOAuthUtil() {}

    public static boolean isConfigured() {
        Properties props = loadProperties();
        if (props == null) {
            return false;
        }
        String id = props.getProperty("google.client.id", "").trim();
        String secret = props.getProperty("google.client.secret", "").trim();
        String redirect = props.getProperty("google.redirect.uri", "").trim();
        return !id.isBlank()
                && !secret.isBlank()
                && !redirect.isBlank()
                && !id.startsWith("YOUR_");
    }

    public static String buildAuthorizationUrl(String state) {
        Properties props = requireProperties();
        String clientId = props.getProperty("google.client.id").trim();
        String redirectUri = props.getProperty("google.redirect.uri").trim();

        String query = "client_id=" + enc(clientId)
                + "&redirect_uri=" + enc(redirectUri)
                + "&response_type=code"
                + "&scope=" + enc(SCOPE)
                + "&state=" + enc(state)
                + "&access_type=online"
                + "&prompt=select_account";

        return AUTH_URL + "?" + query;
    }

    public static String exchangeCodeForAccessToken(String code) throws IOException, InterruptedException {
        Properties props = requireProperties();
        String body = "code=" + enc(code)
                + "&client_id=" + enc(props.getProperty("google.client.id").trim())
                + "&client_secret=" + enc(props.getProperty("google.client.secret").trim())
                + "&redirect_uri=" + enc(props.getProperty("google.redirect.uri").trim())
                + "&grant_type=authorization_code";

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(TOKEN_URL))
                .timeout(Duration.ofSeconds(15))
                .header("Content-Type", "application/x-www-form-urlencoded")
                .POST(HttpRequest.BodyPublishers.ofString(body))
                .build();

        HttpResponse<String> response = HttpClient.newHttpClient()
                .send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            LOG.warning("Google token error: " + response.body());
            throw new IOException("Google token exchange failed: HTTP " + response.statusCode());
        }

        String token = extractJsonString(response.body(), "access_token");
        if (token == null || token.isBlank()) {
            throw new IOException("Google token response missing access_token");
        }
        return token;
    }

    public static GoogleUserInfo fetchUserInfo(String accessToken) throws IOException, InterruptedException {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(USERINFO_URL))
                .timeout(Duration.ofSeconds(15))
                .header("Authorization", "Bearer " + accessToken)
                .GET()
                .build();

        HttpResponse<String> response = HttpClient.newHttpClient()
                .send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() != 200) {
            LOG.warning("Google userinfo error: " + response.body());
            throw new IOException("Google userinfo failed: HTTP " + response.statusCode());
        }

        String json = response.body();
        return new GoogleUserInfo(
                extractJsonString(json, "sub"),
                extractJsonString(json, "email"),
                extractJsonString(json, "name"),
                extractJsonString(json, "picture")
        );
    }

    public record GoogleUserInfo(String sub, String email, String name, String picture) {}

    private static Properties requireProperties() {
        Properties props = loadProperties();
        if (props == null || !isConfigured()) {
            throw new IllegalStateException(
                    "Chưa cấu hình google.properties. Sao chép google.properties.example và điền OAuth.");
        }
        return props;
    }

    private static Properties loadProperties() {
        try (InputStream in = GoogleOAuthUtil.class.getClassLoader().getResourceAsStream(PROPS_FILE)) {
            if (in == null) {
                return null;
            }
            Properties props = new Properties();
            props.load(in);
            return props;
        } catch (IOException ex) {
            LOG.log(Level.WARNING, "Cannot load google.properties", ex);
            return null;
        }
    }

    private static String enc(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }

    private static String extractJsonString(String json, String key) {
        Pattern pattern = Pattern.compile("\"" + Pattern.quote(key) + "\"\\s*:\\s*\"((?:\\\\.|[^\"\\\\])*)\"");
        Matcher matcher = pattern.matcher(json);
        if (!matcher.find()) {
            return null;
        }
        return unescapeJson(matcher.group(1));
    }

    private static String unescapeJson(String value) {
        return value.replace("\\\"", "\"")
                .replace("\\\\", "\\")
                .replace("\\/", "/");
    }
}
