package DAO;

import Model.Booking;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class BookingDao {
    private static final Logger logger = Logger.getLogger(BookingDao.class.getName());
    private Connection con;

    public BookingDao(Connection connection) {
        this.con = connection;
    }

    // Allow connection to be updated after construction
    public void setConnection(Connection connection) {
        this.con = connection;
    }

    /**
     * Creates a new booking in the database
     * @param booking The booking to create
     * @return true if successful, false otherwise
     * @throws SQLException if a database error occurs
     */
    public boolean createBooking(Booking booking) throws SQLException {
        if (booking == null) {
            throw new IllegalArgumentException("Booking cannot be null");
        }

        String sql = "INSERT INTO bookings (user_id, ride_id, payment_id, status, created_at) " +
                   "VALUES (?, ?, ?, ?, NOW())";
        
        try (PreparedStatement statement = con.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            statement.setInt(1, booking.getUserId());
            statement.setInt(2, booking.getRideId());
            statement.setString(3, booking.getPaymentId());
            statement.setInt(4, booking.getStatus());
            
            int affectedRows = statement.executeUpdate();
            if (affectedRows == 0) {
                logger.log(Level.WARNING, "Failed to create booking, no rows affected");
                return false;
            }
            
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    booking.setId(generatedKeys.getInt(1));
                    logger.log(Level.INFO, "Created booking with ID: {0}", booking.getId());
                } else {
                    logger.log(Level.WARNING, "Failed to retrieve generated booking ID");
                }
            }
            return true;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error creating booking", e);
            throw e;
        }
    }

    /**
     * Retrieves a booking by its ID
     * @param id The booking ID
     * @return The Booking object or null if not found
     * @throws SQLException if a database error occurs
     */
    public Booking getBookingById(int id) throws SQLException {
        String sql = "SELECT * FROM bookings WHERE id = ?";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, id);
            
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    return mapResultSetToBooking(resultSet);
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error retrieving booking by ID: " + id, e);
            throw e;
        }
        return null;
    }

    /**
     * Retrieves all bookings for a specific user
     * @param userId The user ID
     * @return List of bookings for the user
     * @throws SQLException if a database error occurs
     */
    public List<Booking> getBookingsByUser(int userId) throws SQLException {
        List<Booking> bookings = new ArrayList<>();
        String sql = "SELECT * FROM bookings WHERE user_id = ? ORDER BY created_at DESC";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, userId);
            
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    bookings.add(mapResultSetToBooking(resultSet));
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error retrieving bookings for user: " + userId, e);
            throw e;
        }
        return bookings;
    }

    /**
     * Updates a booking's status
     * @param bookingId The booking ID
     * @param newStatus The new status value
     * @return true if successful, false otherwise
     * @throws SQLException if a database error occurs
     */
    public boolean updateBookingStatus(int bookingId, int newStatus) throws SQLException {
        String sql = "UPDATE bookings SET status = ? WHERE id = ?";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, newStatus);
            statement.setInt(2, bookingId);
            
            int affectedRows = statement.executeUpdate();
            if (affectedRows == 0) {
                logger.log(Level.WARNING, "No booking found with ID: {0}", bookingId);
                return false;
            }
            return true;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error updating booking status for ID: " + bookingId, e);
            throw e;
        }
    }

    /**
     * Cancels a booking (sets status to cancelled)
     * @param bookingId The booking ID
     * @return true if successful, false otherwise
     * @throws SQLException if a database error occurs
     */
    public boolean cancelBooking(int bookingId) throws SQLException {
        return updateBookingStatus(bookingId, 0); // Assuming 0 = cancelled status
    }

    /**
     * Maps a ResultSet row to a Booking object
     * @param resultSet The ResultSet containing booking data
     * @return A Booking object
     * @throws SQLException if a database error occurs
     */
    private Booking mapResultSetToBooking(ResultSet resultSet) throws SQLException {
        Booking booking = new Booking();
        booking.setId(resultSet.getInt("id"));
        booking.setUserId(resultSet.getInt("user_id"));
        booking.setRideId(resultSet.getInt("ride_id"));
        booking.setPaymentId(resultSet.getString("payment_id"));
        booking.setStatus(resultSet.getInt("status"));
        booking.setCreatedAt(resultSet.getTimestamp("created_at"));
        return booking;
    }
}
