package za.ac.tut.web;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

public class WekaAIService {
    
    // TASK 1: Predict area demand based on pickup count
    public String predictAreaDemand(String city, String province, Connection conn) throws Exception {
        String sql = "SELECT COUNT(*) as pickup_count " +
                     "FROM PICKUP_REQUEST pr " +
                     "JOIN HOUSEHOLD_USER hu ON pr.household_user_id = hu.user_id " +
                     "WHERE hu.city = ? AND pr.request_status = 'completed'";
        
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, city);
        ResultSet rs = ps.executeQuery();
        
        int count = 0;
        if (rs.next()) {
            count = rs.getInt("pickup_count");
        }
        rs.close();
        ps.close();
        
        if (count > 30) return "HIGH";
        else if (count > 15) return "MEDIUM";
        else return "LOW";
    }
    
    // Get area statistics
    public AreaStats getAreaStats(String city, Connection conn) throws Exception {
        String sql = "SELECT " +
                     "COUNT(DISTINCT pr.request_id) as total_pickups, " +
                     "COALESCE(SUM(pi.estimated_weight), 0) as total_weight, " +
                     "COUNT(DISTINCT hu.user_id) as active_households " +
                     "FROM HOUSEHOLD_USER hu " +
                     "LEFT JOIN PICKUP_REQUEST pr ON hu.user_id = pr.household_user_id " +
                     "LEFT JOIN PICKUP_ITEM pi ON pr.request_id = pi.request_id " +
                     "WHERE hu.city = ? AND (pr.request_status = 'completed' OR pr.request_status IS NULL)";
        
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, city);
        ResultSet rs = ps.executeQuery();
        
        AreaStats stats = new AreaStats();
        if (rs.next()) {
            stats.totalPickups = rs.getInt("total_pickups");
            stats.totalWeight = rs.getDouble("total_weight");
            stats.activeHouseholds = rs.getInt("active_households");
        }
        
        rs.close();
        ps.close();
        return stats;
    }
    
    // TASK 2: Get centre recommendation based on distance
    public String recommendCentre(double distance, String city) {
        if (distance < 3) {
            return "Go to closest centre (" + String.format("%.1f", distance) + " km from city center)";
        } else if (distance < 7) {
            return "Consider closest centre or one with better capacity (" + String.format("%.1f", distance) + " km)";
        } else {
            return "Closest centre is " + String.format("%.1f", distance) + " km away. Schedule pickup carefully.";
        }
    }
    
    // TASK 3: Predict most recycled material in area
    public String predictMostLikelyMaterial(String city, Connection conn) throws Exception {
        String sql = "SELECT rm.material_name, COUNT(*) as count " +
                     "FROM PICKUP_ITEM pi " +
                     "JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id " +
                     "JOIN PICKUP_REQUEST pr ON pi.request_id = pr.request_id " +
                     "JOIN HOUSEHOLD_USER hu ON pr.household_user_id = hu.user_id " +
                     "WHERE hu.city = ? AND pr.request_status = 'completed' " +
                     "GROUP BY rm.material_name " +
                     "ORDER BY count DESC " +
                     "LIMIT 1";
        
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, city);
        ResultSet rs = ps.executeQuery();
        
        if (rs.next()) {
            String material = rs.getString("material_name");
            rs.close();
            ps.close();
            return material;
        }
        
        rs.close();
        ps.close();
        return "Plastic (default prediction)";
    }
}

// AreaStats class
class AreaStats {
    public int totalPickups;
    public double totalWeight;
    public int activeHouseholds;
}