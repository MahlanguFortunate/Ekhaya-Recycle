// File: src/java/za/ac/tut/web/RequestDetailsServlet.java
package za.ac.tut.web;

import java.io.IOException;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

public class RequestDetailsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.html");
            return;
        }
        
        String requestIdParam = request.getParameter("requestId");
        String householdIdParam = request.getParameter("householdId");
        
        if (requestIdParam == null || householdIdParam == null) {
            response.sendRedirect("centre_requests.jsp");
            return;
        }
        
        int requestId = Integer.parseInt(requestIdParam);
        int householdId = Integer.parseInt(householdIdParam);
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            
            // Get request details
            String requestSql = "SELECT * FROM PICKUP_REQUEST WHERE request_id = ?";
            ps = conn.prepareStatement(requestSql);
            ps.setInt(1, requestId);
            rs = ps.executeQuery();
            
            if (rs.next()) {
                request.setAttribute("requestId", rs.getInt("request_id"));
                request.setAttribute("householdId", rs.getInt("household_user_id"));
                request.setAttribute("scheduledDate", rs.getString("scheduled_date"));
                request.setAttribute("createdDate", rs.getString("created_date"));
                request.setAttribute("status", rs.getString("request_status"));
                request.setAttribute("pickupStreet", rs.getString("pickup_street"));
                request.setAttribute("pickupCity", rs.getString("pickup_city"));
                request.setAttribute("pickupProvince", rs.getString("pickup_province"));
                request.setAttribute("pickupPostal", rs.getString("pickup_postal_code"));
                request.setAttribute("notes", rs.getString("special_instructions"));
            }
            rs.close();
            ps.close();
            
            // Get household user details
            String userSql = "SELECT hu.*, u.email_address FROM HOUSEHOLD_USER hu " +
                           "JOIN USERS u ON hu.user_id = u.user_id WHERE hu.user_id = ?";
            ps = conn.prepareStatement(userSql);
            ps.setInt(1, householdId);
            rs = ps.executeQuery();
            
            if (rs.next()) {
                request.setAttribute("userFirstName", rs.getString("first_name"));
                request.setAttribute("userLastName", rs.getString("last_name"));
                request.setAttribute("userPhone", rs.getString("phone_number"));
                request.setAttribute("userEmail", rs.getString("email_address"));
                request.setAttribute("userStreet", rs.getString("street_address"));
                request.setAttribute("userCity", rs.getString("city"));
                request.setAttribute("userProvince", rs.getString("province"));
                request.setAttribute("userPostal", rs.getString("postal_code"));
            }
            rs.close();
            ps.close();
            
            // Get materials list
            String materialsSql = "SELECT rm.material_name, pi.estimated_weight " +
                                "FROM PICKUP_ITEM pi " +
                                "JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id " +
                                "WHERE pi.request_id = ?";
            ps = conn.prepareStatement(materialsSql);
            ps.setInt(1, requestId);
            rs = ps.executeQuery();
            
            List<String[]> materialsList = new ArrayList<>();
            double totalWeight = 0.0;
            while (rs.next()) {
                String[] material = new String[2];
                material[0] = rs.getString("material_name");
                material[1] = String.valueOf(rs.getDouble("estimated_weight"));
                materialsList.add(material);
                totalWeight += rs.getDouble("estimated_weight");
            }
            request.setAttribute("materialsList", materialsList);
            request.setAttribute("totalWeight", totalWeight);
            
        } catch (Exception e) {
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (ps != null) ps.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
        
        request.getRequestDispatcher("request_details.jsp").forward(request, response);
    }
}