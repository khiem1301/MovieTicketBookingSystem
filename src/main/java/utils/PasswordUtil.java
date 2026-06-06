package utils;

import org.mindrot.jbcrypt.BCrypt;

public final class PasswordUtil {

    private PasswordUtil() {}

    public static String hash(String plainPassword) {
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt());
    }

    public static boolean verify(String plainPassword, String passwordHash) {
        if (plainPassword == null || passwordHash == null || passwordHash.isBlank()) {
            return false;
        }
        try {
            // jbcrypt 0.4 chỉ nhận $2a$; seed DB có thể dùng $2b$ (tương thích)
            String normalized = passwordHash.startsWith("$2b$")
                    ? "$2a$" + passwordHash.substring(4)
                    : passwordHash;
            return BCrypt.checkpw(plainPassword, normalized);
        } catch (IllegalArgumentException ex) {
            return false;
        }
    }
}
