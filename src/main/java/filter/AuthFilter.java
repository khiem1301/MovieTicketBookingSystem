package filter;

import jakarta.servlet.*;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import util.AppConstants;

import java.io.IOException;

/**
 * Filter kiểm tra đăng nhập cho tất cả URL yêu cầu xác thực.
 * Nếu chưa đăng nhập → redirect về trang login.
 *
 * Để thêm URL cần bảo vệ, thêm vào urlPatterns bên dưới.
 */
@WebFilter(urlPatterns = {
        "/user/*",
        "/booking/*",
        "/payment/*",
        "/admin/*",
        "/manager/*",
        "/staff/*"
})
public class AuthFilter implements Filter {

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  req     = (HttpServletRequest)  request;
        HttpServletResponse res     = (HttpServletResponse) response;
        HttpSession         session = req.getSession(false);

        boolean loggedIn = session != null
                && session.getAttribute(AppConstants.SESSION_USER) != null;

        if (!loggedIn) {
            String loginUrl = req.getContextPath() + "/login";
            res.sendRedirect(loginUrl);
            return;
        }

        chain.doFilter(request, response);
    }
}
