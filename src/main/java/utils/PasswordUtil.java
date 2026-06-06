package utils;

import org.mindrot.jbcrypt.BCrypt;

public final class PasswordUtil {

    private static final int BCRYPT_ROUNDS = 10;

    private PasswordUtil() {
    }

    public static String hash(String plainPassword) {
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(BCRYPT_ROUNDS));
    }

    public static boolean verify(String plainPassword, String passwordHash) {
        if (plainPassword == null || passwordHash == null || passwordHash.isBlank()) {
            return false;
        }
        try {
            return BCrypt.checkpw(plainPassword, normalizeBcryptHash(passwordHash.trim()));
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    /**
     * jBCrypt 0.4 only verifies {@code $2a$} hashes. Seed SQL may use {@code $2b$} from other tools.
     */
    private static String normalizeBcryptHash(String passwordHash) {
        if (passwordHash.startsWith("$2b$") || passwordHash.startsWith("$2y$")) {
            return "$2a$" + passwordHash.substring(4);
        }
        return passwordHash;
    }
}
