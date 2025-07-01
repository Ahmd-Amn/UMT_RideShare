<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Registration Form</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: url('img/hp.jpg') no-repeat center center fixed; 
            background-size: cover;
            color: #fff;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }

        .btn-primary {
            background-color: #6f42c1;
            border-color: #6f42c1;
            transition: background-color 0.3s;
        }

        .btn-primary:hover {
            background-color: #5a3b99;
        }

        .btn-danger {
            background-color: #e63946;
            border: none;
            transition: background-color 0.3s;
        }

        .btn-danger:hover {
            background-color: #ff4d4d;
        }

        .container {
            padding: 50px;
            background: rgba(0, 0, 0, 0.6);
            border-radius: 12px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.3);
            width: 100%;
            max-width: 500px;
        }

        .card-header {
            background-color: #0072ff;
            color: white;
            text-align: center;
            border-radius: 10px 10px 0 0;
            padding: 20px;
        }

        .card-body {
            background-color: rgba(0, 0, 0, 0.5);
            padding: 30px;
            border-radius: 0 0 10px 10px;
        }

        .form-group label {
            font-weight: bold;
        }

        .form-control {
            background-color: #f8f9fa;
            border: none;
            padding: 15px;
            border-radius: 6px;
            box-shadow: inset 0 1px 3px rgba(0,0,0,0.1);
        }

        .form-control:focus {
            background-color: #ffffff;
            border-color: #0072ff;
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }

        .error {
            color: red;
            margin-top: 5px;
            font-size: 0.9rem;
        }

        .btn-block {
            padding: 14px;
        }

        /* Added media query for mobile responsiveness */
        @media (max-width: 576px) {
            .container {
                padding: 20px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="card">
            <div class="card-header">
                <h3>Sign Up</h3>
            </div>
            <div class="card-body">
                <!-- Modified form to work with UserServlet -->
                <form id="registrationForm" action="UserServlet" method="post">
                    <input type="hidden" name="action" value="insert">
                    
                    <div class="form-group">
                        <label for="name">Name:</label>
                        <input type="text" class="form-control" id="name" name="name" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="email">Email:</label>
                        <input type="email" class="form-control" id="email" name="email" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="phone">Phone Number:</label>
                        <input type="tel" class="form-control" id="phone" name="phone" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="username">Username:</label>
                        <input type="text" class="form-control" id="username" name="username" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="password">Password:</label>
                        <input type="password" class="form-control" id="password" name="password" minlength="8" 
                               title="Password must be at least 8 characters long" required>
                    </div>
                    
                    <div class="form-group">
                        <label for="confirmPassword">Confirm Password:</label>
                        <input type="password" class="form-control" id="confirmPassword" name="confirmPassword" required>
                        <div id="error-message" class="error"></div>
                    </div>
                    
                    <button type="submit" class="btn btn-primary btn-block">Register</button>
                    
                </form>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS and dependencies -->
    <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>

    <script>
        document.getElementById('registrationForm').onsubmit = function(event) {
            var password = document.getElementById('password').value;
            var confirmPassword = document.getElementById('confirmPassword').value;
            var errorMessage = document.getElementById('error-message');
            var email = document.getElementById('email').value;
            var emailPattern = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;

            // Clear previous error message
            errorMessage.textContent = "";

            // Validate email format
            if (!emailPattern.test(email)) {
                event.preventDefault();
                errorMessage.textContent = "Invalid email format!";
                return;
            }

            // Validate password length
            if (password.length < 8) {
                event.preventDefault();
                errorMessage.textContent = "Password must be at least 8 characters long!";
                return;
            }

            // Validate password match
            if (password !== confirmPassword) {
                event.preventDefault();
                errorMessage.textContent = "Passwords do not match!";
                return;
            }
        };
        
        // Display success message if redirected from successful registration
        window.onload = function() {
            const urlParams = new URLSearchParams(window.location.search);
            if(urlParams.has('success')) {
                alert('Registration successful!');
            }
        };
    </script>
</body>
</html>
