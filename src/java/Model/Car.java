package Model;

public class Car {
    private int id;
    private String plateNumber;
    private String color;
    private String carType;
    private int userId;
    
    // Constructors
    public Car() {}
    
    public Car(String plateNumber, String color, String carType, int userId) {
        this.plateNumber = plateNumber;
        this.color = color;
        this.carType = carType;
        this.userId = userId;
    }
    
    // Getters and Setters
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    
    public String getPlateNumber() { return plateNumber; }
    public void setPlateNumber(String plateNumber) { this.plateNumber = plateNumber; }
    
    public String getColor() { return color; }
    public void setColor(String color) { this.color = color; }
    
    public String getCarType() { return carType; }
    public void setCarType(String carType) { this.carType = carType; }
    
    public int getUserId() { return userId; }
    public void setUserId(int userId) { this.userId = userId; }
}

