<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.*"%>

<%
    Integer requestId = (Integer) request.getAttribute("requestId");
    Integer householdId = (Integer) request.getAttribute("householdId");
    String scheduledDate = (String) request.getAttribute("scheduledDate");
    String createdDate = (String) request.getAttribute("createdDate");
    String status = (String) request.getAttribute("status");
    String pickupStreet = (String) request.getAttribute("pickupStreet");
    String pickupCity = (String) request.getAttribute("pickupCity");
    String pickupProvince = (String) request.getAttribute("pickupProvince");
    String pickupPostal = (String) request.getAttribute("pickupPostal");
    String notes = (String) request.getAttribute("notes");
    
    String userFirstName = (String) request.getAttribute("userFirstName");
    String userLastName = (String) request.getAttribute("userLastName");
    String userPhone = (String) request.getAttribute("userPhone");
    String userEmail = (String) request.getAttribute("userEmail");
    String userStreet = (String) request.getAttribute("userStreet");
    String userCity = (String) request.getAttribute("userCity");
    String userProvince = (String) request.getAttribute("userProvince");
    String userPostal = (String) request.getAttribute("userPostal");
    
    List<String[]> materialsList = (List<String[]>) request.getAttribute("materialsList");
    Double totalWeight = (Double) request.getAttribute("totalWeight");
    
    if (requestId == null) {
        response.sendRedirect("centre_requests.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya — Request Details</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styling/Household_user_dashboard.css">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { background: #1a1d21; font-family: 'Inter', sans-serif; padding: 40px 20px; }
        .container { max-width: 900px; margin: 0 auto; }
        .back-link { color: #3b82f6; text-decoration: none; display: inline-block; margin-bottom: 20px; }
        .back-link:hover { text-decoration: underline; }
        .card { background: #fff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.1); margin-bottom: 20px; }
        .card-header { background: linear-gradient(135deg, #597226, #6e8f2f); color: white; padding: 20px 24px; }
        .card-header h1 { font-size: 22px; margin: 0; }
        .card-header p { margin: 5px 0 0; opacity: 0.9; font-size: 14px; }
        .detail-section { padding: 20px 24px; border-bottom: 1px solid #eee; }
        .detail-section:last-child { border-bottom: none; }
        .detail-section h3 { color: #597226; font-size: 16px; margin-bottom: 15px; padding-bottom: 5px; border-bottom: 2px solid #597226; display: inline-block; }
        .detail-grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 15px; }
        .detail-item { display: flex; flex-direction: column; }
        .detail-label { font-size: 11px; color: #8a9680; text-transform: uppercase; font-weight: 600; }
        .detail-value { font-size: 14px; color: #333; margin-top: 4px; font-weight: 500; }
        .address-box { background: #f9faf7; padding: 12px; border-radius: 8px; margin-top: 5px; }
        .materials-list { background: #f9faf7; border-radius: 8px; padding: 15px; }
        .material-item { display: flex; justify-content: space-between; padding: 8px 0; border-bottom: 1px solid #e0e0e0; }
        .material-item:last-child { border-bottom: none; }
        .material-name { font-weight: 600; color: #597226; }
        .total-weight { border-top: 2px solid #597226; margin-top: 8px; padding-top: 10px; font-weight: 700; color: #597226; }
        .status-badge { display: inline-block; padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; }
        .status-pending { background: #fff3e0; color: #ff9800; }
        .status-scheduled { background: #e3f2fd; color: #2196f3; }
        .status-completed { background: #e8f5e9; color: #4caf50; }
        .status-cancelled { background: #ffebee; color: #f44336; }
        .action-buttons { display: flex; gap: 15px; justify-content: flex-end; padding: 20px 24px; background: #f9faf7; }
        .btn { padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; font-size: 14px; font-weight: 600; text-decoration: none; display: inline-block; }
        .btn-accept { background: #4caf50; color: white; }
        .btn-decline { background: #f44336; color: white; }
        .btn-back { background: #666; color: white; }
        .btn:hover { opacity: 0.85; }
        .decline-form { display: inline-flex; align-items: flex-end; gap: 10px; }
        .decline-date-field label { display: block; font-size: 11px; font-weight: 600; color: #8a9680; margin-bottom: 5px; }
        .decline-date-field input { padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-family: inherit; }
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
    <a href="centre_requests.jsp" class="back-link">← Back to Requests</a>
    
    <div class="card">
        <div class="card-header">
            <h1>Request Details - #<%= requestId %></h1>
            <p>Complete information for this pickup request</p>
        </div>
        
        <div style="padding: 15px 24px; background: #f9faf7; border-bottom: 1px solid #eee;">
            <span class="status-badge status-<%= status %>">Status: <%= status != null ? status.toUpperCase() : "UNKNOWN" %></span>
        </div>
        
        <div class="detail-section">
            <h3>Request Information</h3>
            <div class="detail-grid">
                <div class="detail-item"><span class="detail-label">Request ID</span><span class="detail-value">#<%= requestId %></span></div>
                <div class="detail-item"><span class="detail-label">Scheduled Date</span><span class="detail-value"><%= scheduledDate %></span></div>
                <div class="detail-item"><span class="detail-label">Created Date</span><span class="detail-value"><%= createdDate %></span></div>
                <div class="detail-item"><span class="detail-label">Pickup Address</span><span class="detail-value"><%= pickupStreet %>, <%= pickupCity %>, <%= pickupProvince %>, <%= pickupPostal %></span></div>
            </div>
        </div>
        
        <div class="detail-section">
            <h3>Household User</h3>
            <div class="detail-grid">
                <div class="detail-item"><span class="detail-label">User ID</span><span class="detail-value"><%= householdId %></span></div>
                <div class="detail-item"><span class="detail-label">Full Name</span><span class="detail-value"><%= userFirstName %> <%= userLastName %></span></div>
                <div class="detail-item"><span class="detail-label">Email Address</span><span class="detail-value"><%= userEmail %></span></div>
                <div class="detail-item"><span class="detail-label">Phone Number</span><span class="detail-value"><%= userPhone %></span></div>
            </div>
        </div>
        
        <div class="detail-section">
            <h3>Registered Address</h3>
            <div class="address-box"><%= userStreet %><br><%= userCity %>, <%= userProvince %><br><%= userPostal %></div>
        </div>
        
        <div class="detail-section">
            <h3>Materials to Collect</h3>
            <div class="materials-list">
                <% if (materialsList != null && materialsList.size() > 0) { 
                    for (String[] material : materialsList) { 
                %>
                    <div class="material-item"><span class="material-name"><%= material[0] %></span><span><%= material[1] %> kg</span></div>
                <% } %>
                    <div class="material-item total-weight"><span>Total Estimated Weight</span><span><%= String.format("%.1f", totalWeight) %> kg</span></div>
                <% } else { %>
                    <div class="material-item">No materials found for this request</div>
                <% } %>
            </div>
        </div>
        
        <% if (notes != null && !notes.trim().isEmpty()) { %>
        <div class="detail-section">
            <h3>Additional Notes</h3>
            <div style="background: #f9faf7; padding: 12px; border-radius: 8px;"><%= notes %></div>
        </div>
        <% } %>
        
        <div class="action-buttons">
            <a href="centre_requests.jsp" class="btn btn-back">Close</a>
            <% if (status != null && "pending".equalsIgnoreCase(status)) { %>
                <form action="AcceptRequestServlet.do" method="POST" style="display: inline;">
                    <input type="hidden" name="requestId" value="<%= requestId %>">
                    <input type="hidden" name="householdUserId" value="<%= householdId %>">
                    <button type="submit" class="btn btn-accept">Accept Request</button>
                </form>
                <form action="DeclineRequestServlet.do" method="POST" class="decline-form">
                    <input type="hidden" name="requestId" value="<%= requestId %>">
                    <div class="decline-date-field">
                        <label>Preferred pickup date</label>
                        <input type="date" name="preferredPickupDate" required>
                    </div>
                    <button type="submit" class="btn btn-decline">Decline</button>
                </form>
            <% } %>
        </div>
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
    messageModal.addEventListener('click', function(event) {
        if (event.target === messageModal) {
            closeMessageModal();
        }
    });
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape' && messageModal.classList.contains('is-open')) {
            closeMessageModal();
        }
    });
</script>

</body>
</html>
