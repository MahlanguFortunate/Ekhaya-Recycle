package za.ac.tut.web;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

public class PickupRequestServlet extends HttpServlet {

    private final NearestCentreService nearestCentreService = new NearestCentreService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("text/html");
        PrintWriter out = response.getWriter();
        
        HttpSession session = request.getSession(false);
        Integer userId = session == null ? null : (Integer) session.getAttribute("userId");
        String userName = session == null ? null : (String) session.getAttribute("userName");
        
        if (userId == null) {
            out.println("<!DOCTYPE html>");
            out.println("<html>");
            out.println("<head><title>Error</title>");
            out.println("<link rel='stylesheet' href='styling/Schedule_pickup.css'>");
            out.println("</head>");
            out.println("<body>");
            out.println("<div class='container' style='text-align: center; margin-top: 50px;'>");
            out.println("<div class='error-message' style='display: block; background: #f8d7da; color: #721c24; padding: 20px; border-radius: 10px;'>");
            out.println("<h3>Session Expired</h3>");
            out.println("<p>Please login again to continue.</p>");
            out.println("<a href='login.html' class='submit-btn' style='display: inline-block; margin-top: 15px;'>Go to Login</a>");
            out.println("</div></div></body></html>");
            return;
        }
        
        Connection conn = null;
        
        try {
            // Get regular form parameters
            String[] materials = request.getParameterValues("material");
            String pickupDate = request.getParameter("date");
            String notes = request.getParameter("notes");
            String useHouseholdAddress = request.getParameter("useHouseholdAddress");
            boolean usingHouseholdAddress = useHouseholdAddress != null && useHouseholdAddress.equals("on");
            
            // Validation
            if (materials == null || materials.length == 0) {
                showErrorPage(out, "Please select at least one material type.", "schedule_pickup.jsp");
                return;
            }
            
            if (pickupDate == null || pickupDate.isEmpty()) {
                showErrorPage(out, "Please select a pickup date.", "schedule_pickup.jsp");
                return;
            }
            
            double estimatedWeight = 0.0;
            
            conn = DBManager.getConnection();
            conn.setAutoCommit(false);
            
            String streetAddress;
            String city;
            String province;
            String postalCode;
            
            // Get address based on user choice
            if (usingHouseholdAddress) {
                String addressSql = "SELECT street_address, city, province, postal_code FROM HOUSEHOLD_USER WHERE user_id = ?";
                PreparedStatement psAddress = conn.prepareStatement(addressSql);
                psAddress.setInt(1, userId);
                ResultSet rsAddress = psAddress.executeQuery();
                
                if (rsAddress.next()) {
                    streetAddress = rsAddress.getString("street_address");
                    city = rsAddress.getString("city");
                    province = rsAddress.getString("province");
                    postalCode = rsAddress.getString("postal_code");
                } else {
                    showErrorPage(out, "Could not find your registered address. Please update your profile first.", "schedule_pickup.jsp");
                    return;
                }
                rsAddress.close();
                psAddress.close();
            } else {
                streetAddress = request.getParameter("street");
                city = request.getParameter("city");
                province = request.getParameter("province");
                postalCode = request.getParameter("postal");
                
                if (streetAddress == null || streetAddress.trim().isEmpty() ||
                    city == null || city.trim().isEmpty() ||
                    province == null || province.trim().isEmpty() ||
                    postalCode == null || postalCode.trim().isEmpty()) {
                    showErrorPage(out, "Please complete all address fields.", "schedule_pickup.jsp");
                    return;
                }
            }

            double[] pickupCoords = nearestCentreService.resolvePickupCoordinates(
                    conn, userId, streetAddress, city, province, postalCode, usingHouseholdAddress);
            if (pickupCoords == null) {
                conn.rollback();
                showErrorPage(out, "Could not locate this pickup street address. Please include the street number/name, city, province and postal code.", "schedule_pickup.jsp");
                return;
            }

            NearestCentreService.AssignedCentre assignedCentre =
                    nearestCentreService.findNearestCentre(conn, pickupCoords[0], pickupCoords[1]);
            if (assignedCentre == null) {
                conn.rollback();
                showErrorPage(out, "No recycle centre with a valid street-level location was found. Please check that centre street addresses are complete.", "schedule_pickup.jsp");
                return;
            }
            
            // Insert into PICKUP_REQUEST
            String sqlRequest = "INSERT INTO PICKUP_REQUEST (household_user_id, centre_id, pickup_street_address, pickup_city, pickup_province, pickup_postal_code, scheduled_date, request_status, created_date) "
                               + "VALUES (?, ?, ?, ?, ?, ?, ?, 'pending', CURDATE())";
            
            PreparedStatement psRequest = conn.prepareStatement(sqlRequest, Statement.RETURN_GENERATED_KEYS);
            psRequest.setInt(1, userId);
            psRequest.setInt(2, assignedCentre.centreId);
            psRequest.setString(3, streetAddress);
            psRequest.setString(4, city);
            psRequest.setString(5, province);
            psRequest.setString(6, postalCode);
            psRequest.setString(7, pickupDate);
            
            int result = psRequest.executeUpdate();
            
            if (result == 0) {
                conn.rollback();
                showErrorPage(out, "Failed to create pickup request. Please try again.", "schedule_pickup.jsp");
                return;
            }
            
            // Get request_id
            ResultSet rs = psRequest.getGeneratedKeys();
            int requestId = -1;
            if (rs.next()) {
                requestId = rs.getInt(1);
            }
            rs.close();
            psRequest.close();
            
            // Insert materials
            double weightPerMaterial = estimatedWeight / materials.length;
            
            for (String materialName : materials) {
                // Get or create material
                String sqlGetMaterial = "SELECT material_id FROM RECYCLE_MATERIAL WHERE material_name = ?";
                PreparedStatement psGetMaterial = conn.prepareStatement(sqlGetMaterial);
                psGetMaterial.setString(1, materialName);
                ResultSet rsMaterial = psGetMaterial.executeQuery();
                
                int materialId = -1;
                if (rsMaterial.next()) {
                    materialId = rsMaterial.getInt("material_id");
                } else {
                    String sqlInsertMaterial = "INSERT INTO RECYCLE_MATERIAL (material_name) VALUES (?)";
                    PreparedStatement psInsertMaterial = conn.prepareStatement(sqlInsertMaterial, Statement.RETURN_GENERATED_KEYS);
                    psInsertMaterial.setString(1, materialName);
                    psInsertMaterial.executeUpdate();
                    
                    ResultSet rsNewMaterial = psInsertMaterial.getGeneratedKeys();
                    if (rsNewMaterial.next()) {
                        materialId = rsNewMaterial.getInt(1);
                    }
                    rsNewMaterial.close();
                    psInsertMaterial.close();
                }
                rsMaterial.close();
                psGetMaterial.close();
                
                // Insert into PICKUP_ITEM
                String sqlPickupItem = "INSERT INTO PICKUP_ITEM (request_id, material_id, estimated_weight) VALUES (?, ?, ?)";
                PreparedStatement psPickupItem = conn.prepareStatement(sqlPickupItem);
                psPickupItem.setInt(1, requestId);
                psPickupItem.setInt(2, materialId);
                psPickupItem.setDouble(3, weightPerMaterial);
                psPickupItem.executeUpdate();
                psPickupItem.close();
            }
            
            // Update notes if provided
            if (notes != null && !notes.trim().isEmpty()) {
                try {
                    String sqlNotes = "UPDATE PICKUP_REQUEST SET notes = ? WHERE request_id = ?";
                    PreparedStatement psNotes = conn.prepareStatement(sqlNotes);
                    psNotes.setString(1, notes);
                    psNotes.setInt(2, requestId);
                    psNotes.executeUpdate();
                    psNotes.close();
                } catch (SQLException e) {
                    // Notes column might not exist
                }
            }
            
            conn.commit();

            try {
                EmailService.notifyCentreOfNewPickup(conn, requestId);
            } catch (Exception emailError) {
                System.err.println("Pickup request created, but centre email notification failed: " + emailError.getMessage());
                emailError.printStackTrace();
            }

            if (session != null) {
                session.removeAttribute(WasteScanServlet.SESSION_SCAN_RESULT);
                session.removeAttribute(WasteScanServlet.SESSION_SCANNED_ITEMS);
            }
            
            // Show success page
            showSuccessPage(out, requestId, materials, estimatedWeight, pickupDate, userName, streetAddress, assignedCentre);
            
        } catch (Exception e) {
            e.printStackTrace();
            try {
                if (conn != null) conn.rollback();
            } catch (SQLException ex) {}
            
            showErrorPage(out, "An error occurred: " + e.getMessage(), "schedule_pickup.jsp");
        } finally {
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
    
    private void showSuccessPage(PrintWriter out, int requestId, String[] materials, double weight, String date, String userName, String address, NearestCentreService.AssignedCentre assignedCentre) {
        String materialsList = String.join(", ", materials);
        
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<meta charset='UTF-8'>");
        out.println("<title>Success - Pickup Request Submitted</title>");
        out.println("<link rel='stylesheet' href='styling/Schedule_pickup.css'>");
        out.println("<style>");
        out.println(".success-container { max-width: 600px; margin: 50px auto; text-align: center; }");
        out.println(".success-card { background: #fff; border-radius: 12px; padding: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }");
        out.println(".success-title { color: #4CAF50; font-size: 28px; margin-bottom: 10px; }");
        out.println(".request-id { background: #f5f5f5; padding: 15px; border-radius: 8px; margin: 20px 0; }");
        out.println(".request-id h3 { margin: 0 0 10px 0; color: #333; }");
        out.println(".request-id p { font-size: 24px; font-weight: bold; color: #4CAF50; margin: 0; }");
        out.println(".details { text-align: left; background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; }");
        out.println(".details p { margin: 8px 0; }");
        out.println(".button-group { margin-top: 30px; }");
        out.println(".btn { display: inline-block; padding: 12px 24px; margin: 0 10px; border-radius: 8px; text-decoration: none; font-weight: 600; }");
        out.println(".btn-primary { background: #4CAF50; color: white; }");
        out.println(".btn-secondary { background: #597226; color: white; }");
        out.println(".btn:hover { opacity: 0.9; transform: translateY(-2px); transition: all 0.2s; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body style='background: #2c2c2c; min-height: 100vh; display: flex; align-items: center; justify-content: center;'>");
        out.println("<div class='success-container'>");
        out.println("<div class='success-card'>");
        out.println("<h1 class='success-title'>Pickup Request Submitted!</h1>");
        out.println("<p>Thank you, " + (userName != null ? userName : "User") + "! Your request has been received.</p>");
        out.println("<div class='request-id'>");
        out.println("<h3>Your Request ID</h3>");
        out.println("<p>" + requestId + "</p>");
        out.println("</div>");
        out.println("<div class='details'>");
        out.println("<h3>Request Details</h3>");
        out.println("<p><strong>Pickup Date:</strong> " + date + "</p>");
        out.println("<p><strong>Materials:</strong> " + materialsList + "</p>");
        out.println("<p><strong>Pickup Address:</strong> " + address + "</p>");
        out.println("<p><strong>Assigned Recycle Centre:</strong> " + escapeHtml(assignedCentre.name) + "</p>");
        out.println("<p><strong>Centre Address:</strong> " + escapeHtml(assignedCentre.getDisplayAddress()) + "</p>");
        out.println("<p><strong>Distance:</strong> " + assignedCentre.getFormattedDistance() + " away</p>");
        out.println("<p style='font-size:12px;color:#666;'><strong>Pickup coordinates:</strong> " + String.format("%.6f", assignedCentre.pickupLatitude) + ", " + String.format("%.6f", assignedCentre.pickupLongitude) + "</p>");
        out.println("<p style='font-size:12px;color:#666;'><strong>Centre coordinates:</strong> " + String.format("%.6f", assignedCentre.latitude) + ", " + String.format("%.6f", assignedCentre.longitude) + "</p>");
        out.println("</div>");
        out.println("<p><strong>Status:</strong> <span style='color: #ff9800;'>Pending</span> - Sent to the closest recycle centre</p>");
        out.println("<div class='button-group'>");
        out.println("<a href='household_user_dashboard.jsp' class='btn btn-primary'>Go to Dashboard</a>");
        out.println("<a href='schedule_pickup.jsp' class='btn btn-secondary'>New Request</a>");
        out.println("</div>");
        out.println("</div></div>");
        out.println("</body></html>");
    }
    
    private void showErrorPage(PrintWriter out, String errorMessage, String backPage) {
        out.println("<!DOCTYPE html>");
        out.println("<html>");
        out.println("<head>");
        out.println("<meta charset='UTF-8'>");
        out.println("<title>Error - Pickup Request</title>");
        out.println("<link rel='stylesheet' href='styling/Schedule_pickup.css'>");
        out.println("<style>");
        out.println(".error-container { max-width: 500px; margin: 50px auto; text-align: center; }");
        out.println(".error-card { background: #fff; border-radius: 12px; padding: 30px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }");
        out.println(".error-title { color: #f44336; font-size: 28px; margin-bottom: 10px; }");
        out.println(".error-message { background: #ffebee; color: #c62828; padding: 15px; border-radius: 8px; margin: 20px 0; }");
        out.println(".btn { display: inline-block; padding: 12px 24px; margin: 10px; border-radius: 8px; text-decoration: none; font-weight: 600; }");
        out.println(".btn-primary { background: #597226; color: white; }");
        out.println(".btn-secondary { background: #666; color: white; }");
        out.println(".btn:hover { opacity: 0.9; }");
        out.println("</style>");
        out.println("</head>");
        out.println("<body style='background: #2c2c2c; min-height: 100vh; display: flex; align-items: center; justify-content: center;'>");
        out.println("<div class='error-container'>");
        out.println("<div class='error-card'>");
        out.println("<h1 class='error-title'>Submission Failed</h1>");
        out.println("<div class='error-message'>");
        out.println("<p>" + errorMessage + "</p>");
        out.println("</div>");
        out.println("<div class='button-group'>");
        out.println("<a href='" + backPage + "' class='btn btn-primary'>Go Back</a>");
        out.println("<a href='household_user_dashboard.jsp' class='btn btn-secondary'>Dashboard</a>");
        out.println("</div>");
        out.println("</div></div>");
        out.println("</body></html>");
    }

    private String escapeHtml(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
}
