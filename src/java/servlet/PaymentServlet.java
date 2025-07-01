package servlet;

import com.stripe.Stripe;
import com.stripe.exception.StripeException;
import com.stripe.model.PaymentIntent;
import com.stripe.param.PaymentIntentCreateParams;
import java.io.IOException;
import java.io.Serializable;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Date;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/PaymentServlet")
public class PaymentServlet extends HttpServlet {
    private static final String STRIPE_SECRET_KEY = "sk_test_51ReoHoRscsSRGtE0IVSkGTrCxIthnOCKV7IsIJNOiTB2ODi6VWFI2aBfxfPpncZjw8Zu1g4dEEuO4vfDSsRWcTdr00D5I0HEJN";
    private final String jdbcURL = "jdbc:mysql://localhost:3306/ridesharedb";
    private final String jdbcUsername = "root";
    private final String jdbcPassword = "admin";
    
    @Override
    public void init() throws ServletException {
        Stripe.apiKey = STRIPE_SECRET_KEY;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
        } catch (ClassNotFoundException e) {
            throw new ServletException("MySQL JDBC Driver not found", e);
        }
    }
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(jdbcURL, jdbcUsername, jdbcPassword);
            
            int rideId = Integer.parseInt(request.getParameter("rideId"));
            double amount = Double.parseDouble(request.getParameter("amount"));
            String email = request.getParameter("email");
            String paymentMethod = request.getParameter("paymentMethod");
            int userId = (Integer) request.getSession().getAttribute("userId");
            
            // Generate transaction IDs
            String receiptNumber = "RCPT-" + System.currentTimeMillis();
            String transactionId = "TXN" + System.currentTimeMillis();
            
            // Process payment based on method
            if ("card".equals(paymentMethod)) {
                long amountInCents = (long)(amount * 100);
                PaymentIntentCreateParams params = PaymentIntentCreateParams.builder()
                    .setAmount(amountInCents)
                    .setCurrency("myr")
                    .setDescription("Payment for ride #" + rideId)
                    .setReceiptEmail(email)
                    .build();
                
                PaymentIntent paymentIntent = PaymentIntent.create(params);
                response.setContentType("application/json");
                response.getWriter().write("{\"clientSecret\": \"" + paymentIntent.getClientSecret() + "\"}");
            } else {
                // Save to database
                String sql = "INSERT INTO receipts (receipt_number, ride_id, user_id, amount, " +
                             "payment_method, transaction_id, email) VALUES (?, ?, ?, ?, ?, ?, ?)";
                
                try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                    stmt.setString(1, receiptNumber);
                    stmt.setInt(2, rideId);
                    stmt.setInt(3, userId);
                    stmt.setDouble(4, amount);
                    stmt.setString(5, paymentMethod);
                    stmt.setString(6, transactionId);
                    stmt.setString(7, email);
                    stmt.executeUpdate();
                }
                
                // Update ride status
                updateRideStatus(conn, rideId, 0); // 0 = booked status
                
                // Create receipt for session
                Receipt receipt = new Receipt();
                receipt.setReceiptNumber(receiptNumber);
                receipt.setPaymentDate(new Date());
                receipt.setRideId(rideId);
                receipt.setAmount(amount);
                receipt.setPaymentMethod(getPaymentMethodDisplayName(paymentMethod));
                receipt.setEmail(email);
                receipt.setTransactionId(transactionId);
                
                request.getSession().setAttribute("receipt", receipt);
                response.setContentType("application/json");
                response.getWriter().write("{\"status\":\"success\",\"redirectUrl\":\"receipt.jsp\"}");
            }
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write("{\"error\":\"" + e.getMessage() + "\"}");
            e.printStackTrace();
        } finally {
            if (conn != null) try { conn.close(); } catch (SQLException e) {}
        }
    }
    
    private void updateRideStatus(Connection conn, int rideId, int status) throws SQLException {
        String sql = "UPDATE rides SET status = ? WHERE id = ?";
        try (PreparedStatement stmt = conn.prepareStatement(sql)) {
            stmt.setInt(1, status);
            stmt.setInt(2, rideId);
            stmt.executeUpdate();
        }
    }
    
    private String getPaymentMethodDisplayName(String method) {
        switch(method.toLowerCase()) {
            case "grabpay": return "GrabPay";
            case "tng": return "Touch 'n Go";
            case "maybank": return "Maybank2U";
            case "card": return "Credit/Debit Card";
            default: return method;
        }
    }
    
    public static class Receipt implements Serializable {
        private String receiptNumber;
        private Date paymentDate;
        private int rideId;
        private double amount;
        private String paymentMethod;
        private String email;
        private String transactionId;

        // Getters and setters
        public String getReceiptNumber() { return receiptNumber; }
        public void setReceiptNumber(String receiptNumber) { this.receiptNumber = receiptNumber; }
        public Date getPaymentDate() { return paymentDate; }
        public void setPaymentDate(Date paymentDate) { this.paymentDate = paymentDate; }
        public int getRideId() { return rideId; }
        public void setRideId(int rideId) { this.rideId = rideId; }
        public double getAmount() { return amount; }
        public void setAmount(double amount) { this.amount = amount; }
        public String getPaymentMethod() { return paymentMethod; }
        public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }
        public String getEmail() { return email; }
        public void setEmail(String email) { this.email = email; }
        public String getTransactionId() { return transactionId; }
        public void setTransactionId(String transactionId) { this.transactionId = transactionId; }
    }
}
