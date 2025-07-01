<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CarPool - Booking Slot</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
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

        .navbar-brand img {
            width: 70px;
            height: auto;
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

        .btn-primary {
            background-color: #6f42c1;
            border-color: #6f42c1;
        }

        .btn-primary:hover {
            background-color: #5a3b99;
            border-color: #5a3b99;
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
        }

        .form-control:focus {
            background-color: #ffffff;
            box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
        }

        .table {
            color: black;
        }

        .table th {
            border-top: none;
        }

        .badge-available {
            background-color: #28a745;
        }

        .badge-booked {
            background-color: #dc3545;
        }

        /* Additional fixes */
        .book-btn {
            white-space: nowrap;
            min-width: 100px;
        }

        .table td, .table th {
            vertical-align: middle;
            padding: 12px 15px;
        }

        .loading-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.7);
            z-index: 9999;
            display: flex;
            justify-content: center;
            align-items: center;
            color: white;
            font-size: 1.5rem;
        }

        #card-element {
            padding: 10px;
            border: 1px solid #ced4da;
            border-radius: 4px;
            background: white;
        }

        #card-errors {
            color: #dc3545;
            margin-top: 5px;
        }
        .modal-content {
            color: black; /* Set default text color to black */
        }

        .booking-summary {
            color: black; /* Ensure summary text is black */
        }

        .modal-body label {
            color: black; /* Make all labels black */
        }

        /* Update Stripe element styling */
        #card-element {
            color: black; /* Text color for card input */
        }

        /* Make sure placeholder text is visible */
        .StripeElement--empty {
            color: #6c757d !important;
        }
        /* Add to your style section */
        #payment-methods .btn {
            flex: 1;
            text-align: center;
        }

        #payment-methods .btn.active {
            background-color: #6f42c1;
            color: white;
        }

        #payment-methods .btn:hover {
            background-color: #5a3b99;
            color: white;
        }

        #payment-methods input[type="radio"] {
            position: absolute;
            clip: rect(0,0,0,0);
            pointer-events: none;
        }
    </style>
</head>
<body>
    <!-- Navigation Bar -->
    <nav class="navbar navbar-expand-lg">
        <div class="container">
            <a class="navbar-brand" href="dashboard.jsp">
                <img src="img/logo.png" alt="CarPool Logo">
            </a>
            <button class="navbar-toggler" type="button" data-toggle="collapse" data-target="#navbarNav">
                <span class="navbar-toggler-icon"></span>
            </button>
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
                <span class="navbar-text mr-3">
                    <strong>${not empty sessionScope.username ? sessionScope.username : 'User'}</strong>
                </span>
                <form action="logout" method="post" class="form-inline">
                    <button type="submit" class="btn btn-danger">Logout</button>
                </form>
            </div>
        </div>
    </nav>

    <!-- Main Content -->
    <div class="container container-main">
        <div class="card">
            <div class="card-header">
                <h4>Booking Slot</h4>
            </div>
            <div class="card-body">
                <!-- Search Form -->
                <form action="BookServlet" method="get">
                    <div class="form-row">
                        <div class="col-md-3 mb-3">
                            <label>Pickup Location</label>
                            <input type="text" class="form-control" name="pickupLocation" placeholder="Enter pickup location" value="${param.pickupLocation}">
                        </div>
                        <div class="col-md-3 mb-3">
                            <label>Drop-off Location</label>
                            <input type="text" class="form-control" name="dropoffLocation" placeholder="Enter drop-off location" value="${param.dropoffLocation}">
                        </div>
                        <div class="col-md-3 mb-3">
                            <label>Date</label>
                            <input type="date" class="form-control" name="searchDate" value="${param.searchDate}">
                        </div>
                        <div class="col-md-3 mb-3 d-flex align-items-end">
                            <button type="submit" class="btn btn-primary btn-block">Search</button>
                        </div>
                    </div>
                </form>

                <!-- Available Slots -->
                <div class="mt-4">
                    <h5>Available Slots</h5>
                    <c:choose>
                        <c:when test="${not empty rides}">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th>#Ref. ID</th>
                                            <th>Date</th>
                                            <th>Pickup Time</th>
                                            <th>Car Details</th>
                                            <th>Available Seats</th>
                                            <th>Pickup Location</th>
                                            <th>Drop-off Location</th>
                                            <th>Price</th>
                                            <th>Status</th>
                                            <th>Action</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        <c:forEach items="${rides}" var="ride">
                                            <tr>
                                                <td>${ride.id}</td>
                                                <td><fmt:formatDate value="${ride.date}" pattern="yyyy-MM-dd"/></td>
                                                <td>${ride.pickupTime}</td>
                                                <td>${ride.carPlateNumber} - ${ride.carType} (${ride.carColor})</td>
                                                <td>${ride.availableSeats}</td>
                                                <td>${ride.pickupAddress}</td>
                                                <td>${ride.dropoffAddress}</td>
                                                <td><fmt:formatNumber value="${ride.price}" type="currency" currencySymbol="RM"/></td>
                                                <td>
                                                    <span class="badge ${ride.status == 1 ? 'badge-available' : 'badge-booked'}">
                                                        ${ride.status == 1 ? 'Available' : 'Booked'}
                                                    </span>
                                                </td>
                                                <td>
                                                    <button class="btn btn-success btn-sm book-btn" 
                                                            data-ride-id="${ride.id}" 
                                                            data-amount="${ride.price}"
                                                            ${ride.status != 1 ? 'disabled' : ''}>
                                                        ${ride.status == 1 ? 'Book Now' : 'Booked'}
                                                    </button>
                                                </td>
                                            </tr>
                                        </c:forEach>
                                    </tbody>
                                </table>
                            </div>
                        </c:when>
                        <c:otherwise>
                            <div class="alert alert-info">
                                No available rides found. Please adjust your search criteria.
                            </div>
                        </c:otherwise>
                    </c:choose>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Loading overlay (hidden by default) -->
    <div class="loading-overlay" style="display: none;">
        <div class="text-center">
            <div class="spinner-border" style="width: 3rem; height: 3rem;"></div>
            <p class="mt-2">Processing your request...</p>
        </div>
    </div>

    <!-- Enhanced Payment Modal -->
    <div class="modal fade" id="paymentModal" tabindex="-1" role="dialog" aria-labelledby="paymentModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-dialog-centered" role="document">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title" id="paymentModalLabel">Complete Your Booking</h5>
                    <button type="button" class="close text-white" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <div class="booking-summary mb-4 p-3 bg-light rounded">
                        <h6><i class="fas fa-info-circle mr-2"></i>Booking Summary</h6>
                        <div class="d-flex justify-content-between">
                            <span>Ride ID:</span>
                            <strong id="summary-ride-id"></strong>
                        </div>
                        <div class="d-flex justify-content-between">
                            <span>Amount:</span>
                            <strong id="summary-amount"></strong>
                        </div>
                    </div>

                    <form id="payment-form">
                        <div class="form-group">
                            <label>Payment Method</label>
                            <div class="btn-group btn-group-toggle w-100" data-toggle="buttons" id="payment-methods">
                                <label class="btn btn-outline-primary active">
                                    <input type="radio" name="paymentMethod" value="grabpay" checked> GrabPay
                                </label>
                                <label class="btn btn-outline-primary">
                                    <input type="radio" name="paymentMethod" value="tng"> Touch 'n Go
                                </label>
                                <label class="btn btn-outline-primary">
                                    <input type="radio" name="paymentMethod" value="maybank"> Maybank2U
                                </label>
                            </div>
                        </div>

                        <div class="form-group">
                            <label for="email"><i class="fas fa-envelope mr-1"></i>Email for Receipt</label>
                            <input type="email" id="email" class="form-control" required>
                        </div>
                        <input type="hidden" id="ride-id">
                        <input type="hidden" id="amount">

                        <button type="submit" class="btn btn-success btn-block mt-3" id="submit-button">
                            <span id="button-text">Pay Now</span>
                            <span id="payment-processing" class="spinner-border spinner-border-sm ml-2 d-none"></span>
                        </button>

                        <div class="text-center mt-2">
                            <img src="https://cdn.worldvectorlogo.com/logos/stripe-4.svg" alt="Stripe" style="height: 30px;">
                            <p class="small text-muted mt-1">Secure payment processing</p>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript Libraries -->
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
    <script src="https://js.stripe.com/v3/"></script>
    
    <script>
        // Document ready function
        $(document).ready(function() {
            // Initialize Stripe
            const stripe = Stripe('pk_test_51ReoHoRscsSRGtE0cSAhvWzWn9vBJRp7G3Pq8mzZbM7YQXG2LcEKSbSlVA2pvkiUQ6HcaMM84lnzDWuW7IqmrWCm00xnQEbqUn');
            let elements;
            let card;

            // Initialize payment form when modal is shown
            $('#paymentModal').on('shown.bs.modal', function() {
                if (!elements) {
                    elements = stripe.elements();
                    card = elements.create('card', {
                        style: {
                            base: {
                                color: '#495057',
                                fontFamily: '"Segoe UI", Roboto, sans-serif',
                                fontSize: '16px',
                                '::placeholder': {
                                    color: '#6c757d'
                                }
                            },
                            invalid: {
                                color: '#dc3545',
                                iconColor: '#dc3545'
                            }
                        }
                    });
                    card.mount('#card-element');
                }

                // Handle real-time validation errors
                card.addEventListener('change', function(event) {
                    const displayError = document.getElementById('card-errors');
                    if (event.error) {
                        displayError.textContent = event.error.message;
                    } else {
                        displayError.textContent = '';
                    }
                });
            });

            // Clean up when modal is hidden
            $('#paymentModal').on('hidden.bs.modal', function() {
                if (card) {
                    card.unmount();
                    elements = null;
                    card = null;
                }
                $('#payment-form')[0].reset();
                $('#card-errors').text('');
            });

            // Show loading overlay during AJAX requests
            $(document).ajaxStart(function(){
                $('.loading-overlay').show();
            }).ajaxStop(function(){
                $('.loading-overlay').hide();
            });

            // Handle book button clicks
            $(document).on('click', '.book-btn:not(:disabled)', function() {
                const rideId = $(this).data('ride-id');
                const amount = parseFloat($(this).data('amount')).toFixed(2);

                // Update modal with booking details
                $('#ride-id').val(rideId);
                $('#amount').val(amount);
                $('#summary-ride-id').text('RIDE-' + rideId);
                $('#summary-amount').text('RM' + amount);

                // Reset form state
                $('#payment-form')[0].reset();
                $('#card-errors').text('');
                $('#submit-button').prop('disabled', false);
                $('#button-text').text('Pay Now');
                $('#payment-processing').addClass('d-none');

                // Show modal
                $('#paymentModal').modal('show');
            });

            // Handle form submission
            $('#payment-form').on('submit', function(e) {
                e.preventDefault();

                const email = $('#email').val().trim();
                const rideId = $('#ride-id').val();
                const amount = $('#amount').val();
                const paymentMethod = $('input[name="paymentMethod"]:checked').val();

                // Validate email
                if (!email) {
                    alert('Please enter a valid email address');
                    return;
                }

                // Disable form and show processing
                $('#submit-button').prop('disabled', true);
                $('#button-text').text('Processing Payment');
                $('#payment-processing').removeClass('d-none');

                // Create payment intent
                $.ajax({
                    url: 'PaymentServlet',
                    type: 'POST',
                    data: {
                        rideId: rideId,
                        amount: amount,
                        email: email,
                        paymentMethod: paymentMethod
                    },
                    success: function(data) {
                        if (data.error) {
                            showError(data.error);
                            return;
                        }

                        if (data.redirectUrl) {
                            // For e-wallet payments, redirect to receipt page
                            window.location.href = data.redirectUrl;
                        } else if (data.clientSecret) {
                            // For card payments, confirm with Stripe then redirect
                            stripe.confirmCardPayment(data.clientSecret, {
                                payment_method: {
                                    card: card,
                                    billing_details: {
                                        email: email
                                    }
                                }
                            }).then(function(result) {
                                if (result.error) {
                                    showError(result.error.message);
                                } else {
                                    // On success, redirect to receipt page
                                    window.location.href = 'receipt.jsp?rideId=' + rideId;
                                }
                            });
                        }
                    },
                    error: function(xhr) {
                        showError(xhr.responseJSON?.error || 'Payment failed');
                    }
                });
            });

            function showError(message) {
                $('#submit-button').prop('disabled', false);
                $('#button-text').text('Pay Now');
                $('#payment-processing').addClass('d-none');
                $('#card-errors').text(message);
            }
        });
    </script>
</body>
</html>
