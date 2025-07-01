package Model;

import java.sql.Timestamp;

public class Booking {
    private int id;
    private int userId;
    private int rideId;
    private String paymentId;
    private int status;
    private Timestamp createdAt;

    // Getters and setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
    public int getRideId() { return rideId; }
    public void setRideId(int rideId) { this.rideId = rideId; }
    public String getPaymentId() { return paymentId; }
    public void setPaymentId(String paymentId) { this.paymentId = paymentId; }
    public int getStatus() { return status; }
    public void setStatus(int status) { this.status = status; }
    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }
}
