package DAO;

import Model.Car;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class CarDao {
    
    private Connection con;
    
    public CarDao(Connection con) {
        this.con = con;
    }

    // Add a new car to the database
    public boolean addCar(Car car) {
        boolean success = false;
        try {
            String query = "INSERT INTO cars (plate_number, color, car_type, user_id) VALUES (?, ?, ?, ?)";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setString(1, car.getPlateNumber());
            ps.setString(2, car.getColor());
            ps.setString(3, car.getCarType());
            ps.setInt(4, car.getUserId());
            
            int rowsAffected = ps.executeUpdate();
            if (rowsAffected == 1) {
                success = true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return success;
    }

    // Get all cars for a specific user
    public List<Car> getCarsByUserId(int userId) {
        List<Car> cars = new ArrayList<>();
        try {
            String query = "SELECT * FROM cars WHERE user_id = ?";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setInt(1, userId);
            
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Car car = new Car();
                car.setId(rs.getInt("id"));
                car.setPlateNumber(rs.getString("plate_number"));
                car.setColor(rs.getString("color"));
                car.setCarType(rs.getString("car_type"));
                car.setUserId(rs.getInt("user_id"));
                cars.add(car);
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return cars;
    }

    // Get a single car by its ID
    public Car getCarById(int carId) {
        Car car = null;
        try {
            String query = "SELECT * FROM cars WHERE id = ?";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setInt(1, carId);
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                car = new Car();
                car.setId(rs.getInt("id"));
                car.setPlateNumber(rs.getString("plate_number"));
                car.setColor(rs.getString("color"));
                car.setCarType(rs.getString("car_type"));
                car.setUserId(rs.getInt("user_id"));
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return car;
    }

    // Update car information
    public boolean updateCar(Car car) {
        boolean success = false;
        try {
            String query = "UPDATE cars SET plate_number = ?, color = ?, car_type = ? WHERE id = ?";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setString(1, car.getPlateNumber());
            ps.setString(2, car.getColor());
            ps.setString(3, car.getCarType());
            ps.setInt(4, car.getId());
            
            int rowsAffected = ps.executeUpdate();
            if (rowsAffected == 1) {
                success = true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return success;
    }

    // Delete a car
    public boolean deleteCar(int carId) {
        boolean success = false;
        try {
            String query = "DELETE FROM cars WHERE id = ?";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setInt(1, carId);
            
            int rowsAffected = ps.executeUpdate();
            if (rowsAffected == 1) {
                success = true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return success;
    }

    // Check if plate number already exists (for validation)
    public boolean plateNumberExists(String plateNumber) {
        boolean exists = false;
        try {
            String query = "SELECT id FROM cars WHERE plate_number = ?";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setString(1, plateNumber);
            
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                exists = true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return exists;
    }

}

