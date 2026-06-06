package util;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Tiện ích hash và verify mật khẩu bằng BCrypt.
 *
 * Cách dùng:
 *   String hashed = PasswordUtil.hash(rawPassword);       // khi tạo/đổi mật khẩu
 *   boolean ok    = PasswordUtil.verify(raw, hashed);     // khi đăng nhập
 */
public final class PasswordUtil {

    private static final int BCRYPT_ROUNDS = 12;

    private PasswordUtil() {}

    public static String hash(String plainPassword) {
        return BCrypt.hashpw(plainPassword, BCrypt.gensalt(BCRYPT_ROUNDS));
    }

    public static boolean verify(String plainPassword, String hashedPassword) {
        if (plainPassword == null || hashedPassword == null) return false;
        return BCrypt.checkpw(plainPassword, hashedPassword);
    }
}
