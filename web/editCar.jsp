<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Edit Vehicle - CarPool</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: url('img/hp.jpg') no-repeat center center fixed; 
            background-size: cover;
            color: #fff;
            min-height: 100vh;
        }

        .navbar {
            background-color: rgba(0, 0, 0, 0.7);
            padding: 15px 0;
        }

        .navbar-brand {
            font-size: 1.5rem;
            font-weight: bold;
        }

        .nav-link {
            color: #fff !important;
            margin: 0 10px;
        }

        .nav-link:hover {
            color: #6f42c1 !important;
        }

        .container-main {
            background: rgba(0, 0, 0, 0.6);
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
            padding: 30px;
            margin-top: 30px;
        }

        .card {
            background-color: rgba(106, 90, 205, 0.5);
            border: none;
            margin-bottom: 20px;
        }

        .card-header {
            background-color: #0072ff;
            color: white;
            border-radius: 10px 10px 0 0 !important;
            padding: 15px 20px;
        }

        .btn-primary {
            background-color: #6f42c1;
            border-color: #6f42c1;
        }

        .btn-primary:hover {
            background-color: #5a3b99;
            border-color: #5a3b99;
        }

        .btn-danger {
            background-color: #e63946;
            border: none;
        }

        .btn-danger:hover {
            background-color: #ff4d4d;
        }

        .btn-success {
            background-color: #28a745;
        }

        .btn-success:hover {
            background-color: #218838;
        }

        .form-control {
            background-color: #f8f9fa;
            border: none;
            border-radius: 6px;
            color: #333;
        }

        .form-control:focus {
            background-color: #ffffff;
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }

        .profile-info {
            display: inline-block;
            margin-left: 15px;
        }

        @media (max-width: 768px) {
            .container-main {
                padding: 15px;
            }
        }
    </style>
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar navbar-expand-lg" style="background-color: rgba(0, 0, 0, 0.7);">
        <div class="container">
            <!-- Logo with link to dashboard -->
            <a class="navbar-brand" href="dashboard.jsp">
                <img src="img/logo.png" alt="CarPool Logo" style="width:70px; height:auto;">
            </a>

            <!-- Navigation links -->
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav mr-auto">
                    <li class="nav-item">
                        <a class="nav-link" href="dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="/CarServlet">Garage</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="Ride.jsp">Ride</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="Book.jsp">Book</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" href="userProfile.jsp">Profile</a>
                    </li>
                </ul>

                <!-- Logout button -->
                <form action="logout" method="post" class="form-inline my-2 my-lg-0">
                    <span class="navbar-text mr-3" style="color: #fff;">
                        Welcome, <strong>${not empty sessionScope.username ? sessionScope.username : 'User'}</strong>
                    </span>
                    <button type="submit" class="btn btn-danger">Logout</button>
                </form>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container container-main">
        <div class="card">
            <div class="card-header">
                <h4>Edit Vehicle</h4>
            </div>
            <div class="card-body">
                <form action="CarServlet?action=update" method="post">
                    <input type="hidden" name="id" value="${car.id}">
                    
                    <div class="form-group">
                        <label>Car Plate</label>
                        <input type="text" name="plateNumber" class="form-control" value="${car.plateNumber}" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Car Color</label>
                        <input type="text" name="color" class="form-control" value="${car.color}" required>
                    </div>
                    
                    <div class="form-group">
                        <label>Car Type</label>
                        <select name="carType" class="form-control" required>
                            <option value="Sedan" ${car.carType eq 'Sedan' ? 'selected' : ''}>Sedan</option>
                            <option value="Hatchback" ${car.carType eq 'Hatchback' ? 'selected' : ''}>Hatchback</option>
                            <option value="SUV" ${car.carType eq 'SUV' ? 'selected' : ''}>SUV</option>
                            <option value="Truck" ${car.carType eq 'Truck' ? 'selected' : ''}>Truck</option>
                        </select>
                    </div>
                    
                    <div class="form-group text-right">
                        <a href="/CarServlet" class="btn btn-secondary">Cancel</a>
                        <button type="submit" class="btn btn-primary">Update Vehicle</button>
                        <a href="CarServlet?action=delete&id=${car.id}" class="btn btn-danger" 
                           onclick="return confirm('Are you sure you want to delete this vehicle?')">Delete</a>
                    </div>
                </form>
            </div>
        </div>
    </div>

    <!-- JavaScript Libraries -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
