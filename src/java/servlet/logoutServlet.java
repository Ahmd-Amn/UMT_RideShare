package servlet;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import javax.servlet.annotation.WebServlet;
import java.util.logging.Logger;

@WebServlet("/logout")
public class logoutServlet extends HttpServlet {
    private static final Logger logger = Logger.getLogger(logoutServlet.class.getName());

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Invalidate the session to log the user out
        HttpSession session = request.getSession(false); // Get the current session (do not create a new one)
        if (session != null) {
            // Optionally, clear specific attributes if needed
            // session.removeAttribute("username");
            // session.removeAttribute("userId");

            session.invalidate(); // Invalidate the session to log out the user
            logger.info("User  logged out successfully.");
        }

        // Redirect to the login page after logout
        response.sendRedirect("index.jsp");
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Redirect to doPost for logout
        doPost(request, response);
    }
}
