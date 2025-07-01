
package servlet;

import DAO.RideDao;
import DAO.CarDao;
import Model.Ride;
import Model.Car;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.sql.Date;
import java.sql.Time;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.RequestDispatcher;

@WebServlet("/RideServlet")
public class RideServlet extends HttpServlet {
    private RideDao rideDao;
    private CarDao carDao;
    private final String jdbcURL = "jdbc:mysql://localhost:3306/ridesharedb";
    private final String jdbcUsername = "root";
    private final String jdbcPassword = "admin";

    @Override
    public void init() throws ServletException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection connection = DriverManager.getConnection(jdbcURL, jdbcUsername, jdbcPassword);
            rideDao = new RideDao(connection);
            carDao = new CarDao(connection);
        } catch (ClassNotFoundException | SQLException e) {
            throw new ServletException("Database initialization failed", e);
        }
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        try {
            Integer userId = getUserIdFromSession(request, response);
            if (userId == null) return;

            String action = request.getParameter("action");
            if (action == null) action = "list";

            switch (action) {
                case "new":
                    showRideForm(request, response, userId, null);
                    break;
                case "edit":
                    showEditForm(request, response, userId);
                    break;
                case "list":
                default:
                    listRidesAndCars(request, response, userId);
                    break;
            }
        } catch (SQLException e) {
            handleError(request, response, "Database error: " + e.getMessage());
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        try {
            Integer userId = getUserIdFromSession(request, response);
            if (userId == null) return;

            String action = request.getParameter("action");
            if (action == null) action = "create";

            switch (action) {
                case "create":
                    createRide(request, response, userId);
                    break;
                case "update":
                    updateRide(request, response);
                    break;
                case "delete":
                    deleteRide(request, response);
                    break;
                case "cancel":
                    cancelRide(request, response);
                    break;
                default:
                    listRidesAndCars(request, response, userId);
            }
        } catch (SQLException | ParseException e) {
            handleError(request, response, "Database error: " + e.getMessage());
        }
    }

    private Integer getUserIdFromSession(HttpServletRequest request, HttpServletResponse response) 
            throws IOException {
        Integer userId = (Integer) request.getSession().getAttribute("userId");
        if (userId == null) {
            response.sendRedirect("login.jsp");
            return null;
        }
        return userId;
    }

    private void listRidesAndCars(HttpServletRequest request, HttpServletResponse response, int userId)
        throws SQLException, ServletException, IOException {
        List<Ride> rides = rideDao.getRidesByDriver(userId);
        List<Car> cars = rideDao.getCarsByUserId(userId);

        request.setAttribute("rides", rides);
        request.setAttribute("cars", cars);
        request.getRequestDispatcher("Ride.jsp").forward(request, response);
    }

    private void showRideForm(HttpServletRequest request, HttpServletResponse response, int userId, Ride ride)
        throws SQLException, ServletException, IOException {
        List<Car> cars = rideDao.getCarsByUserId(userId);

        if (cars.isEmpty()) {
            request.setAttribute("errorMessage", "You need to register a car first before creating rides");
            request.getRequestDispatcher("CarServlet").forward(request, response);
            return;
        }

        request.setAttribute("cars", cars);
        if (ride != null) {
            request.setAttribute("ride", ride);
        }
        request.getRequestDispatcher("Ride.jsp").forward(request, response);
    }

    private void showEditForm(HttpServletRequest request, HttpServletResponse response, int userId)
            throws SQLException, ServletException, IOException {
        int rideId = Integer.parseInt(request.getParameter("id"));
        Ride existingRide = rideDao.getRideById(rideId);
        
        if (existingRide == null) {
            handleError(request, response, "Ride not found");
            return;
        }
        
        showRideForm(request, response, userId, existingRide);
    }

    private void createRide(HttpServletRequest request, HttpServletResponse response, int userId)
            throws SQLException, ParseException, IOException, ServletException {
        try {
            Ride newRide = createRideFromRequest(request);
            rideDao.createRide(newRide);
            response.sendRedirect("RideServlet");
        } catch (IllegalArgumentException e) {
            handleError(request, response, "Invalid input: " + e.getMessage());
        }
    }

    private Ride createRideFromRequest(HttpServletRequest request) throws ParseException {
        int carId = Integer.parseInt(request.getParameter("car_id"));
        Date date = Date.valueOf(request.getParameter("date"));
        Time pickupTime = Time.valueOf(request.getParameter("pickup_time") + ":00");
        double pickupLat = Double.parseDouble(request.getParameter("pickup_latitude"));
        double pickupLng = Double.parseDouble(request.getParameter("pickup_longitude"));
        double dropoffLat = Double.parseDouble(request.getParameter("dropoff_latitude"));
        double dropoffLng = Double.parseDouble(request.getParameter("dropoff_longitude"));
        String pickupAddress = request.getParameter("pickup_address");
        String dropoffAddress = request.getParameter("dropoff_address");
        int availableSeats = Integer.parseInt(request.getParameter("available_seats"));
        double price = Double.parseDouble(request.getParameter("price"));

        return new Ride(carId, date, pickupTime, pickupLat, pickupLng, 
              dropoffLat, dropoffLng, pickupAddress, dropoffAddress, 
              availableSeats, price);
    }

    private void updateRide(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException, ServletException {
        int rideId = Integer.parseInt(request.getParameter("id"));
        int status = Integer.parseInt(request.getParameter("status"));
        
        if (!rideDao.updateRideStatus(rideId, status)) {
            handleError(request, response, "Failed to update ride status");
            return;
        }
        
        response.sendRedirect("RideServlet");
    }

    private void cancelRide(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException, ServletException {
        int rideId = Integer.parseInt(request.getParameter("rideId"));
        
        if (!rideDao.updateRideStatus(rideId, -1)) {
            handleError(request, response, "Failed to cancel ride");
            return;
        }
        
        response.sendRedirect("RideServlet");
    }

    private void deleteRide(HttpServletRequest request, HttpServletResponse response)
            throws SQLException, IOException, ServletException {
        int rideId = Integer.parseInt(request.getParameter("id"));
        
        if (!rideDao.deleteRide(rideId)) {
            handleError(request, response, "Failed to delete ride");
            return;
        }
        
        response.sendRedirect("RideServlet");
    }

    private void handleError(HttpServletRequest request, HttpServletResponse response, String message)
            throws ServletException, IOException {
        request.setAttribute("errorMessage", message);
        request.getRequestDispatcher("Ride.jsp").forward(request, response);
    }

}
