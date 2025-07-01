<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>UMT RideShare</title>
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

        .card {
            background: rgba(255, 255, 255, 0.9);
            border: none;
            border-radius: 15px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.2);
            overflow: hidden;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .card:hover {
            transform: scale(1.05);
            box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
        }

        .card-title {
            font-weight: bold;
            font-size: 1.75rem;
            color: #1e90ff;
            text-align: center;
        }

        .card-text {
            font-size: 1rem;
            color: #333;
            text-align: left;
            margin-top: 10px;
        }

        .btn-primary {
            background: linear-gradient(90deg, #1e90ff, #00fa9a);
            border: none;
            color: #fff;
            font-weight: bold;
            padding: 10px 20px;
            border-radius: 30px;
            transition: background 0.3s ease;
        }

        .btn-primary:hover {
            background: linear-gradient(90deg, #00fa9a, #1e90ff);
            color: #fff;
        }

        .btn-secondary {
            background: #ddd;
            color: #333;
            border: none;
            border-radius: 30px;
            font-weight: bold;
            padding: 10px 20px;
            transition: background 0.3s ease;
        }

        .btn-secondary:hover {
            background: #ccc;
        }

        .modal-content {
            border-radius: 20px;
        }

        .modal-header {
            background: linear-gradient(90deg, #1e90ff, #00fa9a);
            color: #fff;
            border-bottom: none;
        }

        .modal-footer {
            border-top: none;
        }

        input[type="text"], input[type="password"] {
            border: 1px solid #ddd;
            border-radius: 30px;
            padding: 10px 15px;
        }
    </style>
</head>
<body>
    <div class="container mt-5">
        <img src="img/hp.png" style="width: 100%; height: auto; max-height: 300px;">
        <h3 class="stylish-heading">Welcome to UMT RideShare</h3>
        <div class="row mt-5">
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Features</h5>
                        <p class="card-text">Easily find rides within the UMT community.</p>
                        <p class="card-text">Search for trusted drivers and riders.</p>
                        <p class="card-text">Schedule rides at your convenience.</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Benefits</h5>
                        <p class="card-text">Save money by sharing rides.</p>
                        <p class="card-text">Reduce your carbon footprint.</p>
                        <p class="card-text">Build connections within the UMT community.</p>
                    </div>
                </div>
            </div>
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <form action="login" method="post">
                            <div class="form-group">
                                <input type="text" name="username" class="form-control" placeholder="Username" required>
                            </div>
                            <div class="form-group">
                                <input type="password" name="password" class="form-control" placeholder="Password" required>
                            </div>
                            <button type="submit" class="btn btn-primary btn-block">Log in</button>
                            <a href="register.jsp" class="btn btn-secondary btn-block">Sign up</a>
                            <p class="text-center mt-2">
                                <a href="#" data-toggle="modal" data-target="#adminLoginModal">Login as Admin</a>
                            </p>
                        </form>
                    </div>
                </div>
            </div>
        </div>
        
    </div>

    <!-- Admin Login Modal -->
    <div class="modal fade" id="adminLoginModal" tabindex="-1" role="dialog" aria-labelledby="adminLoginModalLabel" aria-hidden="true">
        <div class="modal-dialog" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="adminLoginModalLabel">Admin Login</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <form action="adminLogin" method="post">
                    <div class="modal-body">
                        <div class="form-group">
                            <label for="adminUsername">Username</label>
                            <input type="text" name="adminUsername" id="adminUsername" class="form-control" placeholder="Admin username" required>
                        </div>
                        <div class="form-group">
                            <label for="adminPassword">Password</label>
                            <input type="password" name="adminPassword" id="adminPassword" class="form-control" placeholder="Admin password" required>
                        </div>
                        
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-dismiss="modal">Close</button>
                        <button type="submit" class="btn btn-primary">Log in</button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    
    
    <!-- Bootstrap JS and dependencies -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>

    <%@ include file="footer.html"%>
</body>
</html>
