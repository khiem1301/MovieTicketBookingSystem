package utils;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

class PasswordHashCheckTest {

    private static final String SEED_HASH =
            "$2b$10$cQtXPt5hVH2nDDhuXFDxQ.aKttyB7S7/6jR.xyULrEfcnUFA8UCM6";

    @Test
    void seedHashShouldMatchDefaultPassword() {
        assertTrue(PasswordUtil.verify("Password@123", SEED_HASH));
    }
}
