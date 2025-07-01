package DAO;

import Model.Car;
import Model.Ride;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Time;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

public class RideDao {
    private static final Logger logger = Logger.getLogger(RideDao.class.getName());
    private Connection con;

    public RideDao(Connection connection) {
        this.con = connection;
    }

    // Allow connection to be updated after construction
    public void setConnection(Connection connection) {
        this.con = connection;
    }

    /**
     * Creates a new ride in the database
     * @param ride The ride to create
     * @return true if successful
     * @throws SQLException if database error occurs
     * @throws IllegalArgumentException if ride is null
     */
    public boolean createRide(Ride ride) throws SQLException {
        if (ride == null) {
            throw new IllegalArgumentException("Ride cannot be null");
        }

        String sql = "INSERT INTO rides (car_id, date, pickup_time, pickup_latitude, pickup_longitude, "
                   + "dropoff_latitude, dropoff_longitude, pickup_address, dropoff_address, "
                   + "available_seats, price, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

        try (PreparedStatement statement = con.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            setRideParameters(statement, ride);
            
            int affectedRows = statement.executeUpdate();
            if (affectedRows == 0) {
                logger.log(Level.WARNING, "Creating ride failed, no rows affected");
                throw new SQLException("Creating ride failed, no rows affected.");
            }
            
            try (ResultSet generatedKeys = statement.getGeneratedKeys()) {
                if (generatedKeys.next()) {
                    ride.setId(generatedKeys.getInt(1));
                    logger.log(Level.INFO, "Created ride with ID: {0}", ride.getId());
                    return true;
                } else {
                    logger.log(Level.SEVERE, "Creating ride failed, no ID obtained");
                    throw new SQLException("Creating ride failed, no ID obtained.");
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error creating ride", e);
            throw e;
        }
    }
    
    /**
     * Gets all cars for a specific user
     * @param userId The user ID
     * @return List of cars
     * @throws SQLException if database error occurs
     */
    public List<Car> getCarsByUserId(int userId) throws SQLException {
        List<Car> cars = new ArrayList<>();
        String query = "SELECT * FROM cars WHERE user_id = ?";

        try (PreparedStatement ps = con.prepareStatement(query)) {
            ps.setInt(1, userId);

            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Car car = new Car();
                    car.setId(rs.getInt("id"));
                    car.setPlateNumber(rs.getString("plate_number"));
                    car.setColor(rs.getString("color"));
                    car.setCarType(rs.getString("car_type"));
                    car.setUserId(rs.getInt("user_id"));
                    cars.add(car);
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting cars for user ID: " + userId, e);
            throw e;
        }
        return cars;
    }

    /**
     * Gets all rides (admin view)
     * @return List of all rides
     * @throws SQLException if database error occurs
     */
    public List<Ride> getAllRides() throws SQLException {
        List<Ride> rides = new ArrayList<>();
        String sql = "SELECT r.*, c.plate_number, c.car_type, c.color, u.username as driver_name "
                   + "FROM rides r JOIN cars c ON r.car_id = c.id "
                   + "JOIN users u ON c.user_id = u.id "
                   + "ORDER BY r.date DESC, r.pickup_time DESC";
        
        try (PreparedStatement statement = con.prepareStatement(sql);
             ResultSet resultSet = statement.executeQuery()) {
            
            while (resultSet.next()) {
                Ride ride = mapResultSetToRide(resultSet);
                ride.setCarPlateNumber(resultSet.getString("plate_number"));
                ride.setCarType(resultSet.getString("car_type"));
                ride.setCarColor(resultSet.getString("color"));
                rides.add(ride);
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting all rides", e);
            throw e;
        }
        return rides;
    }

    /**
     * Gets rides by specific driver
     * @param driverId The driver's user ID
     * @return List of rides for the driver
     * @throws SQLException if database error occurs
     */
    public List<Ride> getRidesByDriver(int driverId) throws SQLException {
        List<Ride> rides = new ArrayList<>();
        String sql = "SELECT r.*, c.plate_number, c.car_type, c.color "
                   + "FROM rides r JOIN cars c ON r.car_id = c.id "
                   + "WHERE c.user_id = ? "
                   + "ORDER BY r.date DESC, r.pickup_time DESC";

        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, driverId);

            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Ride ride = mapResultSetToRide(resultSet);
                    ride.setCarPlateNumber(resultSet.getString("plate_number"));
                    ride.setCarType(resultSet.getString("car_type"));
                    ride.setCarColor(resultSet.getString("color"));
                    rides.add(ride);
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting rides for driver ID: " + driverId, e);
            throw e;
        }
        return rides;
    }

    /**
     * Gets a single ride by ID
     * @param rideId The ride ID
     * @return Ride object or null if not found
     * @throws SQLException if database error occurs
     */
    public Ride getRideById(int rideId) throws SQLException {
        String sql = "SELECT r.*, c.plate_number, c.car_type, c.color, u.username as driver_name "
                   + "FROM rides r JOIN cars c ON r.car_id = c.id "
                   + "JOIN users u ON c.user_id = u.id "
                   + "WHERE r.id = ?";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, rideId);
            
            try (ResultSet resultSet = statement.executeQuery()) {
                if (resultSet.next()) {
                    Ride ride = mapResultSetToRide(resultSet);
                    ride.setCarPlateNumber(resultSet.getString("plate_number"));
                    ride.setCarType(resultSet.getString("car_type"));
                    ride.setCarColor(resultSet.getString("color"));
                    return ride;
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting ride by ID: " + rideId, e);
            throw e;
        }
        return null;
    }

    /**
     * Updates ride status
     * @param rideId The ride ID
     * @param status The new status
     * @return true if successful
     * @throws SQLException if database error occurs
     */
    public boolean updateRideStatus(int rideId, int status) throws SQLException {
        String sql = "UPDATE rides SET status = ? WHERE id = ?";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, status);
            statement.setInt(2, rideId);
            
            int affectedRows = statement.executeUpdate();
            if (affectedRows > 0) {
                logger.log(Level.INFO, "Updated status for ride ID: {0} to {1}", new Object[]{rideId, status});
                return true;
            }
            logger.log(Level.WARNING, "No ride found with ID: {0}", rideId);
            return false;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error updating status for ride ID: " + rideId, e);
            throw e;
        }
    }

    /**
     * Deletes a ride
     * @param rideId The ride ID
     * @return true if successful
     * @throws SQLException if database error occurs
     */
    public boolean deleteRide(int rideId) throws SQLException {
        String sql = "DELETE FROM rides WHERE id = ?";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, rideId);
            
            int affectedRows = statement.executeUpdate();
            if (affectedRows > 0) {
                logger.log(Level.INFO, "Deleted ride with ID: {0}", rideId);
                return true;
            }
            logger.log(Level.WARNING, "No ride found with ID: {0}", rideId);
            return false;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error deleting ride ID: " + rideId, e);
            throw e;
        }
    }

    /**
     * Gets available rides for passengers to book
     * @param excludeUserId User ID to exclude (driver's own rides)
     * @return List of available rides
     * @throws SQLException if database error occurs
     */
    public List<Ride> getAvailableRides(int excludeUserId) throws SQLException {
        List<Ride> rides = new ArrayList<>();
        String sql = "SELECT r.*, c.plate_number, c.car_type, c.color, u.username as driver_name "
                   + "FROM rides r "
                   + "JOIN cars c ON r.car_id = c.id "
                   + "JOIN users u ON c.user_id = u.id "
                   + "WHERE r.status = 1 AND r.available_seats > 0 "
                   + "AND c.user_id != ? "
                   + "ORDER BY r.date, r.pickup_time";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, excludeUserId);
            
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Ride ride = mapResultSetToRide(resultSet);
                    ride.setCarPlateNumber(resultSet.getString("plate_number"));
                    ride.setCarType(resultSet.getString("car_type"));
                    ride.setCarColor(resultSet.getString("color"));
                    rides.add(ride);
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error getting available rides excluding user ID: " + excludeUserId, e);
            throw e;
        }
        return rides;
    }

    /**
     * Searches available rides with filters
     * @param pickupLocation Partial pickup location match
     * @param dropoffLocation Partial dropoff location match
     * @param date Exact date match
     * @param excludeUserId User ID to exclude
     * @return List of matching rides
     * @throws SQLException if database error occurs
     */
    public List<Ride> searchAvailableRides(String pickupLocation, String dropoffLocation, 
                                         String date, int excludeUserId) throws SQLException {
        List<Ride> rides = new ArrayList<>();
        StringBuilder sql = new StringBuilder(
            "SELECT r.*, c.plate_number, c.car_type, c.color, u.username as driver_name "
            + "FROM rides r "
            + "JOIN cars c ON r.car_id = c.id "
            + "JOIN users u ON c.user_id = u.id "
            + "WHERE r.status = 1 AND r.available_seats > 0 "
            + "AND c.user_id != ? "
        );
        
        List<Object> params = new ArrayList<>();
        params.add(excludeUserId);
        
        if (pickupLocation != null && !pickupLocation.isEmpty()) {
            sql.append("AND r.pickup_address LIKE ? ");
            params.add("%" + pickupLocation + "%");
        }
        
        if (dropoffLocation != null && !dropoffLocation.isEmpty()) {
            sql.append("AND r.dropoff_address LIKE ? ");
            params.add("%" + dropoffLocation + "%");
        }
        
        if (date != null && !date.isEmpty()) {
            sql.append("AND r.date = ? ");
            params.add(Date.valueOf(date));
        }
        
        sql.append("ORDER BY r.date, r.pickup_time");
        
        try (PreparedStatement statement = con.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                statement.setObject(i + 1, params.get(i));
            }
            
            try (ResultSet resultSet = statement.executeQuery()) {
                while (resultSet.next()) {
                    Ride ride = mapResultSetToRide(resultSet);
                    ride.setCarPlateNumber(resultSet.getString("plate_number"));
                    ride.setCarType(resultSet.getString("car_type"));
                    ride.setCarColor(resultSet.getString("color"));
                    rides.add(ride);
                }
            }
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error searching available rides", e);
            throw e;
        }
        return rides;
    }

    /**
     * Updates available seats for a ride
     * @param rideId The ride ID
     * @param seatChange The change in seats (positive or negative)
     * @return true if successful
     * @throws SQLException if database error occurs
     */
    public boolean updateAvailableSeats(int rideId, int seatChange) throws SQLException {
        String sql = "UPDATE rides SET available_seats = available_seats + ? "
                   + "WHERE id = ? AND available_seats + ? >= 0";

        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, seatChange);
            statement.setInt(2, rideId);
            statement.setInt(3, seatChange);

            int affectedRows = statement.executeUpdate();
            if (affectedRows > 0) {
                logger.log(Level.INFO, "Updated seats for ride ID: {0} by {1}", new Object[]{rideId, seatChange});
                return true;
            }
            logger.log(Level.WARNING, "Failed to update seats for ride ID: {0}", rideId);
            return false;
        } catch (SQLException e) {
            logger.log(Level.SEVERE, "Error updating seats for ride ID: " + rideId, e);
            throw e;
        }
    }

    // Helper method to set ride parameters in prepared statement
    private void setRideParameters(PreparedStatement statement, Ride ride) throws SQLException {
        statement.setInt(1, ride.getCarId());
        statement.setDate(2, new Date(ride.getDate().getTime()));
        statement.setTime(3, new Time(ride.getPickupTime().getTime()));
        statement.setDouble(4, ride.getPickupLatitude());
        statement.setDouble(5, ride.getPickupLongitude());
        statement.setDouble(6, ride.getDropoffLatitude());
        statement.setDouble(7, ride.getDropoffLongitude());
        statement.setString(8, ride.getPickupAddress());
        statement.setString(9, ride.getDropoffAddress());
        statement.setInt(10, ride.getAvailableSeats());
        statement.setDouble(11, ride.getPrice());
        statement.setInt(12, ride.getStatus());
    }

    // Helper method to map ResultSet to Ride object
    private Ride mapResultSetToRide(ResultSet resultSet) throws SQLException {
        Ride ride = new Ride();
        ride.setId(resultSet.getInt("id"));
        ride.setCarId(resultSet.getInt("car_id"));
        ride.setDate(resultSet.getDate("date"));
        ride.setPickupTime(resultSet.getTime("pickup_time"));
        ride.setPickupLatitude(resultSet.getDouble("pickup_latitude"));
        ride.setPickupLongitude(resultSet.getDouble("pickup_longitude"));
        ride.setDropoffLatitude(resultSet.getDouble("dropoff_latitude"));
        ride.setDropoffLongitude(resultSet.getDouble("dropoff_longitude"));
        ride.setPickupAddress(resultSet.getString("pickup_address"));
        ride.setDropoffAddress(resultSet.getString("dropoff_address"));
        ride.setAvailableSeats(resultSet.getInt("available_seats"));
        ride.setPrice(resultSet.getDouble("price"));
        ride.setStatus(resultSet.getInt("status"));
        return ride;
    }
}
