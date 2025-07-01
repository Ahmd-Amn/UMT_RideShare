/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/JSP_Servlet/Servlet.java to edit this template
 */
package servlet;

import DAO.UserDao;
import Model.User;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;


/**
 *
 * @author Amin
 */
@WebServlet("/UserServlet") 
public class UserServlet extends HttpServlet {
    private static  final long serialVersionUID = 1L;
    private UserDao userDao;
    
    public void init(){
        try{
            Class.forName("com.mysql.jdbc.Driver");
            Connection con = DriverManager.getConnection("jdbc:mysql://localhost:3306/ridesharedb", "root", "admin");
            userDao = new UserDao(con);
        } catch(Exception e){
            e.printStackTrace();
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        
            try {
            if(action == null) {
                showUserProfile(request, response);
                return;
            }

            switch(action){
                case "register":
                    registerForm(request, response);
                    break;
                case "insert":
                    insertUser(request, response);
                    break;
                case "update":
                    updateUser(request, response);
                    break;
                case "changePassword":
                    changePassword (request, response);
                    break;
                case "userProfile":
                    showUserProfile(request, response);
                    break;
            }
        } catch(Exception e){
            e.printStackTrace();
            request.getSession().setAttribute("errorMessage", "An error occurred: " + e.getMessage());
            response.sendRedirect("userProfile.jsp");
        }
    }
    
    private void registerForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException{
        RequestDispatcher dispatcher = request.getRequestDispatcher("register.jsp");
        dispatcher.forward(request, response);
    }
    
    
    private void showUserProfile(HttpServletRequest request, HttpServletResponse response)
        throws ServletException, IOException {
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        try {
            User user = userDao.getUserById(userId);
            if (user != null) {
                request.setAttribute("user", user); // This sets the user attribute
                RequestDispatcher dispatcher = request.getRequestDispatcher("userProfile.jsp");
                dispatcher.forward(request, response);
            } else {
                session.setAttribute("errorMessage", "User not found");
                response.sendRedirect("login.jsp");
            }
        } catch (SQLException e) {
            session.setAttribute("errorMessage", "Database error: " + e.getMessage());
            response.sendRedirect("login.jsp");
        }
    }


     private void insertUser(HttpServletRequest request, HttpServletResponse response)
            throws IOException {
        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        
        User newUser = new User();
        newUser.setName(name);
        newUser.setEmail(email);
        newUser.setPhone(phone);
        newUser.setUsername(username);
        newUser.setPassword(password);
        
        userDao.addUser(newUser);
        response.sendRedirect("success.jsp");
    }
     
      private void updateUser(HttpServletRequest request, HttpServletResponse response)
        throws IOException, ServletException, SQLException {
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("index.jsp");
            return;
        }

        String name = request.getParameter("name");
        String email = request.getParameter("email");
        String phone = request.getParameter("phone");
        String username = request.getParameter("username");

        User user = new User();
        user.setId(userId);
        user.setName(name);
        user.setEmail(email);
        user.setPhone(phone);
        user.setUsername(username);

        boolean success = userDao.updateUser(user);

        if (success) {
            session.setAttribute("successMessage", "Profile updated successfully");
        } else {
            session.setAttribute("errorMessage", "Failed to update profile");
        }

        User updatedUser = userDao.getUserById(userId);
        request.setAttribute("user", updatedUser);
        request.getRequestDispatcher("/userProfile.jsp").forward(request, response);
    }
    
    private void changePassword(HttpServletRequest request, HttpServletResponse response) 
        throws IOException, ServletException, SQLException {
    
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // Get form parameters
        String currentPassword = request.getParameter("currentPassword");
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        // Basic validation
        if (newPassword == null || !newPassword.equals(confirmPassword)) {
            session.setAttribute("errorMessage", "New passwords don't match");
            response.sendRedirect("userProfile.jsp");
            return;
        }

        try {
            // Get current user data
            User currentUser = userDao.getUserById(userId);

            // Verify current password (plain text comparison - not secure)
            if (currentUser == null || !currentUser.getPassword().equals(currentPassword)) {
                session.setAttribute("errorMessage", "Current password is incorrect");
                response.sendRedirect("userProfile.jsp");
                return;
            }

            // Update password
            User updatedUser = new User();
            updatedUser.setId(userId);
            updatedUser.setPassword(newPassword); // In production, hash this password

            boolean success = userDao.updateUserPassword(updatedUser);

            if (success) {
                session.setAttribute("successMessage", "Password changed successfully");
            } else {
                session.setAttribute("errorMessage", "Failed to update password");
            }
        } catch (Exception e) {
            session.setAttribute("errorMessage", "Error: " + e.getMessage());
            e.printStackTrace();
        }

        User updateUserPassword = userDao.getUserById(userId);
        request.setAttribute("user", updateUserPassword);
        request.getRequestDispatcher("/userProfile.jsp").forward(request, response);
    }
      
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }

    /**
     * Returns a short description of the servlet.
     *
     * @return a String containing servlet description
     */
    @Override
    public String getServletInfo() {
        return "Short description";
    }// </editor-fold>

}
