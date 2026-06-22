// File: src/java/za/ac/tut/web/ConfirmPickupServlet.java
package za.ac.tut.web;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

@WebServlet(name = "ConfirmPickupServlet", urlPatterns = {"/ConfirmPickupServlet.do"})
public class ConfirmPickupServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.html");
            return;
        }
        
        int centreId = (Integer) session.getAttribute("userId");
        int requestId = 0;
        int householdUserId = 0;
        double actualWeight = 0.0;
        double amountToPay = 0.0;

        try {
            requestId = Integer.parseInt(request.getParameter("requestId"));
            householdUserId = Integer.parseInt(request.getParameter("householdUserId"));
        } catch (Exception e) {
            response.sendRedirect("centre_requests.jsp?error=invalid_payment");
            return;
        }

        String[] materialWeights = request.getParameterValues("materialWeight");
        String[] materialNames = request.getParameterValues("materialName");
        if (materialWeights == null || materialNames == null || materialWeights.length != materialNames.length) {
            response.sendRedirect("request_details.jsp?requestId=" + requestId + "&householdId=" + householdUserId + "&error=invalid_payment");
            return;
        }

        try {
            actualWeight = 0.0;
            amountToPay = 0.0;
            for (int i = 0; i < materialWeights.length; i++) {
                double materialWeight = parseNonNegativeDouble(materialWeights[i]);
                actualWeight += materialWeight;
                amountToPay += materialWeight * materialRate(materialNames[i]);
            }
        } catch (NumberFormatException e) {
            response.sendRedirect("request_details.jsp?requestId=" + requestId + "&householdId=" + householdUserId + "&error=invalid_payment");
            return;
        }

        if (requestId <= 0 || householdUserId <= 0 || actualWeight < 10 || actualWeight > 250 || amountToPay <= 0) {
            response.sendRedirect("request_details.jsp?requestId=" + requestId + "&householdId=" + householdUserId + "&error=invalid_payment");
            return;
        }
        
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            conn = DBManager.getConnection();
            conn.setAutoCommit(false);
            System.out.println("Database connected successfully");

            System.out.println("=== CONFIRM PICKUP SERVLET CALLED ===");
            System.out.println("Request ID: " + requestId);
            System.out.println("Household User ID: " + householdUserId);
            System.out.println("Amount to Pay: R" + amountToPay);
            System.out.println("Actual Weight: " + actualWeight);
            System.out.println("Centre ID: " + centreId);
            
            // Step 1: Only scheduled requests owned by this centre can be completed.
            String updateRequestSql = "UPDATE PICKUP_REQUEST SET request_status = 'completed' WHERE request_id = ? AND household_user_id = ? AND centre_id = ? AND request_status = 'scheduled'";
            ps = conn.prepareStatement(updateRequestSql);
            ps.setInt(1, requestId);
            ps.setInt(2, householdUserId);
            ps.setInt(3, centreId);
            int rowsUpdated = ps.executeUpdate();
            System.out.println("PICKUP_REQUEST updated: " + rowsUpdated + " rows");
            ps.close();

            if (rowsUpdated == 0) {
                conn.rollback();
                response.sendRedirect("request_details.jsp?requestId=" + requestId + "&householdId=" + householdUserId + "&error=not_scheduled");
                return;
            }

            for (int i = 0; i < materialWeights.length; i++) {
                double materialWeight = parseNonNegativeDouble(materialWeights[i]);
                String updateMaterialWeightSql = "UPDATE PICKUP_ITEM pi "
                        + "JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id "
                        + "SET pi.estimated_weight = ? "
                        + "WHERE pi.request_id = ? AND rm.material_name = ?";
                ps = conn.prepareStatement(updateMaterialWeightSql);
                ps.setDouble(1, materialWeight);
                ps.setInt(2, requestId);
                ps.setString(3, materialNames[i]);
                ps.executeUpdate();
                ps.close();
            }
            
            // Step 2: Insert into COLLECTION_RECORD
            String insertRecordSql = "INSERT INTO COLLECTION_RECORD (request_id, centre_id, actual_weight, amount_owed, collection_date) VALUES (?, ?, ?, ?, CURDATE())";
            ps = conn.prepareStatement(insertRecordSql, Statement.RETURN_GENERATED_KEYS);
            ps.setInt(1, requestId);
            ps.setInt(2, centreId);
            ps.setDouble(3, actualWeight);
            ps.setDouble(4, amountToPay);
            int rowsInserted = ps.executeUpdate();
            
            // Get the generated collection_id
            int collectionId = 0;
            rs = ps.getGeneratedKeys();
            if (rs.next()) {
                collectionId = rs.getInt(1);
            }
            rs.close();
            ps.close();
            System.out.println("COLLECTION_RECORD inserted: " + rowsInserted + " rows, collection_id: " + collectionId);
            
            // Step 3: Get or create wallet for this household
            int walletId = 0;
            String getWalletSql = "SELECT wallet_id, balance FROM WALLET WHERE household_user_id = ?";
            ps = conn.prepareStatement(getWalletSql);
            ps.setInt(1, householdUserId);
            rs = ps.executeQuery();
            
            if (rs.next()) {
                walletId = rs.getInt("wallet_id");
                double currentBalance = rs.getDouble("balance");
                System.out.println("Existing wallet found: wallet_id=" + walletId + ", current balance=R" + currentBalance);
                rs.close();
                ps.close();
                
                // Update wallet balance
                String updateWalletSql = "UPDATE WALLET SET balance = balance + ? WHERE wallet_id = ?";
                ps = conn.prepareStatement(updateWalletSql);
                ps.setDouble(1, amountToPay);
                ps.setInt(2, walletId);
                int walletUpdated = ps.executeUpdate();
                System.out.println("WALLET balance updated: " + walletUpdated + " rows, added R" + amountToPay);
                ps.close();
            } else {
                rs.close();
                ps.close();
                
                // Create new wallet for household
                System.out.println("No wallet found, creating new wallet...");
                String insertWalletSql = "INSERT INTO WALLET (household_user_id, balance) VALUES (?, ?)";
                ps = conn.prepareStatement(insertWalletSql, Statement.RETURN_GENERATED_KEYS);
                ps.setInt(1, householdUserId);
                ps.setDouble(2, amountToPay);
                int walletInserted = ps.executeUpdate();
                
                rs = ps.getGeneratedKeys();
                if (rs.next()) {
                    walletId = rs.getInt(1);
                }
                rs.close();
                ps.close();
                System.out.println("New WALLET created: wallet_id=" + walletId + ", initial balance=R" + amountToPay);
            }
            
            // Step 4: Insert into WALLET_TRANSACTION (This is what shows in transaction history!)
            String insertTransactionSql = "INSERT INTO WALLET_TRANSACTION (wallet_id, collection_id, amount, transaction_type, transaction_date) VALUES (?, ?, ?, 'credit', CURDATE())";
            ps = conn.prepareStatement(insertTransactionSql);
            ps.setInt(1, walletId);
            ps.setInt(2, collectionId);
            ps.setDouble(3, amountToPay);
            int transactionInserted = ps.executeUpdate();
            System.out.println("WALLET_TRANSACTION inserted: " + transactionInserted + " rows");
            ps.close();
            
            // Verify final wallet balance
            String verifySql = "SELECT balance FROM WALLET WHERE wallet_id = ?";
            ps = conn.prepareStatement(verifySql);
            ps.setInt(1, walletId);
            rs = ps.executeQuery();
            if (rs.next()) {
                double newBalance = rs.getDouble("balance");
                System.out.println("FINAL WALLET BALANCE: R" + newBalance);
            }
            rs.close();
            ps.close();
            
            conn.commit();
            System.out.println("=== TRANSACTION COMMITTED SUCCESSFULLY ===");
            
            // Redirect back with success
            response.sendRedirect("request_details.jsp?requestId=" + requestId + "&householdId=" + householdUserId + "&success=true&amount=" + amountToPay);
            
        } catch (Exception e) {
            System.err.println("=== ERROR IN CONFIRM PICKUP ===");
            System.err.println("Error: " + e.getMessage());
            e.printStackTrace();
            try {
                if (conn != null) {
                    conn.rollback();
                    System.out.println("Transaction ROLLED BACK due to error");
                }
            } catch (SQLException ex) {
                ex.printStackTrace();
            }
            response.sendRedirect("request_details.jsp?requestId=" + requestId + "&householdId=" + householdUserId + "&error=true");
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (ps != null) ps.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }

    private double parseNonNegativeDouble(String value) {
        if (value == null || value.trim().isEmpty()) {
            return 0.0;
        }
        double parsed = Double.parseDouble(value);
        if (parsed < 0) {
            throw new NumberFormatException("Negative value is not allowed");
        }
        return parsed;
    }

    private double materialRate(String materialName) {
        if (materialName == null) {
            return 0.0;
        }

        String material = materialName.trim().toLowerCase();
        if ("plastic".equals(material)) {
            return 3.50;
        }
        if ("scrap metal".equals(material) || "metal".equals(material)) {
            return 20.00;
        }
        if ("paper".equals(material) || "cardboard".equals(material)
                || "paper and cardboard".equals(material) || "paper & cardboard".equals(material)
                || "paper/cardboard".equals(material)) {
            return 0.11;
        }
        if ("glass".equals(material)) {
            return 0.87;
        }
        return 0.0;
    }
}
