package servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/ViewReceiptServlet")
public class ViewReceiptServlet extends HttpServlet {
    private final String jdbcURL = "jdbc:mysql://localhost:3306/ridesharedb";
    private final String jdbcUsername = "root";
    private final String jdbcPassword = "admin";
    
    @Override
    public void init() throws ServletException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("MySQL JDBC Driver not found", e);
        }
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        Connection conn = null;
        try {
            String receiptId = request.getParameter("id");
            Integer userId = (Integer) request.getSession().getAttribute("userId");
            
            if (userId == null) {
                response.sendRedirect("login.jsp");
                return;
            }
            
            conn = DriverManager.getConnection(jdbcURL, jdbcUsername, jdbcPassword);
            String sql = "SELECT r.*, rd.date as ride_date, rd.pickup_time, " +
                         "rd.pickup_address, rd.dropoff_address " +
                         "FROM receipts r JOIN rides rd ON r.ride_id = rd.id " +
                         "WHERE r.receipt_number = ? AND r.user_id = ?";
            
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, receiptId);
                stmt.setInt(2, userId);
                
                ResultSet rs = stmt.executeQuery();
                if (rs.next()) {
                    PaymentServlet.Receipt receipt = new PaymentServlet.Receipt();
                    receipt.setReceiptNumber(rs.getString("receipt_number"));
                    receipt.setPaymentDate(rs.getTimestamp("created_at"));
                    receipt.setRideId(rs.getInt("ride_id"));
                    receipt.setAmount(rs.getDouble("amount"));
                    receipt.setPaymentMethod(rs.getString("payment_method"));
                    receipt.setEmail(rs.getString("email"));
                    receipt.setTransactionId(rs.getString("transaction_id"));
                    
                    // Add ride details
                    request.setAttribute("rideDate", rs.getDate("ride_date"));
                    request.setAttribute("pickupTime", rs.getTime("pickup_time"));
                    request.setAttribute("pickupAddress", rs.getString("pickup_address"));
                    request.setAttribute("dropoffAddress", rs.getString("dropoff_address"));
                    
                    request.setAttribute("receipt", receipt);
                    request.getRequestDispatcher("receipt.jsp").forward(request, response);
                } else {
                    response.sendRedirect("userProfile.jsp?error=receipt_not_found");
                }
            }
        } catch (Exception e) {
            response.sendRedirect("userProfile.jsp?error=server_error");
            e.printStackTrace();
        } finally {
            if (conn != null) {
                try { conn.close(); } catch (SQLException e) {}
            }
        }
    }
}
