package za.ac.tut.db;

import java.sql.*;
import za.ac.tut.object.credentials.Credentials;
import za.ac.tut.object.personalinfo.PersonalInfo;
import za.ac.tut.object.address.Address;

public class HouseholdDAO {
    
    // Register household with latitude and longitude
    public boolean registerHousehold(Credentials c, PersonalInfo p, Address a, 
                                      Double latitude, Double longitude) {
        Connection conn = null;
        PreparedStatement ps1 = null;
        PreparedStatement ps2 = null;
        PreparedStatement ps3 = null;
        ResultSet rs = null;
        
        try {
            System.out.println("\n========================================");
            System.out.println("STARTING REGISTRATION PROCESS");
            System.out.println("========================================");
            
            System.out.println("Email: " + c.getEmail());
            System.out.println("First Name: " + p.getFirstName());
            System.out.println("Last Name: " + p.getLastName());
            
            if (latitude != null && longitude != null) {
                System.out.println("Geocoding: Lat=" + latitude + ", Lon=" + longitude);
            }
            
            conn = DBManager.getConnection();
            conn.setAutoCommit(false);
            
            // ========== CHECK IF EMAIL ALREADY EXISTS ==========
            System.out.println("\n--- Checking if email exists ---");
            String checkSql = "SELECT user_id FROM USERS WHERE email_address = ?";
            PreparedStatement checkPs = conn.prepareStatement(checkSql);
            checkPs.setString(1, c.getEmail());
            rs = checkPs.executeQuery();
            
            if (rs.next()) {
                int existingId = rs.getInt("user_id");
                System.out.println("❌ EMAIL ALREADY EXISTS! user_id: " + existingId);
                rs.close();
                checkPs.close();
                conn.rollback();
                return false;
            }
            System.out.println("✅ Email is available");
            rs.close();
            checkPs.close();
            // ===================================================
            
            // 1. Insert into USERS table
            System.out.println("\n--- Inserting into USERS ---");
            String sqlUsers = "INSERT INTO USERS (email_address, user_password, role) VALUES (?, ?, ?)";
            ps1 = conn.prepareStatement(sqlUsers, Statement.RETURN_GENERATED_KEYS);
            ps1.setString(1, c.getEmail());
            ps1.setString(2, c.getPassword());
            ps1.setString(3, "household_user");
            
            int result1 = ps1.executeUpdate();
            System.out.println("USERS insert result: " + result1);
            
            if (result1 == 0) {
                System.out.println("❌ USERS insert failed");
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
                System.out.println("❌ Failed to get user_id");
                conn.rollback();
                return false;
            }
            rs.close();
            ps1.close();
            
            // 2. Insert into HOUSEHOLD_USER table (NO recycling_score column)
            System.out.println("\n--- Inserting into HOUSEHOLD_USER ---");
            String sqlHousehold = "INSERT INTO HOUSEHOLD_USER (user_id, first_name, last_name, phone_number, " +
                                 "street_address, city, province, postal_code, latitude, longitude) "
                                 + "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
            ps2 = conn.prepareStatement(sqlHousehold);
            ps2.setInt(1, userId);
            ps2.setString(2, p.getFirstName());
            ps2.setString(3, p.getLastName());
            ps2.setString(4, p.getPhoneNumber());
            ps2.setString(5, a.getStreetAddress());
            ps2.setString(6, a.getCity());
            ps2.setString(7, a.getProvince());
            ps2.setString(8, a.getPostalCode());
            
            // Handle latitude
            if (latitude != null) {
                ps2.setDouble(9, latitude);
                System.out.println("Latitude stored: " + latitude);
            } else {
                ps2.setNull(9, java.sql.Types.DECIMAL);
                System.out.println("Latitude: NULL");
            }
            
            // Handle longitude
            if (longitude != null) {
                ps2.setDouble(10, longitude);
                System.out.println("Longitude stored: " + longitude);
            } else {
                ps2.setNull(10, java.sql.Types.DECIMAL);
                System.out.println("Longitude: NULL");
            }
            
            int result2 = ps2.executeUpdate();
            System.out.println("HOUSEHOLD_USER insert result: " + result2);
            
            if (result2 == 0) {
                System.out.println("❌ HOUSEHOLD_USER insert failed");
                conn.rollback();
                return false;
            }
            ps2.close();
            
            // 3. Insert into WALLET table
            System.out.println("\n--- Inserting into WALLET ---");
            String sqlWallet = "INSERT INTO WALLET (household_user_id, balance) VALUES (?, 0.00)";
            ps3 = conn.prepareStatement(sqlWallet);
            ps3.setInt(1, userId);
            
            int result3 = ps3.executeUpdate();
            System.out.println("WALLET insert result: " + result3);
            
            if (result3 == 0) {
                System.out.println("❌ WALLET insert failed");
                conn.rollback();
                return false;
            }
            ps3.close();
            
            conn.commit();
            System.out.println("\n========== REGISTRATION SUCCESSFUL! ==========\n");
            return true;
            
        } catch (SQLException e) {
            System.err.println("\n========== DATABASE ERROR ==========");
            System.err.println("Error Message: " + e.getMessage());
            e.printStackTrace();
            
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
            return false;
            
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (ps1 != null) ps1.close(); } catch (SQLException e) {}
            try { if (ps2 != null) ps2.close(); } catch (SQLException e) {}
            try { if (ps3 != null) ps3.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
    
    // Get household by ID with coordinates
    public ResultSet getHouseholdById(int householdId) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "SELECT user_id, first_name, last_name, phone_number, " +
                        "street_address, city, province, postal_code, " +
                        "latitude, longitude " +
                        "FROM HOUSEHOLD_USER WHERE user_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, householdId);
            rs = pstmt.executeQuery();
            return rs;
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    // Get household by email
    public ResultSet getHouseholdByEmail(String email) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "SELECT hu.user_id, hu.first_name, hu.last_name, hu.phone_number, " +
                        "hu.street_address, hu.city, hu.province, hu.postal_code, " +
                        "hu.latitude, hu.longitude " +
                        "FROM HOUSEHOLD_USER hu " +
                        "JOIN USERS u ON hu.user_id = u.user_id " +
                        "WHERE u.email_address = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, email);
            rs = pstmt.executeQuery();
            return rs;
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    // Get all households (for admin)
    public ResultSet getAllHouseholds() {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "SELECT user_id, first_name, last_name, phone_number, " +
                        "street_address, city, province, postal_code, " +
                        "latitude, longitude " +
                        "FROM HOUSEHOLD_USER";
            pstmt = conn.prepareStatement(sql);
            rs = pstmt.executeQuery();
            return rs;
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    // Get households by city (for area demand analysis)
    public ResultSet getHouseholdsByCity(String city) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "SELECT user_id, first_name, last_name, phone_number, " +
                        "street_address, city, province, postal_code, " +
                        "latitude, longitude " +
                        "FROM HOUSEHOLD_USER WHERE city = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, city);
            rs = pstmt.executeQuery();
            return rs;
        } catch (SQLException e) {
            e.printStackTrace();
            return null;
        }
    }
    
    // Update household coordinates
    public boolean updateHouseholdCoordinates(int householdId, double latitude, double longitude) {
        Connection conn = null;
        PreparedStatement pstmt = null;
        
        try {
            conn = DBManager.getConnection();
            String sql = "UPDATE HOUSEHOLD_USER SET latitude = ?, longitude = ? WHERE user_id = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setDouble(1, latitude);
            pstmt.setDouble(2, longitude);
            pstmt.setInt(3, householdId);
            
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
    
    // Close resources helper method
    public void closeResources(ResultSet rs, PreparedStatement pstmt, Connection conn) {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (pstmt != null) pstmt.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }
}