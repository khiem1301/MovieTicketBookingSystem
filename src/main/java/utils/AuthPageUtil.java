package utils;

import jakarta.servlet.http.HttpServletRequest;

public final class AuthPageUtil {

    private AuthPageUtil() {}

    public static void prepareOAuthAttributes(HttpServletRequest request) {
        request.setAttribute("googleOAuthEnabled", GoogleOAuthUtil.isConfigured());
    }

    public static void prepareOAuthAttributes(HttpServletRequest request, String redirectParam) {
        prepareOAuthAttributes(request);
        if (AuthRedirectUtil.isSafeRedirect(redirectParam)) {
            request.setAttribute("googleRedirect", redirectParam);
        }
    }
}
