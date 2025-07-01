<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Dashboard</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">

    <style>
        body {
            background: linear-gradient(135deg, #1e90ff, #00fa9a);
            font-family: 'Roboto', sans-serif;
            color: #fff;
            padding: 20px;
        }

        .stylish-heading {
            font-family: 'Arial Black', sans-serif;
            font-size: 3rem;
            text-align: center;
            color: #fff;
            text-shadow: 2px 2px 10px rgba(0, 0, 0, 0.5);
            margin-top: 20px;
        }

        .navbar {
            background: #004aad;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1);
        }

        .navbar-brand {
            font-weight: bold;
            color: #fff;
            text-transform: uppercase;
        }

        .navbar-brand:hover {
            color: #d4edda;
        }

        .nav-link {
            color: #fff;
            transition: color 0.3s;
        }

        .nav-link:hover {
            color: #d4edda;
        }

        .btn-danger {
            background-color: #e63946;
            border: none;
            transition: background-color 0.3s;
        }

        .btn-danger:hover {
            background-color: #ff4d4d;
        }

        /* Content Section */
        .container {
            flex: 1;
            margin-top: 50px;
            text-align: center;
        }

        h1 {
            font-size: 3rem;
            margin-bottom: 20px;
            font-weight: bold;
            text-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
        }

        p {
            font-size: 1.25rem;
        }


    </style>
</head>
<body>

    <!-- Navigation Bar -->
    <nav class="navbar navbar-expand-lg" style="background-color: rgba(0, 0, 0, 0.7);">
        <div class="container">
            <a class="navbar-brand" href="dashboard.jsp">
                <img src="img/logo.png" alt="CarPool Logo" style="width:70px; height:auto;">
            </a>
            <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
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
                <span class="navbar-text mr-3" style="color: #fff;">
                    Welcome, <strong>${not empty sessionScope.username ? sessionScope.username : 'User'}</strong>
                </span>
                <form action="logout" method="post" class="form-inline">
                    <button type="submit" class="btn btn-danger">Logout</button>
                </form>
            </div>
        </div>
    </nav>

    <!-- Content Section -->
    <div class="container">
        <h1>Welcome to User Dashboard</h1>
        <p>Your trusted carpooling partner for seamless rides.</p>
        <p>Navigate through the dashboard to manage your rides, bookings, and profile.</p>
    </div>
    
    <div class="slide">
        <div id="carouselExampleIndicators" class="carousel slide" data-ride="carousel">
            <!-- Indicators -->
            <ol class="carousel-indicators">
                <li data-target="#carouselExampleIndicators" data-slide-to="0" class="active"></li>
                <li data-target="#carouselExampleIndicators" data-slide-to="1"></li>
                <li data-target="#carouselExampleIndicators" data-slide-to="2"></li>
            </ol>

            <!-- Slides -->
            <div class="carousel-inner">
                <div class="carousel-item active">
                    <img src="img/hp.png" class="d-block w-100" alt="First slide">
                </div>
                <div class="carousel-item">
                    <img src="img/slide 2.png" class="d-block w-100" alt="Second slide">
                </div>
                <div class="carousel-item">
                    <img src="img/slide 3.png" class="d-block w-100" alt="Third slide">
                </div>
            </div>

            <!-- Controls -->
            <a class="carousel-control-prev" href="#carouselExampleIndicators" role="button" data-slide="prev">
                <span class="carousel-control-prev-icon" aria-hidden="true"></span>
                <span class="sr-only">Previous</span>
            </a>
            <a class="carousel-control-next" href="#carouselExampleIndicators" role="button" data-slide="next">
                <span class="carousel-control-next-icon" aria-hidden="true"></span>
                <span class="sr-only">Next</span>
            </a>
        </div>
    </div>

    <!-- Footer -->
    <%@ include file="footer.html"%>
    
    <!-- Bootstrap JS and dependencies -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>

</body>
</html>
