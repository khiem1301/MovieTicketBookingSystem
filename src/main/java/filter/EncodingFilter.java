package filter;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;

public class EncodingFilter implements Filter {

    private static final String ENCODING = "UTF-8";

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        request.setCharacterEncoding(ENCODING);
        response.setCharacterEncoding(ENCODING);

        if (request instanceof HttpServletRequest req && response instanceof HttpServletResponse resp) {
            String uri = req.getRequestURI();
            if (uri != null) {
                if (uri.endsWith(".js")) {
                    resp.setContentType("application/javascript;charset=UTF-8");
                } else if (uri.endsWith(".css")) {
                    resp.setContentType("text/css;charset=UTF-8");
                }
            }
        }

        chain.doFilter(request, response);
    }
}
