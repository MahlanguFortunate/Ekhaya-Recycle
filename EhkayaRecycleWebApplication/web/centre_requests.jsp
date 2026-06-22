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

    if (!"recycle_centre".equalsIgnoreCase(userRole) && !"recycle_center".equalsIgnoreCase(userRole)) {
        response.sendRedirect("household_user_dashboard.jsp");
        return;
    }

    String householdFilterParam = request.getParameter("householdId");
    Integer householdFilterId = null;
    if (householdFilterParam != null && householdFilterParam.matches("\\d+")) {
        householdFilterId = Integer.parseInt(householdFilterParam);
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Scheduled Requests</title>
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
        .request-table { width: 100%; border-collapse: collapse; }
        .request-table th { text-align: left; padding: 15px 20px; background: #f9faf7; color: #8a9680; font-size: 11px; font-weight: 600; text-transform: uppercase; border-bottom: 1px solid #eee; }
        .request-table td { padding: 15px 20px; border-bottom: 1px solid #eee; color: #333; font-size: 14px; }
        .request-table tr:hover { background: #f9faf7; }
        .status-badge { display: inline-block; padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 500; }
        .status-scheduled { background: #e3f2fd; color: #2196f3; }
        .btn { padding: 6px 14px; border: none; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 500; margin: 2px; text-decoration: none; display: inline-block; }
        .btn-view { background: #2196f3; color: white; }
        .btn:hover { opacity: 0.85; transform: translateY(-1px); }
        .empty-row td { text-align: center; padding: 40px; color: #999; }
        .action-cell { white-space: nowrap; }
        .modal-backdrop { position: fixed; inset: 0; background: rgba(17,24,39,0.58); display: none; align-items: center; justify-content: center; padding: 20px; z-index: 1000; }
        .modal-backdrop.is-open { display: flex; }
        .app-dialog { width: min(430px, 100%); background: #fff; border-radius: 12px; box-shadow: 0 24px 60px rgba(0,0,0,0.28); overflow: hidden; }
        .app-dialog-header { padding: 18px 20px; border-bottom: 1px solid #edf2e7; }
        .app-dialog-title { margin: 0; color: #1a1f0f; font-size: 18px; font-weight: 800; }
        .app-dialog-body { padding: 18px 20px; color: #4b5563; font-size: 14px; line-height: 1.5; }
        .app-dialog-actions { display: flex; justify-content: flex-end; padding: 0 20px 20px; }
        .app-dialog-btn { border: none; border-radius: 8px; background: #597226; color: #fff; cursor: pointer; font-size: 13px; font-weight: 700; min-height: 40px; padding: 0 18px; }
        .app-dialog.error .app-dialog-btn { background: #dc2626; }
    </style>
</head>
<body>

<div class="container">
    <a href="recycle_center_dashboard.jsp" class="back-link">&lt;- Back to Dashboard</a>

    <div class="header">
        <h1>Scheduled Requests</h1>
        <p>Accepted pickups waiting for collection, weighing, and payment<% if (householdFilterId != null) { %> for household ID <%= householdFilterId %><% } %></p>
    </div>

    <div class="card">
        <div class="card-header">
            <h2>Scheduled Pickup Requests</h2>
        </div>
        <table class="request-table" id="requestsTable">
            <thead>
                <tr>
                    <th>Request ID</th>
                    <th>Household Name</th>
                    <th>City</th>
                    <th>Province</th>
                    <th>Scheduled Date</th>
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
                        String sql = "SELECT pr.request_id, pr.household_user_id, pr.pickup_city, pr.pickup_province, " +
                                   "pr.scheduled_date, pr.request_status, hu.first_name, hu.last_name " +
                                   "FROM PICKUP_REQUEST pr " +
                                   "JOIN HOUSEHOLD_USER hu ON pr.household_user_id = hu.user_id " +
                                   "WHERE pr.centre_id = ? AND pr.request_status = 'scheduled' " +
                                   (householdFilterId != null ? "AND pr.household_user_id = ? " : "") +
                                   "ORDER BY pr.scheduled_date ASC, pr.request_id DESC";
                        ps = conn.prepareStatement(sql);
                        ps.setInt(1, userId);
                        if (householdFilterId != null) {
                            ps.setInt(2, householdFilterId);
                        }
                        rs = ps.executeQuery();

                        boolean hasData = false;
                        while (rs.next()) {
                            hasData = true;
                            int reqId = rs.getInt("request_id");
                            int houseId = rs.getInt("household_user_id");
                            String householdName = rs.getString("first_name") + " " + rs.getString("last_name");
                            String city = rs.getString("pickup_city");
                            String province = rs.getString("pickup_province");
                            String date = rs.getString("scheduled_date");
                %>
                <tr>
                    <td><a href="request_details.jsp?requestId=<%= reqId %>&householdId=<%= houseId %>" style="color: #333; text-decoration: none; font-weight: 500;">#<%= reqId %></a></td>
                    <td><%= householdName %> <span style="color:#888; font-size:11px;">(ID: <%= houseId %>)</span></td>
                    <td><%= city != null ? city : "N/A" %></td>
                    <td><%= province != null ? province : "N/A" %></td>
                    <td><%= date != null ? date : "N/A" %></td>
                    <td><span class="status-badge status-scheduled">scheduled</span></td>
                    <td class="action-cell">
                        <a href="request_details.jsp?requestId=<%= reqId %>&householdId=<%= houseId %>" class="btn btn-view">Weigh and Pay</a>
                    </td>
                </tr>
                <%
                        }
                        if (!hasData) {
                %>
                    <tr class="empty-row"><td colspan="7">No scheduled pickup requests found<% if (householdFilterId != null) { %> for this household<% } %>.</td></tr>
                <%
                        }
                    } catch (Exception e) {
                        e.printStackTrace();
                %>
                    <tr class="empty-row"><td colspan="7">Error loading scheduled requests: <%= e.getMessage() %></td></tr>
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

<div class="modal-backdrop" id="messageModal" aria-hidden="true">
    <div class="app-dialog" id="messageDialog" role="dialog" aria-modal="true" aria-labelledby="messageModalTitle">
        <div class="app-dialog-header">
            <h2 class="app-dialog-title" id="messageModalTitle">Message</h2>
        </div>
        <div class="app-dialog-body" id="messageModalBody"></div>
        <div class="app-dialog-actions">
            <button type="button" class="app-dialog-btn" id="messageModalClose">OK</button>
        </div>
    </div>
</div>

<script>
    const params = new URLSearchParams(window.location.search);
    const modalType = params.get('modalType');
    const modalMessage = params.get('modalMessage');
    const messageModal = document.getElementById('messageModal');
    const messageDialog = document.getElementById('messageDialog');
    const messageTitle = document.getElementById('messageModalTitle');
    const messageBody = document.getElementById('messageModalBody');
    const messageClose = document.getElementById('messageModalClose');

    function closeMessageModal() {
        messageModal.classList.remove('is-open');
        messageModal.setAttribute('aria-hidden', 'true');
        if (modalType || modalMessage) {
            history.replaceState(null, '', window.location.pathname);
        }
    }

    if (modalMessage) {
        messageTitle.textContent = modalType === 'error' ? 'Action needed' : 'Success';
        messageBody.textContent = modalMessage;
        messageDialog.classList.toggle('error', modalType === 'error');
        messageModal.classList.add('is-open');
        messageModal.setAttribute('aria-hidden', 'false');
        messageClose.focus();
    }

    messageClose.addEventListener('click', closeMessageModal);
    messageModal.addEventListener('click', function (event) {
        if (event.target === messageModal) {
            closeMessageModal();
        }
    });
    document.addEventListener('keydown', function (event) {
        if (event.key === 'Escape' && messageModal.classList.contains('is-open')) {
            closeMessageModal();
        }
    });
</script>

</body>
</html>
