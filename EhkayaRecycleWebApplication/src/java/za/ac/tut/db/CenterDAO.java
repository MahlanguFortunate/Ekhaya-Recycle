package za.ac.tut.db;

import java.sql.*;
import za.ac.tut.object.credentials.Credentials;
import za.ac.tut.object.address.Address;

public class CenterDAO {

    // Register center with latitude and longitude
    public boolean registerCenter(Credentials c, String centerName, String centerPhone, 
                                   Address a, Double latitude, Double longitude) {
        Connection conn = null;
        PreparedStatement ps1 = null;
        PreparedStatement ps2 = null;
        ResultSet rs = null;
        
        try {
            System.out.println("=== Center Registration Started ===");
            
            conn = DBManager.getConnection();
            conn.setAutoCommit(false);
            
            // Check if email already exists
            String checkSql = "SELECT user_id FROM USERS WHERE email_address = ?";
            PreparedStatement checkPs = conn.prepareStatement(checkSql);
            checkPs.setString(1, c.getEmail());
            rs = checkPs.executeQuery();
            
            if (rs.next()) {
                System.out.println("Email already exists: " + c.getEmail());
                rs.close();
                checkPs.close();
                conn.rollback();
                return false;
            }
            rs.close();
            checkPs.close();
            
            // 1. Insert into USERS table
            String sqlUsers = "INSERT INTO USERS (email_address, user_password, role) VALUES (?, ?, ?)";
            ps1 = conn.prepareStatement(sqlUsers, Statement.RETURN_GENERATED_KEYS);
            ps1.setString(1, c.getEmail());
            ps1.setString(2, c.getPassword());
            ps1.setString(3, "recycle_center");
            
            int result1 = ps1.executeUpdate();
            System.out.println("USERS insert result: " + result1);
            
            if (result1 == 0) {
                conn.rollback();
                return false;
            }
            
            // Get the generated user_id
            rs = ps1.getGeneratedKeys();
            int userId = -1;
            if (rs.next()) {
                userId = rs.getInt(1);
                System.out.println("Generated user_id: " + userId);
            } else {
                conn.rollback();
                return false;
            }
            rs.close();
            ps1.close();
            
            // 2. Insert into RECYCLE_CENTRE table WITH latitude and longitude
            String sqlCenter = "INSERT INTO RECYCLE_CENTRE (user_id, centre_name, phone_number, " +
                              "street_address, city, province, postal_code, latitude, longitude) "
                             + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)";
            ps2 = conn.prepareStatement(sqlCenter);
            ps2.setInt(1, userId);
            ps2.setString(2, centerName);
            ps2.setString(3, centerPhone);
            ps2.setString(4, a.getStreetAddress());
            ps2.setString(5, a.getCity());
            ps2.setString(6, a.getProvince());
            ps2.setString(7, a.getPostalCode());
            
            // Handle latitude
            if (latitude != null) {
                ps2.setDouble(8, latitude);
                System.out.println("Latitude: " + latitude);
            } else {
                ps2.setNull(8, java.sql.Types.DECIMAL);
            }
            
            // Handle longitude
            if (longitude != null) {
                ps2.setDouble(9, longitude);
                System.out.println("Longitude: " + longitude);
            } else {
                ps2.setNull(9, java.sql.Types.DECIMAL);
            }
            
            int result2 = ps2.executeUpdate();
            System.out.println("RECYCLE_CENTRE insert result: " + result2);
            
            if (result2 == 0) {
                conn.rollback();
                return false;
            }
            
            conn.commit();
            System.out.println("=== Center Registration Successful for user_id: " + userId + " ===");
            return true;
            
        } catch (SQLException e) {
            System.err.println("SQL ERROR: " + e.getMessage());
            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
            return false;
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (ps1 != null) ps1.close(); } catch (SQLException e) {}
            try { if (ps2 != null) ps2.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
    
    // Get all centres with coordinates
    public ResultSet getAllCentres() {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "SELECT user_id, centre_name, phone_number, " +
                        "street_address, city, province, postal_code, " +
                        "latitude, longitude " +
                        "FROM RECYCLE_CENTRE " +
                        "WHERE latitude IS NOT NULL AND longitude IS NOT NULL";
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            return rs;
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    // Get centre by ID with coordinates
    public ResultSet getCentreById(int centreId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "SELECT user_id, centre_name, phone_number, " +
                        "street_address, city, province, postal_code, " +
                        "latitude, longitude " +
                        "FROM RECYCLE_CENTRE " +
                        "WHERE user_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, centreId);
            rs = pstmt.executeQuery();
            return rs;
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    // Update centre coordinates
    public boolean updateCentreCoordinates(int centreId, double latitude, double longitude) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "UPDATE RECYCLE_CENTRE SET latitude = ?, longitude = ? WHERE user_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setDouble(1, latitude);
            pstmt.setDouble(2, longitude);
            pstmt.setInt(3, centreId);
            
            int rowsAffected = pstmt.executeUpdate();
            return rowsAffected > 0;
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        } finally {
            try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
}