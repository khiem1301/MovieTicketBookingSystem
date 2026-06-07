package util;

import jakarta.servlet.ServletContext;
import jakarta.servlet.http.Part;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Set;
import java.util.UUID;

public final class MovieImageUpload {

    private static final Set<String> ALLOWED_TYPES = Set.of(
            "image/jpeg", "image/jpg", "image/png", "image/webp"
    );
    private static final long MAX_BYTES = 5 * 1024 * 1024; // 5 MB

    private MovieImageUpload() {}

    /**
     * Lưu file upload vào webapp/images/movies/{folder}/.
     * Trả về đường dẫn tương đối: images/movies/posters/uuid.jpg
     */
    public static String save(ServletContext ctx, Part part, String folder) throws IOException {
        if (part == null || part.getSize() == 0) return null;

        String contentType = part.getContentType();
        if (contentType == null || !ALLOWED_TYPES.contains(contentType.toLowerCase())) {
            throw new IllegalArgumentException("Ảnh phải là JPG, PNG hoặc WEBP.");
        }
        if (part.getSize() > MAX_BYTES) {
            throw new IllegalArgumentException("Ảnh không được vượt quá 5 MB.");
        }

        String ext = extensionFor(contentType);
        String filename = UUID.randomUUID() + ext;
        String relDir = "images/movies/" + folder;

        String basePath = ctx.getRealPath("/" + relDir);
        if (basePath == null) {
            throw new IOException("Không tìm thấy thư mục upload: " + relDir);
        }

        Path dir = Path.of(basePath);
        Files.createDirectories(dir);
        part.write(dir.resolve(filename).toString());

        return relDir + "/" + filename;
    }

    /** URL hiển thị trên trình duyệt (hỗ trợ link ngoài hoặc file upload nội bộ). */
    public static String toPublicUrl(String contextPath, String stored) {
        if (stored == null || stored.isBlank()) return null;
        if (stored.startsWith("http://") || stored.startsWith("https://")) {
            return stored;
        }
        String path = stored.startsWith("/") ? stored : "/" + stored;
        return contextPath + path;
    }

    private static String extensionFor(String contentType) {
        return switch (contentType.toLowerCase()) {
            case "image/jpeg", "image/jpg" -> ".jpg";
            case "image/png"  -> ".png";
            case "image/webp" -> ".webp";
            default -> ".img";
        };
    }
}
