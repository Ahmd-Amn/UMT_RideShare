package servlet;

import DAO.BookingDao;
import DAO.RideDao;
import Model.Booking;
import Model.Ride;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/BookServlet")
public class BookServlet extends HttpServlet {
    private static final Logger logger = Logger.getLogger(BookServlet.class.getName());
    
    private BookingDao bookingDao;
    private RideDao rideDao;
    private final String jdbcURL = "jdbc:mysql://localhost:3306/ridesharedb";
    private final String jdbcUsername = "root";
    private final String jdbcPassword = "admin";

    @Override
    public void init() throws ServletException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection connection = DriverManager.getConnection(jdbcURL, jdbcUsername, jdbcPassword);
            bookingDao = new BookingDao(connection);
            rideDao = new RideDao(connection);
        } catch (ClassNotFoundException | SQLException e) {
            logger.log(Level.SEVERE, "Database initialization failed", e);
            throw new ServletException("Database initialization failed", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        Connection connection = null;
        try {
            // Get user ID from session
            Integer userId = (Integer) request.getSession().getAttribute("userId");
            if (userId == null) {
                response.sendRedirect("index.jsp");
                return;
            }

            // Create new connection for this request
            connection = DriverManager.getConnection(jdbcURL, jdbcUsername, jdbcPassword);
            rideDao.setConnection(connection); // Update DAO with new connection

            // Get search parameters
            String pickupLocation = request.getParameter("pickupLocation");
            String dropoffLocation = request.getParameter("dropoffLocation");
            String dateParam = request.getParameter("searchDate");
            
            List<Ride> availableRides;
            
            if (pickupLocation != null || dropoffLocation != null || dateParam != null) {
                // Search with filters excluding current user's rides
                availableRides = rideDao.searchAvailableRides(
                    pickupLocation, 
                    dropoffLocation, 
                    dateParam,
                    userId
                );
            } else {
                // Show all available rides except current user's
                availableRides = rideDao.getAvailableRides(userId);
            }
            
            if (availableRides == null) {
                throw new ServletException("No rides available or error retrieving rides");
            }
            
            request.setAttribute("rides", availableRides);
            request.getRequestDispatcher("Book.jsp").forward(request, response);
            
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Database error in doGet", e);
            throw new ServletException("Database error", e);
        } finally {
            // Close connection in finally block
            if (connection != null) {
                try {
                    connection.close();
                } catch (SQLException e) {
                    logger.log(Level.WARNING, "Failed to close connection", e);
                }
            }
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        Connection connection = null;
        try {
            // Get parameters from request
            int rideId = Integer.parseInt(request.getParameter("rideId"));
            Integer userId = (Integer) request.getSession().getAttribute("userId");
            String paymentId = request.getParameter("paymentId");

            if (userId == null) {
                response.sendRedirect("index.jsp");
                return;
            }

            // Start transaction
            connection = DriverManager.getConnection(jdbcURL, jdbcUsername, jdbcPassword);
            connection.setAutoCommit(false);
            
            // Update DAOs with current connection
            bookingDao.setConnection(connection);
            rideDao.setConnection(connection);

            // 1. Create booking record
            Booking booking = new Booking();
            booking.setUserId(userId);
            booking.setRideId(rideId);
            booking.setPaymentId(paymentId);
            booking.setStatus(1); // 1 = confirmed

            boolean bookingCreated = bookingDao.createBooking(booking);
            if (!bookingCreated) {
                throw new ServletException("Failed to create booking record");
            }

            // 2. Update ride's available seats
            boolean seatsUpdated = rideDao.updateAvailableSeats(rideId, -1); // Decrease by 1
            if (!seatsUpdated) {
                throw new ServletException("Failed to update available seats");
            }

            // Commit transaction
            connection.commit();

            // Redirect to success page
            response.sendRedirect("BookingSuccess.jsp?rideId=" + rideId + "&paymentId=" + paymentId);

        } catch (NumberFormatException e) {
            rollbackTransaction(connection);
            logger.log(Level.SEVERE, "Invalid ride ID", e);
            throw new ServletException("Invalid ride ID", e);
        } catch (SQLException e) {
            rollbackTransaction(connection);
            logger.log(Level.SEVERE, "Database error during booking", e);
            throw new ServletException("Database error during booking", e);
        } finally {
            closeConnection(connection);
        }
    }

    private void rollbackTransaction(Connection connection) {
        if (connection != null) {
            try {
                connection.rollback();
            } catch (SQLException ex) {
                logger.log(Level.SEVERE, "Error during rollback", ex);
            }
        }
    }

    private void closeConnection(Connection connection) {
        if (connection != null) {
            try {
                connection.setAutoCommit(true); // Reset auto-commit
                connection.close();
            } catch (SQLException ex) {
                logger.log(Level.WARNING, "Failed to close connection", ex);
            }
        }
    }
}
