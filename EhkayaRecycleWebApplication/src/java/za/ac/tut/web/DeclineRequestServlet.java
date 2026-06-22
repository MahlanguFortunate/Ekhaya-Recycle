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

public class DeclineRequestServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        Integer centreId = null;
        if (session != null) {
            centreId = (Integer) session.getAttribute("userId");
        }

        if (centreId == null) {
            response.sendRedirect("login.html");
            return;
        }
        
        int requestId = Integer.parseInt(request.getParameter("requestId"));
        String preferredPickupDate = request.getParameter("preferredPickupDate");
        if (preferredPickupDate == null || preferredPickupDate.trim().isEmpty()) {
            redirectWithMessage(response, "centre_requests.jsp", "error",
                    "Please select a preferred pickup date before declining.");
            return;
        }

        try {
            java.sql.Date.valueOf(preferredPickupDate);
        } catch (IllegalArgumentException e) {
            redirectWithMessage(response, "centre_requests.jsp", "error",
                    "Please select a valid preferred pickup date.");
            return;
        }
        
        Connection conn = null;
        
        try {
            conn = DBManager.getConnection();
            conn.setAutoCommit(false);
            
            String updateSql = "UPDATE PICKUP_REQUEST SET request_status = 'cancelled' "
                    + "WHERE request_id = ? AND centre_id = ? AND request_status = 'pending'";
            PreparedStatement ps = conn.prepareStatement(updateSql);
            ps.setInt(1, requestId);
            ps.setInt(2, centreId);
            int rowsUpdated = ps.executeUpdate();
            ps.close();

            if (rowsUpdated == 0) {
                conn.rollback();
                redirectWithMessage(response, "centre_requests.jsp", "error",
                        "This request is no longer available to decline.");
                return;
            }

            conn.commit();

            try {
                EmailService.notifyHouseholdPickupDeclined(conn, requestId, preferredPickupDate);
            } catch (Exception emailError) {
                System.err.println("Pickup request declined, but household email notification failed: " + emailError.getMessage());
                emailError.printStackTrace();
            }
            
            redirectWithMessage(response, "centre_requests.jsp", "success",
                    "Pickup request declined successfully.");
            
        } catch (Exception e) {
            e.printStackTrace();
            try {
                if (conn != null) {
                    conn.rollback();
                }
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
            redirectWithMessage(response, "centre_requests.jsp", "error", "Error: " + e.getMessage());
        } finally {
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }

    private void redirectWithMessage(HttpServletResponse response, String page, String type, String message)
            throws IOException {
        response.sendRedirect(page + "?modalType=" + type + "&modalMessage="
                + URLEncoder.encode(message == null ? "" : message, "UTF-8"));
    }
}
