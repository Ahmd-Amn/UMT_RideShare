<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CarPool - User Profile</title>
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
            background-color: white;
            border: none;
            margin-bottom: 20px;
            color: black;
        }

        .card-header {
            background-color: #0072ff;
            color: white;
            border-radius: 10px 10px 0 0 !important;
            padding: 15px 20px;
        }

        .card-body {
            color: black; 
        }

        .form-control-plaintext.text-white {
            color: black !important; /* Override white text for form fields */
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
                    <li class="nav-item ${pageContext.request.requestURI.endsWith('/dashboard.jsp') ? 'active' : ''}">
                        <a class="nav-link" href="dashboard.jsp">Dashboard</a>
                    </li>
                    <li class="nav-item ${pageContext.request.requestURI.endsWith('/Garage.jsp') ? 'active' : ''}">
                        <a class="nav-link" href="CarServlet">Garage</a>
                    </li>
                    <li class="nav-item ${pageContext.request.requestURI.endsWith('/Ride.jsp') ? 'active' : ''}">
                        <a class="nav-link" href="RideServlet">Ride</a>
                    </li>
                    <li class="nav-item ${pageContext.request.requestURI.endsWith('/Book.jsp') ? 'active' : ''}">
                        <a class="nav-link" href="BookServlet">Book</a>
                    </li>
                    <li class="nav-item ${pageContext.request.requestURI.endsWith('/userProfile.jsp') ? 'active' : ''}">
                        <a class="nav-link" href="UserServlet">Profile</a>
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
        <div class="row">
        <div class="col-md-12"> 
            <div class="card">
                <div class="card-header">
                    <h4>Personal Information</h4>
                </div>
                <div class="card-body">
                    <c:if test="${not empty successMessage}">
                        <div class="alert alert-success">${successMessage}</div>
                    </c:if>
                    <c:if test="${not empty errorMessage}">
                        <div class="alert alert-danger">${errorMessage}</div>
                    </c:if>

                    <!-- View Mode (default) -->
                    <div id="viewMode">
                       
                        <div class="form-group row">
                            <label class="col-sm-3 col-form-label">Username</label>
                            <div class="col-sm-9">
                                <p class="form-control-plaintext text-white">${user.username}</p>
                            </div>
                        </div>
                        <div class="form-group row">
                            <label class="col-sm-3 col-form-label">Full Name</label>
                            <div class="col-sm-9">
                                <p class="form-control-plaintext text-white">${user.name}</p>
                            </div>
                        </div>
                        <div class="form-group row">
                            <label class="col-sm-3 col-form-label">Email</label>
                            <div class="col-sm-9">
                                <p class="form-control-plaintext text-white">${user.email}</p>
                            </div>
                        </div>
                        <div class="form-group row">
                            <label class="col-sm-3 col-form-label">Phone</label>
                            <div class="col-sm-9">
                                <p class="form-control-plaintext text-white">${user.phone}</p>
                            </div>
                        </div>
                        <div class="form-group row">
                            <div class="col-sm-9 offset-sm-3">
                                <button id="editBtn" class="btn btn-primary">Update Profile</button>
                                <button type="button" class="btn btn-secondary ml-2" data-toggle="modal" data-target="#changePasswordModal">
                                    Change Password
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Edit Mode (hidden by default) -->
                    <div id="editMode" style="display: none;">
                        <form action="UserServlet?action=update" method="post">
                            <div class="form-group row">
                                <label class="col-sm-3 col-form-label">Username</label>
                                <div class="col-sm-9">
                                    <input type="text" class="form-control" name="username" value="${user.username}">
                                </div>
                            </div>
                            <div class="form-group row">
                                <label class="col-sm-3 col-form-label">Full Name</label>
                                <div class="col-sm-9">
                                    <input type="text" class="form-control" name="name" value="${user.name}">
                                </div>
                            </div>
                            <div class="form-group row">
                                <label class="col-sm-3 col-form-label">Email</label>
                                <div class="col-sm-9">
                                    <input type="email" class="form-control" name="email" value="${user.email}">
                                </div>
                            </div>
                            <div class="form-group row">
                                <label class="col-sm-3 col-form-label">Phone</label>
                                <div class="col-sm-9">
                                    <input type="tel" class="form-control" name="phone" value="${user.phone}">
                                </div>
                            </div>
                            <div class="form-group row">
                                <div class="col-sm-9 offset-sm-3">
                                    <button type="submit" class="btn btn-success">Save Changes</button>
                                    <button type="button" id="cancelBtn" class="btn btn-secondary ml-2">Cancel</button>
                                </div>
                            </div>
                        </form>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Change Password Modal -->
    <div class="modal fade" id="changePasswordModal" tabindex="-1" role="dialog" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content" style="background-color: rgba(0, 0, 0, 0.8); color: #fff;">
                <div class="modal-header">
                    <h5 class="modal-title">Change Password</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close" style="color: #fff;">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <form action="UserServlet?action=changePassword" method="post">
                        <div class="form-group">
                            <label>Current Password</label>
                            <input type="password" name="currentPassword" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label>New Password</label>
                            <input type="password" name="newPassword" class="form-control" required>
                        </div>
                        <div class="form-group">
                            <label>Confirm New Password</label>
                            <input type="password" name="confirmPassword" class="form-control" required>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-primary">Change Password</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- JavaScript to toggle between view and edit modes -->
<script>
    document.getElementById('editBtn').addEventListener('click', function() {
        document.getElementById('viewMode').style.display = 'none';
        document.getElementById('editMode').style.display = 'block';
    });

    document.getElementById('cancelBtn').addEventListener('click', function() {
        document.getElementById('editMode').style.display = 'none';
        document.getElementById('viewMode').style.display = 'block';
    });
</script>
    <!-- JavaScript Libraries -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>
