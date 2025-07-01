<%@page import="javax.naming.NamingException"%>
<%@page import="java.sql.SQLException"%>
<%@page import="Model.Ride"%>
<%@page import="java.util.List"%>
<%@page import="DAO.RideDao"%>
<%@page import="javax.sql.DataSource"%>
<%@page import="javax.naming.InitialContext"%>
<%@page import="java.sql.Connection"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CarPool - Create Ride Slot</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.7.1/dist/leaflet.css" />
    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
    <link rel="stylesheet" href="https://unpkg.com/leaflet-geosearch@3.0.0/dist/geosearch.css"/>
    <script src="https://unpkg.com/leaflet-geosearch@3.0.0/dist/geosearch.umd.js"></script>
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

        /* Modal styles */
        .modal-content {
            background-color: rgba(0, 0, 0, 0.8);
            color: white;
            border: 1px solid #6f42c1;
        }
        
        .modal-header {
            border-bottom: 1px solid #6f42c1;
        }
        
        .modal-footer {
            border-top: 1px solid #6f42c1;
        }
        
        .close {
            color: white;
        }

        .map-container {
            position: relative;
            height: 500px;
            width: 100%;
            border-radius: 6px;
            margin-bottom: 15px;
            z-index: 1;
        }

        #pickupMap, #dropoffMap {
            height: 100%;
            width: 100%;
        }

        .search-container {
            position: absolute;
            top: 60px; /* Moved down below map controls */
            left: 50%;
            transform: translateX(-50%);
            z-index: 1000;
            width: 90%;
            max-width: 500px;
        }

        .search-container input {
            width: 100%;
            padding: 10px 15px;
            border-radius: 25px;
            border: 2px solid #6f42c1;
            box-shadow: 0 2px 5px rgba(0,0,0,0.3);
            font-size: 16px;
            background-color: rgba(255,255,255,0.9);
        }

        /* Make maps full width on mobile */
        @media (max-width: 768px) {
            .map-container {
                height: 400px;
            }
            .search-container {
                width: 95%;
                top: 50px;
            }
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
                <h4>Create Slot for Carpool</h4>
            </div>
            <div class="card-body">
                <form id="rideForm" action="RideServlet" method="post">
                    <input type="hidden" name="userId" value="${sessionScope.userId}">
                    <input type="hidden" name="action" value="create">
                    
                    <!-- Date and Time Selection -->
                    <div class="row mb-4">
                        <div class="col-md-4">
                            <div class="form-group">
                                <label>Date</label>
                                <input type="date" name="date" class="form-control" required 
                                       min="<%= new java.sql.Date(System.currentTimeMillis()) %>">
                            </div>
                        </div>
                        <div class="col-md-4">
                            <div class="form-group">
                                <label>Pickup Time</label>
                                <input type="time" name="pickup_time" class="form-control" required>
                            </div>
                        </div>
                        <div class="col-md-4 d-flex align-items-end">
                            <button type="button" class="btn btn-success btn-block" data-toggle="modal" data-target="#rideDetailsModal">
                                Add Trip
                            </button>
                        </div>
                    </div>
                    
                    <!-- Location Selection -->
                    <div class="row">
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Pickup Location</label>
                                <div class="map-container">
                                    <div id="pickupMap"></div>
                                    <div class="search-container">
                                        <input type="text" id="pickupSearch" placeholder="Search pickup location">
                                    </div>
                                </div>
                                <input type="hidden" id="pickup_latitude" name="pickup_latitude" required>
                                <input type="hidden" id="pickup_longitude" name="pickup_longitude" required>
                                <input type="text" id="pickup_address" name="pickup_address" class="form-control mt-2" placeholder="Pickup address" readonly required>
                            </div>
                        </div>
                        
                        <div class="col-md-6">
                            <div class="form-group">
                                <label>Drop-off Location</label>
                                <div class="map-container">
                                    <div id="dropoffMap"></div>
                                    <div class="search-container">
                                        <input type="text" id="dropoffSearch" placeholder="Search drop-off location">
                                    </div>
                                </div>
                                <input type="hidden" id="dropoff_latitude" name="dropoff_latitude" required>
                                <input type="hidden" id="dropoff_longitude" name="dropoff_longitude" required>
                                <input type="text" id="dropoff_address" name="dropoff_address" class="form-control mt-2" placeholder="Drop-off address" readonly required>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Hidden fields for car and seats -->
                    <input type="hidden" id="car_id" name="car_id" required>
                    <input type="hidden" id="available_seats" name="available_seats" required>
                </form>

                <!-- Current Trips Table -->
                <div class="mt-4">
                    <h5>Your Active Ride Slots</h5>
                    <div class="table-responsive">
                        <table class="table table-hover">
                            <thead>
                                <tr>
                                    <th>Ref. ID</th>
                                    <th>Date</th>
                                    <th>Time</th>
                                    <th>Car Info</th>
                                    <th>Drop-off Address</th>
                                    <th>Available Seats</th>
                                    <th>Price</th>
                                    <th>Status</th>
                                    <th>Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach items="${rides}" var="ride">
                                <tr>
                                    <td>${ride.id}</td>
                                    <td>${ride.date}</td>
                                    <td>${ride.pickupTime}</td>
                                    <td>${ride.carPlateNumber} - ${ride.carType} (${ride.carColor})</td>
                                    <td>${ride.dropoffAddress}</td>
                                    <td>${ride.availableSeats}</td>
                                    <td><fmt:formatNumber value="${ride.price}" type="currency" currencySymbol="RM"/></td>
                                    <td>
                                        <span class="badge ${ride.status == 1 ? 'badge-success' : 
                                                          (ride.status == 0 ? 'badge-warning' : 'badge-danger')}">
                                            ${ride.status == 1 ? 'Available' : 
                                             (ride.status == 0 ? 'Booked' : 'Cancelled')}
                                        </span>
                                    </td>
                                    <td>
                                        <c:if test="${ride.status == 1}">
                                        <button class="btn btn-sm btn-danger cancel-btn" data-ride-id="${ride.id}">Cancel</button>
                                        </c:if>
                                    </td>
                                </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <!-- Ride Details Modal -->
    <div class="modal fade" id="rideDetailsModal" tabindex="-1" role="dialog" aria-labelledby="rideDetailsModalLabel" aria-hidden="true">
        <div class="modal-dialog modal-lg" role="document">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title" id="rideDetailsModalLabel">Add Trip Details</h5>
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span>
                    </button>
                </div>
                <div class="modal-body">
                    <div class="form-group">
                        <label>Select Your Car</label>
                        <select class="form-control" id="modal_car" required>
                            <option value="">Select Car</option>
                            <c:forEach items="${cars}" var="car">
                                <option value="${car.id}">
                                    ${car.plateNumber} - ${car.carType} (${car.color})
                                </option>
                            </c:forEach>
                        </select>
                    </div>

                    <div class="form-group">
                        <label>Available Seats</label>
                        <input type="number" class="form-control" id="modal_available_seats" min="1" max="10" value="4" required>
                    </div>

                    <div class="form-group">
                        <label>Price per Seat (RM)</label>
                        <input type="number" class="form-control" id="modal_price" min="1" step="0.01" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-dismiss="modal">Cancel</button>
                    <button type="button" class="btn btn-primary" id="submitRide">Create Ride</button>
                </div>
            </div>
        </div>
    </div>

    <!-- JavaScript Libraries -->
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/@popperjs/core@2.9.2/dist/umd/popper.min.js"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
    <script src="https://unpkg.com/leaflet@1.7.1/dist/leaflet.js"></script>
    <script src="https://unpkg.com/leaflet-geosearch@3.0.0/dist/geosearch.umd.js"></script>
    
    
    <script>
        $(document).ready(function() {
            // Initialize pickup map with proper sizing
            var pickupMap = L.map('pickupMap', {
                center: [3.1390, 101.6869],
                zoom: 13,
                zoomControl: true
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(pickupMap);

            var pickupMarker;
            var pickupSearchProvider = new GeoSearch.OpenStreetMapProvider();

            // Initialize dropoff map with proper sizing
            var dropoffMap = L.map('dropoffMap', {
                center: [3.1390, 101.6869],
                zoom: 13,
                zoomControl: true
            });

            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            }).addTo(dropoffMap);

            var dropoffMarker;
            var dropoffSearchProvider = new GeoSearch.OpenStreetMapProvider();

            // Function to handle search functionality
            function setupSearch(map, searchInput, markerVar, latField, lngField, addressField) {
                $(searchInput).on('keypress', function(e) {
                    if (e.which === 13) {
                        var provider = map === pickupMap ? pickupSearchProvider : dropoffSearchProvider;
                        provider.search({ query: $(this).val() }).then(function(result) {
                            if (result.length > 0) {
                                map.setView([result[0].y, result[0].x], 15);
                                if (window[markerVar]) {
                                    map.removeLayer(window[markerVar]);
                                }
                                window[markerVar] = L.marker([result[0].y, result[0].x]).addTo(map)
                                    .bindPopup("Location").openPopup();
                                $(latField).val(result[0].y);
                                $(lngField).val(result[0].x);
                                $(addressField).val(result[0].label);
                            }
                        });
                    }
                });
            }

            // Function to handle map clicks
            function setupMapClick(map, markerVar, latField, lngField, addressField) {
                map.on('click', function(e) {
                    if (window[markerVar]) {
                        map.removeLayer(window[markerVar]);
                    }
                    window[markerVar] = L.marker([e.latlng.lat, e.latlng.lng]).addTo(map)
                        .bindPopup("Selected Location").openPopup();
                    $(latField).val(e.latlng.lat);
                    $(lngField).val(e.latlng.lng);

                    // Reverse geocode to get address
                    var provider = map === pickupMap ? pickupSearchProvider : dropoffSearchProvider;
                    provider.search({ query: e.latlng.lat + ',' + e.latlng.lng })
                        .then(function(result) {
                            if (result.length > 0) {
                                $(addressField).val(result[0].label);
                            }
                        });
                });
            }

            // Set up search for both maps
            setupSearch(pickupMap, '#pickupSearch', 'pickupMarker', '#pickup_latitude', '#pickup_longitude', '#pickup_address');
            setupSearch(dropoffMap, '#dropoffSearch', 'dropoffMarker', '#dropoff_latitude', '#dropoff_longitude', '#dropoff_address');

            // Set up click handlers for both maps
            setupMapClick(pickupMap, 'pickupMarker', '#pickup_latitude', '#pickup_longitude', '#pickup_address');
            setupMapClick(dropoffMap, 'dropoffMarker', '#dropoff_latitude', '#dropoff_longitude', '#dropoff_address');

            // Function to initialize and resize maps
            function initializeMaps() {
                pickupMap.invalidateSize();
                dropoffMap.invalidateSize();

                // Set initial view if no location selected
                if (!$('#pickup_latitude').val()) {
                    pickupMap.setView([3.1390, 101.6869], 13);
                }
                if (!$('#dropoff_latitude').val()) {
                    dropoffMap.setView([3.1390, 101.6869], 13);
                }
            }

            // Initialize maps after slight delay
            setTimeout(initializeMaps, 100);

            // Handle window resize
            $(window).on('resize', function() {
                initializeMaps();
            });

            // Handle ride submission
            $('#submitRide').click(function() {
                if (!$('#modal_car').val()) {
                    alert('Please select a car');
                    return;
                }

                if (!$('#pickup_latitude').val() || !$('#dropoff_latitude').val()) {
                    alert('Please select both pickup and drop-off locations');
                    return;
                }

                if (!$('#modal_available_seats').val() || $('#modal_available_seats').val() < 1) {
                    alert('Please enter a valid number of available seats (minimum 1)');
                    return;
                }
                
                if (!$('#modal_price').val() || $('#modal_price').val() <= 0) {
                    alert('Please enter a valid price (minimum RM1)');
                    return;
                }

                $('#car_id').val($('#modal_car').val());
                $('#available_seats').val($('#modal_available_seats').val());
                $('#rideForm').append('<input type="hidden" name="price" value="' + $('#modal_price').val() + '">');
                $('#rideForm').submit();
                $('#rideDetailsModal').modal('hide');
            });

            // Handle cancel ride buttons
            $('.cancel-btn').click(function() {
                if (confirm('Are you sure you want to cancel this ride?')) {
                    var rideId = $(this).data('ride-id');
                    $.post('RideServlet', { 
                        action: 'cancel', 
                        rideId: rideId 
                    }, function(response) {
                        if (response.success) {
                            location.reload();
                        } else {
                            alert('Failed to cancel ride: ' + response.message);
                        }
                    }).fail(function() {
                        alert('Error communicating with server');
                    });
                }
            });
        });
    </script>
</body>
</html>
