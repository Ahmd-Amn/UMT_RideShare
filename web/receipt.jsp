<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Payment Receipt - CarPool</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <style>
        body {
            background-color: #f8f9fa;
            font-family: 'Arial', sans-serif;
        }
        .receipt-container {
            max-width: 600px;
            margin: 30px auto;
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 0 20px rgba(0,0,0,0.1);
        }
        .receipt-header {
            text-align: center;
            margin-bottom: 30px;
        }
        .receipt-header i {
            font-size: 50px;
            color: #28a745;
            margin-bottom: 15px;
        }
        .receipt-details {
            margin-bottom: 30px;
        }
        .receipt-details table {
            width: 100%;
        }
        .receipt-details th {
            width: 40%;
            padding: 8px 0;
            font-weight: normal;
            text-align: left;
            color: #6c757d;
        }
        .receipt-details td {
            padding: 8px 0;
            font-weight: 500;
        }
        .print-button {
            width: 100%;
        }
        @media print {
            body {
                background-color: white;
            }
            .receipt-container {
                box-shadow: none;
                padding: 0;
                margin: 0;
            }
            .no-print {
                display: none !important;
            }
        }
    </style>
</head>
<body>
    <div class="receipt-container">
        <div class="receipt-header">
            <i class="fas fa-check-circle"></i>
            <h2>Payment Successful</h2>
            <p>Thank you for using CarPool!</p>
        </div>
        
        <div class="receipt-details">
            <table>
                <tr>
                    <th>Receipt Number:</th>
                    <td>${receipt.receiptNumber}</td>
                </tr>
                <tr>
                    <th>Transaction ID:</th>
                    <td>${receipt.transactionId}</td>
                </tr>
                <tr>
                    <th>Payment Date:</th>
                    <td><fmt:formatDate value="${receipt.paymentDate}" pattern="dd MMM yyyy HH:mm"/></td>
                </tr>
                <tr>
                    <th>Ride ID:</th>
                    <td>${receipt.rideId}</td>
                </tr>
                <c:if test="${not empty rideDate}">
                <tr>
                    <th>Ride Date:</th>
                    <td><fmt:formatDate value="${rideDate}" pattern="dd MMM yyyy"/></td>
                </tr>
                <tr>
                    <th>Pickup Time:</th>
                    <td><fmt:formatDate value="${pickupTime}" pattern="HH:mm"/></td>
                </tr>
                </c:if>
                <tr>
                    <th>Pickup Location:</th>
                    <td>${pickupAddress}</td>
                </tr>
                <tr>
                    <th>Drop-off Location:</th>
                    <td>${dropoffAddress}</td>
                </tr>
                <tr>
                    <th>Amount Paid:</th>
                    <td>RM <fmt:formatNumber value="${receipt.amount}" type="number" minFractionDigits="2"/></td>
                </tr>
                <tr>
                    <th>Payment Method:</th>
                    <td>${receipt.paymentMethod}</td>
                </tr>
                <tr>
                    <th>Email:</th>
                    <td>${receipt.email}</td>
                </tr>
            </table>
        </div>
        
        <div class="text-center no-print">
            <button onclick="window.print()" class="btn btn-primary print-button">
                <i class="fas fa-print mr-2"></i>Print Receipt
            </button>
            <a href="dashboard.jsp" class="btn btn-link mt-3">Back to Dashboard</a>
        </div>
    </div>
</body>
</html>
