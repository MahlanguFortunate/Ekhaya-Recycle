package za.ac.tut.web;

import java.io.IOException;
import java.net.URLEncoder;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

public class AcceptRequestServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        // Get current logged in centre user
        HttpSession session = request.getSession(false);
        Integer centreId = null;
        
        if (session != null) {
            centreId = (Integer) session.getAttribute("userId");
        }
        
        if (centreId == null) {
            response.sendRedirect("login.html");
            return;
        }
        
        // Get request parameters
        String requestIdStr = request.getParameter("requestId");
        String householdUserIdStr = request.getParameter("householdUserId");
        
        if (requestIdStr == null || householdUserIdStr == null) {
            redirectWithMessage(response, "centre_requests.jsp", "error", "Missing request information.");
            return;
        }
        
        int requestId = Integer.parseInt(requestIdStr);
        int householdUserId = Integer.parseInt(householdUserIdStr);
        
        Connection conn = null;
        PreparedStatement ps = null;
        
        try {
            conn = DBManager.getConnection();
            conn.setAutoCommit(false);
            
            // 1. Update the PICKUP_REQUEST table - assign centre and change status
            String updateSql = "UPDATE PICKUP_REQUEST SET centre_id = ?, request_status = 'scheduled' WHERE request_id = ? AND centre_id = ? AND request_status = 'pending'";
            ps = conn.prepareStatement(updateSql);
            ps.setInt(1, centreId);
            ps.setInt(2, requestId);
            ps.setInt(3, centreId);
            
            int result = ps.executeUpdate();
            
            if (result == 0) {
                conn.rollback();
                redirectWithMessage(response, "centre_requests.jsp", "error",
                        "This request has already been accepted or is no longer available.");
                return;
            }
            ps.close();
            
            conn.commit();

            try {
                EmailService.notifyHouseholdPickupAccepted(conn, requestId);
            } catch (Exception emailError) {
                System.err.println("Pickup request accepted, but household email notification failed: " + emailError.getMessage());
                emailError.printStackTrace();
            }
            
            redirectWithMessage(response, "centre_requests.jsp", "success",
                    "Pickup request #" + requestId + " accepted successfully.");
            
        } catch (SQLException e) {
            e.printStackTrace();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {}
            
            redirectWithMessage(response, "centre_requests.jsp", "error", "Database error: " + e.getMessage());
            
        } catch (Exception e) {
            e.printStackTrace();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {}
            
            redirectWithMessage(response, "centre_requests.jsp", "error", "Error: " + e.getMessage());
            
        } finally {
            try { if (ps != null) ps.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }

    private void redirectWithMessage(HttpServletResponse response, String page, String type, String message)
            throws IOException {
        response.sendRedirect(page + "?modalType=" + type + "&modalMessage="
                + URLEncoder.encode(message == null ? "" : message, "UTF-8"));
    }
}
