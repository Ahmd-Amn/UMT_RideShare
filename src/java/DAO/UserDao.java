package DAO;

import Model.User;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public class UserDao {
    
    private Connection con;
    
    public UserDao(Connection con){
        this.con = con;
    }

    public boolean addUser (User user) {
        boolean success = false;
        try {
            String query = "INSERT INTO users (name, email, phone, username, password) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement ps = con.prepareStatement(query);
                ps.setString(1, user.getName());
                ps.setString(2, user.getEmail());
                ps.setString(3, user.getPhone());
                ps.setString(4, user.getUsername());
                ps.setString(5, user.getPassword());

                int i = ps.executeUpdate();
                if(i == 1){
                    success = true;
                }
            
        } catch (SQLException e) {
            e.printStackTrace(); // Log the exception for debugging
        }

        return success;
    }
    public List<User> getAllUsers(){
        List<User> users = new ArrayList<>();
        try{
            String query = "SELECT * FROM users";
            Statement st = con.createStatement();
            ResultSet rs = st.executeQuery(query);
            
            while(rs.next()){
                User user = new User();
                user.setId(rs.getInt("id"));
                user.setName(rs.getString("name"));
                user.setEmail(rs.getString("email"));
                user.setPhone(rs.getString("phone"));
                user.setUsername(rs.getString("username"));
                user.setPassword(rs.getString("password"));
                users.add(user);
            }
        } catch (Exception e){
            e.printStackTrace();
        }
        return users;
    }
    
    public boolean updateUser(User user){
        boolean success = false;
        try{
            String query;
            if (user.getPassword() == null || user.getPassword().isEmpty()) {
                query = "UPDATE users SET name=?, email=?, phone=? WHERE id=?";
            } else {
                query = "UPDATE users SET name=?, email=?, phone=?, password=? WHERE id=?";
            }

            PreparedStatement ps = con.prepareStatement(query);
            ps.setString(1, user.getName());
            ps.setString(2, user.getEmail());
            ps.setString(3, user.getPhone());

            if (user.getPassword() == null || user.getPassword().isEmpty()) {
                ps.setInt(4, user.getId());
            } else {
                ps.setString(4, user.getPassword());
                ps.setInt(5, user.getId());
            }

            int i = ps.executeUpdate();
            success = i == 1;
        } catch(Exception e){
            e.printStackTrace();
        }
        return success;
    }
    
    public boolean updateUserPassword(User user) throws SQLException {
        String sql = "UPDATE users SET password = ? WHERE id = ?";
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, user.getPassword()); // Should be hashed in production
            ps.setInt(2, user.getId());
            return ps.executeUpdate() > 0;
        }
    }

    public User getUserById(int userId) throws SQLException {
        User user = null;
        String sql = "SELECT id, name, email, phone, username, password FROM users WHERE id = ?";
        
        try (PreparedStatement statement = con.prepareStatement(sql)) {
            statement.setInt(1, userId);
            ResultSet resultSet = statement.executeQuery();
            
            if (resultSet.next()) {
                user = new User();
                user.setId(resultSet.getInt("id"));
                user.setName(resultSet.getString("name"));
                user.setEmail(resultSet.getString("email"));
                user.setPhone(resultSet.getString("phone"));
                user.setUsername(resultSet.getString("username"));
                user.setPassword(resultSet.getString("password")); // Note: In real app, you wouldn't expose this
            }
        }
        
        return user;
    }
    
    public boolean deleteUser(String username) {
        boolean success = false;
        try {
            String query = "DELETE FROM users WHERE username=?";
            PreparedStatement ps = con.prepareStatement(query);
            ps.setString(1, username);
        
            int i = ps.executeUpdate();
            if (i == 1) {
                success = true;
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return success;
    }
}
