package servlet;

import Model.User;
import javax.servlet.*;
import javax.servlet.http.*;
import java.io.*;
import java.sql.*;
import javax.servlet.annotation.WebServlet;

@WebServlet("/register")
public class RegisterServlet extends HttpServlet {
    // Load MySQL JDBC driver when servlet is initialized
    @Override
    public void init() throws ServletException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("MySQL JDBC Driver not found.", e);
        }
    }
    
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // Get form data from request
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        // Create a User object to hold the data
        User user = new User();
        user.setName(name);
        user.setEmail(email);
        user.setPhone(phone);
        user.setUsername(username);
        user.setPassword(password);

        // Logic to save user data in the database
        try {
            // Establish DB connection
            Connection connection = DriverManager.getConnection("jdbc:mysql://localhost:3306/ridesharedb", "root", "admin");

            // Prepare SQL query
            String query = "INSERT INTO users (name, email, phone, username, password) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement preparedStatement = connection.prepareStatement(query);
            preparedStatement.setString(1, user.getName());
            preparedStatement.setString(2, user.getEmail());
            preparedStatement.setString(3, user.getPhone());
            preparedStatement.setString(4, user.getUsername());
            preparedStatement.setString(5, user.getPassword());

            // Execute update
            int result = preparedStatement.executeUpdate();

            if (result > 0) {
                // Redirect to a success page or login page
                response.sendRedirect("index.jsp");
            } else {
                // Show error message if user was not saved
                request.setAttribute("errorMessage", "Registration failed. Please try again.");
                RequestDispatcher dispatcher = request.getRequestDispatcher("index.jsp");
                dispatcher.forward(request, response);
            }

            // Close the DB connection
            connection.close();
        } catch (SQLException e) {
            e.printStackTrace();
            // Handle database errors
            request.setAttribute("errorMessage", "Database error: " + e.getMessage());
            RequestDispatcher dispatcher = request.getRequestDispatcher("register.jsp");
            dispatcher.forward(request, response);
        }
    }
}
