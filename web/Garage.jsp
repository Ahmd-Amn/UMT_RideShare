<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CarPool - Garage</title>
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

        .table {
            color: #fff;
        }

        .table th {
            border-top: none;
        }

        .form-control {
            background-color: #f8f9fa;
            border: none;
            border-radius: 6px;
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

            <!-- Mobile toggle button -->
            <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav" 
                    aria-controls="navbarNav" aria-expanded="false" aria-label="Toggle navigation">
                <span class="navbar-toggler-icon"></span>
            </button>

            <!-- Navigation links -->
            <div class="collapse navbar-collapse" id="navbarNav">
                <ul class="navbar-nav mr-auto">
                    <li class="nav-item">
                        <a class="nav-link ${pageContext.request.requestURI.endsWith('/dashboard.jsp') ? 'active' : ''}" 
                           href="dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link ${pageContext.request.requestURI.endsWith('/Garage.jsp') ? 'active' : ''}" 
                           href="CarServlet">Garage</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link ${pageContext.request.requestURI.endsWith('/Ride.jsp') ? 'active' : ''}" 
                           href="RideServlet">Ride</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link ${pageContext.request.requestURI.endsWith('/Book.jsp') ? 'active' : ''}" 
                           href="BookServlet">Book</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link ${pageContext.request.requestURI.endsWith('/userProfile.jsp') ? 'active' : ''}" 
                           href="UserServlet">Profile</a>
                    </li>
                </ul>

                <!-- Logout button -->
                <form action="logout" method="post" class="form-inline my-2 my-lg-0">
                    <span class="navbar-text mr-3" style="color: #fff;">
                        <strong>${not empty sessionScope.username ? sessionScope.username : 'User'}</strong>
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
                <h4>My Vehicles</h4>
            </div>
            <div class="card-body">
                <div class="row mb-4">
                    <div class="col-md-8">
                        <div class="input-group">
                            <input type="text" class="form-control" placeholder="Search vehicles...">
                            <div class="input-group-append">
                                <button class="btn btn-primary" type="button">Search</button>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-4 text-right">
                        <button class="btn btn-success" data-toggle="modal" data-target="#addVehicleModal">
                            Add Vehicle
                        </button>
                    </div>
                </div>

                <!-- Vehicles Table -->
                <div class="table-responsive">
                    <table class="table table-hover">
                        <thead>
                            <tr>
                                <th>Plate</th>
                                <th>Color</th>
                                <th>Type</th>
                                <th>Status</th>
                                <th>Action</th>
                            </tr>
                        </thead>
                        <tbody>
                            <c:forEach var="car" items="${cars}">
                                <tr>
                                    <td>${car.plateNumber}</td>
                                    <td>${car.color}</td>
                                    <td>${car.carType}</td>
                                    <td><span class="badge badge-success">Active</span></td>
                                    <td>
                                        <a href="CarServlet?action=edit&id=${car.id}" class="btn btn-sm btn-primary">Edit</a>
                                        <a href="CarServlet?action=delete&id=${car.id}" class="btn btn-sm btn-danger">Delete</a>
                                    </td>
                                </tr>
                            </c:forEach>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>

    <!-- Add Vehicle Modal -->
    <div class="modal fade" id="addVehicleModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content" style="background-color: rgba(0, 0, 0, 0.8); color: #fff;">
                <div class="modal-header">
                    <h5 class="modal-title">Add New Vehicle</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close" style="color: #fff;">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form action="CarServlet?action=add" method="post">
                        <div class="form-group">
                            <label>Car Plate</label>
                            <input type="text" name="plateNumber" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label>Car Color</label>
                            <input type="text" name="color" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label>Car Type</label>
                            <select name="carType" class="form-control" required>
                                <option value="">Select Type</option>
                                <option value="Sedan">Sedan</option>
                                <option value="Hatchback">Hatchback</option>
                                <option value="Truck">Truck</option>
                            </select>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-primary">Add Vehicle</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript Libraries -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
