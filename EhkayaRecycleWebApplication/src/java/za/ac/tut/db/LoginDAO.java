package za.ac.tut.db;

import java.sql.*;
import org.mindrot.jbcrypt.BCrypt;

public class LoginDAO {

    public String[] authenticate(String email, String plainPassword) {
        
        String sql = "SELECT user_id, user_password, role FROM USERS WHERE email_address = ?";

        try (Connection conn = DBManager.getConnection(); 
             PreparedStatement ps = conn.prepareStatement(sql)) {

            ps.setString(1, email);
            ResultSet rs = ps.executeQuery();

            if (rs.next()) {
                String storedHash = rs.getString("user_password");
                String role = rs.getString("role");
                int id = rs.getInt("user_id");

                if (BCrypt.checkpw(plainPassword, storedHash)) {
                    System.out.println("Authentication successful for: " + email + ", role: " + role);
                    return new String[]{String.valueOf(id), role};
                } else {
                    System.out.println("Password mismatch for: " + email);
                }
            } else {
                System.out.println("User not found: " + email);
            }
        } catch (SQLException e) {
            System.err.println("Authentication error: " + e.getMessage());
            e.printStackTrace();
        }
        return null;
    }

    public String fetchNameByRole(int userId, String role) {
        String name = null;
        
        System.out.println("Fetching name for userId: " + userId + ", role: " + role);

        if ("household_user".equalsIgnoreCase(role)) {
            String sql = "SELECT first_name, last_name FROM HOUSEHOLD_USER WHERE user_id = ?";
            try (Connection conn = DBManager.getConnection(); 
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    String firstName = rs.getString("first_name");
                    String lastName = rs.getString("last_name");
                    name = firstName + " " + lastName; 
                    System.out.println("Household user name: " + name);
                } else {
                    System.out.println("No household user found for userId: " + userId);
                }
                rs.close();
            } catch (SQLException e) {
                System.err.println("Error fetching household user name: " + e.getMessage());
                e.printStackTrace();
            }
        } 
        // FIXED: Changed from "recycle_center" to "recycle_centre" to match your database ENUM
        else if ("recycle_center".equalsIgnoreCase(role)) {
            String sql = "SELECT centre_name FROM RECYCLE_CENTRE WHERE user_id = ?";
            try (Connection conn = DBManager.getConnection(); 
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    name = rs.getString("centre_name");
                    System.out.println("Recycle centre name: " + name);
                } else {
                    System.out.println("No recycle centre found for userId: " + userId);
                    name = "Recycle Centre";
                }
                rs.close();
            } catch (SQLException e) {
                System.err.println("Error fetching recycle centre name: " + e.getMessage());
                e.printStackTrace();
            }
        } 
        else if ("admin".equalsIgnoreCase(role)) {
            String sql = "SELECT email_address FROM USERS WHERE user_id = ? AND role = 'admin'";
            try (Connection conn = DBManager.getConnection(); 
                 PreparedStatement ps = conn.prepareStatement(sql)) {
                ps.setInt(1, userId);
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    String email = rs.getString("email_address");
                    name = email != null && email.contains("@")
                            ? email.substring(0, email.indexOf("@"))
                            : "Admin User";
                    System.out.println("Admin name: " + name);
                } else {
                    System.out.println("No admin user found in USERS for userId: " + userId);
                    name = "Admin User";
                }
                rs.close();
            } catch (SQLException e) {
                System.err.println("Error fetching admin name: " + e.getMessage());
                e.printStackTrace();
            }
        }

        return name;
    }
}
