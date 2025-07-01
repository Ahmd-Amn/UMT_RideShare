<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Booking Confirmation</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <style>
        body {
            font-family: 'Arial', sans-serif;
            background: url('img/hp.jpg') no-repeat center center fixed; 
            background-size: cover;
            color: #fff;
            min-height: 100vh;
        }
        .confirmation-container {
            background: rgba(0, 0, 0, 0.7);
            border-radius: 10px;
            padding: 30px;
            margin-top: 100px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-6 confirmation-container text-center">
                <h2><i class="fas fa-check-circle text-success"></i> Booking Confirmed!</h2>
                <p class="mt-4">Your payment was successful and your ride has been booked.</p>
                <p>Ride ID: ${param.rideId}</p>
                <p>Payment Reference: ${param.paymentId}</p>
                <div class="mt-4">
                    <a href="BookServlet" class="btn btn-primary mr-2">Back to Bookings</a>
                    <a href="dashboard.jsp" class="btn btn-secondary">Go to Dashboard</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
