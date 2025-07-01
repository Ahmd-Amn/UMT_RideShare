package servlet;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;
import javax.servlet.annotation.WebServlet;

@WebServlet("/adminLogin")
public class adminLoginServlet extends HttpServlet {

    @Override
    public void init() throws ServletException {
        try {
            // Load MySQL JDBC driver
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("MySQL JDBC Driver not found.", e);
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Retrieve username and password from the form
        String username = request.getParameter("adminUsername");
        String password = request.getParameter("adminPassword");

        // Validate form inputs
        if (username == null || password == null || username.isEmpty() || password.isEmpty()) {
            request.setAttribute("errorMessage", "Username and password cannot be empty.");
            RequestDispatcher dispatcher = request.getRequestDispatcher("index.jsp");
            dispatcher.forward(request, response);
            return;
        }

        try (Connection connection = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/ridesharedb", "root", "admin")) {

            // SQL query to validate admin credentials
            String query = "SELECT * FROM admin WHERE Ausername = ? AND Apassword = ?";
            try (PreparedStatement preparedStatement = connection.prepareStatement(query)) {
                preparedStatement.setString(1, username);
                preparedStatement.setString(2, password);

                try (ResultSet resultSet = preparedStatement.executeQuery()) {
                    if (resultSet.next()) {
                        // Valid credentials - create session and redirect to dashboard
                        HttpSession session = request.getSession();
                        session.setAttribute("adminID", resultSet.getInt("adminID")); // Store adminID in session
                        session.setAttribute("Aname", resultSet.getString("Aname")); // Store admin name
                        response.sendRedirect("dashboard.jsp");
                    } else {
                        // Invalid credentials - forward to login page with error message
                        request.setAttribute("errorMessage", "Invalid username or password.");
                        RequestDispatcher dispatcher = request.getRequestDispatcher("index.jsp");
                        dispatcher.forward(request, response);
                    }
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            // Handle database errors
            request.setAttribute("errorMessage", "Database error: " + e.getMessage());
            RequestDispatcher dispatcher = request.getRequestDispatcher("index.jsp");
            dispatcher.forward(request, response);
        }
    }
}
