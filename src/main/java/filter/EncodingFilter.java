package filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpServletResponseWrapper;

import java.io.IOException;

/**
 * Force UTF-8 on requests/responses. For static .js/.css, Tomcat's DefaultServlet
 * often overwrites Content-Type without charset — wrap the response so charset stays UTF-8
 * (avoids mojibake like "ðŸŽ¬" / "đi?m" in counter-booking.js Vietnamese strings).
 */
public class EncodingFilter implements Filter {

    private static final String ENCODING = "UTF-8";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        request.setCharacterEncoding(ENCODING);
        response.setCharacterEncoding(ENCODING);

        if (request instanceof HttpServletRequest req && response instanceof HttpServletResponse resp) {
            String uri = req.getRequestURI();
            if (uri != null && (uri.endsWith(".js") || uri.endsWith(".css"))) {
                chain.doFilter(request, new CharsetPreservingResponse(resp, uri.endsWith(".js")));
                return;
            }
        }

        chain.doFilter(request, response);
    }

    private static final class CharsetPreservingResponse extends HttpServletResponseWrapper {

        private final boolean javascript;

        CharsetPreservingResponse(HttpServletResponse response, boolean javascript) {
            super(response);
            this.javascript = javascript;
            // Set early so even if DefaultServlet never calls setContentType, charset is present.
            super.setContentType(javascript
                    ? "application/javascript;charset=UTF-8"
                    : "text/css;charset=UTF-8");
        }

        @Override
        public void setContentType(String type) {
            super.setContentType(withUtf8Charset(type));
        }

        @Override
        public void setCharacterEncoding(String charset) {
            // Keep UTF-8 for static assets even if container tries to clear/change it.
            super.setCharacterEncoding(ENCODING);
        }

        private String withUtf8Charset(String type) {
            if (type == null || type.isBlank()) {
                return javascript
                        ? "application/javascript;charset=UTF-8"
                        : "text/css;charset=UTF-8";
            }
            String lower = type.toLowerCase();
            if (lower.contains("charset=")) {
                // Normalize any charset to UTF-8 for js/css
                int idx = lower.indexOf("charset=");
                return type.substring(0, idx) + "charset=UTF-8";
            }
            return type + ";charset=UTF-8";
        }
    }
}
