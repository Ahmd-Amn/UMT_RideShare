package servlet;

import DAO.CarDao;
import Model.Car;
import java.io.IOException;
import java.sql.Connection;
import java.sql.DriverManager;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/CarServlet")
public class CarServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    private CarDao carDao;
    
    @Override
    public void init() throws ServletException {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            Connection con = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/ridesharedb", "root", "admin");
            carDao = new CarDao(con);
        } catch (Exception e) {
            throw new ServletException("Initialization failed", e);
        }
    }

    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        doGet(request, response);
    }

    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        String action = request.getParameter("action");
        
        try {
            switch (action != null ? action : "") {
                case "new":
                    showNewForm(request, response);
                    break;
                case "add":
                    addCar(request, response);
                    break;
                case "edit":
                    showEditForm(request, response);
                    break;
                case "update":
                    updateCar(request, response);
                    break;
                case "delete":
                    deleteCar(request, response);
                    break;
                default:
                    listCars(request, response);
                    break;
            }
        } catch (Exception e) {
            throw new ServletException(e);
        }
    }

    private void listCars(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");
        
        if (userId == null) {
            response.sendRedirect("login.jsp");
            return;
        }
        
        request.setAttribute("cars", carDao.getCarsByUserId(userId));
        request.getRequestDispatcher("Garage.jsp").forward(request, response);
    }

    private void showNewForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        request.getRequestDispatcher("addCar.jsp").forward(request, response);
    }

    private void showEditForm(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int carId = Integer.parseInt(request.getParameter("id"));
        Car existingCar = carDao.getCarById(carId);
        request.setAttribute("car", existingCar);
        request.getRequestDispatcher("editCar.jsp").forward(request, response);
    }

    private void addCar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");
        
        if (userId == null) {
            response.sendRedirect("index.jsp");
            return;
        }
        
        String plateNumber = request.getParameter("plateNumber");
        String color = request.getParameter("color");
        String carType = request.getParameter("carType");
        
        Car newCar = new Car(plateNumber, color, carType, userId);
        
        if (carDao.plateNumberExists(plateNumber)) {
            request.setAttribute("error", "Plate number already exists");
            request.getRequestDispatcher("Garage.jsp").forward(request, response);
            return;
        }
        
        boolean success = carDao.addCar(newCar);
        
        if (success) {
            response.sendRedirect("CarServlet?action=list&success=true");
        } else {
            request.setAttribute("error", "Failed to add car");
            request.getRequestDispatcher("Garage.jsp").forward(request, response);
        }
    }

    private void updateCar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int carId = Integer.parseInt(request.getParameter("id"));
        String plateNumber = request.getParameter("plateNumber");
        String color = request.getParameter("color");
        String carType = request.getParameter("carType");
        
        Car car = carDao.getCarById(carId);
        car.setPlateNumber(plateNumber);
        car.setColor(color);
        car.setCarType(carType);
        
        boolean success = carDao.updateCar(car);
        
        if (success) {
            response.sendRedirect("CarServlet?action=list&updated=true");
        } else {
            request.setAttribute("error", "Failed to update car");
            request.setAttribute("car", car);
            request.getRequestDispatcher("editCar.jsp").forward(request, response);
        }
    }

    private void deleteCar(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        int carId = Integer.parseInt(request.getParameter("id"));
        
        boolean success = carDao.deleteCar(carId);
        
        if (success) {
            response.sendRedirect("CarServlet?action=list&deleted=true");
        } else {
            request.setAttribute("error", "Failed to delete car");
            listCars(request, response);
        }
    }
}

