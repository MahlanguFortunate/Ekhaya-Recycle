<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userRole = (String) session.getAttribute("userRole");

    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }

    if (!"recycle_centre".equalsIgnoreCase(userRole) && !"recycle_center".equalsIgnoreCase(userRole) && !"admin".equalsIgnoreCase(userRole)) {
        response.sendRedirect("household_user_dashboard.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Collection Records</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styling/Household_user_dashboard.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #1a1d21; font-family: 'Inter', sans-serif; }
        .container { max-width: 1400px; margin: 0 auto; padding: 20px; }
        .header { margin-bottom: 30px; }
        .header h1 { color: #fff; font-size: 28px; margin-bottom: 10px; }
        .header p { color: #8a9680; }
        .back-link { color: #597226; text-decoration: none; display: inline-block; margin-bottom: 20px; font-weight: 500; }
        .back-link:hover { text-decoration: underline; }
        .card { background: #fff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .card-header { padding: 20px 24px; border-bottom: 1px solid #eee; background: #f9faf7; }
        .card-header h2 { font-size: 18px; color: #1a1f0f; }
        .records-table { width: 100%; border-collapse: collapse; }
        .records-table th { text-align: left; padding: 15px 20px; background: #f9faf7; color: #8a9680; font-size: 11px; font-weight: 600; text-transform: uppercase; border-bottom: 1px solid #eee; }
        .records-table td { padding: 15px 20px; border-bottom: 1px solid #eee; color: #333; font-size: 14px; }
        .records-table tr:hover { background: #f9faf7; }
        .status-badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 500; background: #e8f5e9; color: #4caf50; }
        .btn { padding: 6px 14px; border: none; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 500; margin: 2px; text-decoration: none; display: inline-block; }
        .btn-view { background: #2196f3; color: white; }
        .empty-row td { text-align: center; padding: 40px; color: #999; }
        .money { color: #2e7d32; font-weight: 700; }
        .weight { color: #597226; font-weight: 700; }
    </style>
</head>
<body>

<div class="container">
    <a href="recycle_center_dashboard.jsp" class="back-link">&lt;- Back to Dashboard</a>

    <div class="header">
        <h1>Collection Records</h1>
        <p>Completed pickups that have been weighed and paid to household wallets</p>
    </div>

    <div class="card">
        <div class="card-header">
            <h2>Completed Collections</h2>
        </div>
        <table class="records-table">
            <thead>
                <tr>
                    <th>Record ID</th>
                    <th>Request ID</th>
                    <th>Household</th>
                    <th>Collection Date</th>
                    <th>Actual Weight</th>
                    <th>Amount Paid</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <%
                    Connection conn = null;
                    PreparedStatement ps = null;
                    ResultSet rs = null;
                    try {
                        conn = DBManager.getConnection();
                        String sql = "SELECT cr.collection_id, cr.request_id, cr.actual_weight, cr.amount_owed, cr.collection_date, " +
                                   "pr.household_user_id, pr.request_status, hu.first_name, hu.last_name " +
                                   "FROM COLLECTION_RECORD cr " +
                                   "JOIN PICKUP_REQUEST pr ON cr.request_id = pr.request_id " +
                                   "JOIN HOUSEHOLD_USER hu ON pr.household_user_id = hu.user_id " +
                                   "WHERE cr.centre_id = ? AND pr.request_status = 'completed' " +
                                   "AND cr.actual_weight > 0 AND cr.amount_owed > 0 " +
                                   "ORDER BY cr.collection_date DESC, cr.collection_id DESC";
                        ps = conn.prepareStatement(sql);
                        ps.setInt(1, userId);
                        rs = ps.executeQuery();

                        boolean hasData = false;
                        while (rs.next()) {
                            hasData = true;
                            int collectionId = rs.getInt("collection_id");
                            int requestId = rs.getInt("request_id");
                            int householdId = rs.getInt("household_user_id");
                            String householdName = rs.getString("first_name") + " " + rs.getString("last_name");
                            String collectionDate = rs.getString("collection_date");
                            double actualWeight = rs.getDouble("actual_weight");
                            double amountPaid = rs.getDouble("amount_owed");
                %>
                <tr>
                    <td>#<%= collectionId %></td>
                    <td>#<%= requestId %></td>
                    <td><%= householdName %> <span style="color:#888; font-size:11px;">(ID: <%= householdId %>)</span></td>
                    <td><%= collectionDate != null ? collectionDate : "N/A" %></td>
                    <td class="weight"><%= String.format("%.1f", actualWeight) %> kg</td>
                    <td class="money">R <%= String.format("%.2f", amountPaid) %></td>
                    <td><span class="status-badge">completed</span></td>
                    <td><a href="request_details.jsp?requestId=<%= requestId %>&householdId=<%= householdId %>" class="btn btn-view">View</a></td>
                </tr>
                <%
                        }
                        if (!hasData) {
                %>
                    <tr class="empty-row"><td colspan="8">No completed collection records found.</td></tr>
                <%
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                %>
                    <tr class="empty-row"><td colspan="8">Error loading collection records: <%= e.getMessage() %></td></tr>
                <%
                    } finally {
                        try { if (rs != null) rs.close(); } catch (SQLException e) {}
                        try { if (ps != null) ps.close(); } catch (SQLException e) {}
                        try { if (conn != null) conn.close(); } catch (SQLException e) {}
                    }
                %>
            </tbody>
        </table>
    </div>
</div>

</body>
</html>
