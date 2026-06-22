<%-- 
    File: request_details.jsp
    Fixed version matching your database schema
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="za.ac.tut.db.DBManager"%>
<%@page import="java.time.LocalDate"%>

<%
    // SESSION CHECK
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
    
    String requestIdParam = request.getParameter("requestId");
    String householdIdParam = request.getParameter("householdId");
    
    if (requestIdParam == null || householdIdParam == null) {
        response.sendRedirect("centre_requests.jsp");
        return;
    }
    
    int requestId = Integer.parseInt(requestIdParam);
    int householdId = Integer.parseInt(householdIdParam);
    
    // Data variables - matching your schema
    String scheduledDate = "";
    String createdDate = "";
    String status = "";
    String pickupStreet = "";
    String pickupCity = "";
    String pickupProvince = "";
    String userFirstName = "";
    String userLastName = "";
    String userPhone = "";
    String userEmail = "";
    String userStreet = "";
    String userCity = "";
    double totalWeight = 0.0;
    double currentWalletBalance = 0.0;
    double lastAmountPaid = 0.0;
    List<String[]> materialsList = new ArrayList<String[]>();
    
    Connection conn = null;
    
    try {
        conn = DBManager.getConnection();
        
        // Get request details - using correct column names from your schema
        String sql = "SELECT request_id, scheduled_date, created_date, request_status, " +
                    "pickup_street_address, pickup_city, pickup_province " +
                    "FROM PICKUP_REQUEST WHERE request_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setInt(1, requestId);
        ResultSet rs = ps.executeQuery();
        
        if (rs.next()) {
            scheduledDate = rs.getString("scheduled_date");
            createdDate = rs.getString("created_date");
            status = rs.getString("request_status");
            pickupStreet = rs.getString("pickup_street_address");
            pickupCity = rs.getString("pickup_city");
            pickupProvince = rs.getString("pickup_province");
            
            // Get total weight from PICKUP_ITEM
            String weightSql = "SELECT SUM(estimated_weight) as total FROM PICKUP_ITEM WHERE request_id = ?";
            PreparedStatement ps2 = conn.prepareStatement(weightSql);
            ps2.setInt(1, requestId);
            ResultSet rs2 = ps2.executeQuery();
            if (rs2.next()) {
                totalWeight = rs2.getDouble("total");
            }
            rs2.close();
            ps2.close();

            String materialsSql = "SELECT rm.material_name, pi.estimated_weight " +
                    "FROM PICKUP_ITEM pi " +
                    "JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id " +
                    "WHERE pi.request_id = ? " +
                    "ORDER BY rm.material_name";
            PreparedStatement psMaterials = conn.prepareStatement(materialsSql);
            psMaterials.setInt(1, requestId);
            ResultSet rsMaterials = psMaterials.executeQuery();
            while (rsMaterials.next()) {
                String[] material = new String[2];
                material[0] = rsMaterials.getString("material_name");
                material[1] = String.format("%.1f", rsMaterials.getDouble("estimated_weight"));
                materialsList.add(material);
            }
            rsMaterials.close();
            psMaterials.close();
        }
        rs.close();
        ps.close();
        
        // Get household details from HOUSEHOLD_USER and USERS
        String userSql = "SELECT hu.first_name, hu.last_name, hu.phone_number, hu.street_address, hu.city, " +
                        "u.email_address FROM HOUSEHOLD_USER hu JOIN USERS u ON hu.user_id = u.user_id " +
                        "WHERE hu.user_id = ?";
        PreparedStatement ps3 = conn.prepareStatement(userSql);
        ps3.setInt(1, householdId);
        ResultSet rs3 = ps3.executeQuery();
        
        if (rs3.next()) {
            userFirstName = rs3.getString("first_name");
            userLastName = rs3.getString("last_name");
            userPhone = rs3.getString("phone_number");
            userEmail = rs3.getString("email_address");
            userStreet = rs3.getString("street_address");
            userCity = rs3.getString("city");
        }
        rs3.close();
        ps3.close();
        
        // Get current wallet balance from WALLET
        String walletSql = "SELECT balance FROM WALLET WHERE household_user_id = ?";
        PreparedStatement ps4 = conn.prepareStatement(walletSql);
        ps4.setInt(1, householdId);
        ResultSet rs4 = ps4.executeQuery();
        if (rs4.next()) {
            currentWalletBalance = rs4.getDouble("balance");
        }
        rs4.close();
        ps4.close();
        
        // Get last payment amount if completed
        if ("completed".equalsIgnoreCase(status)) {
            String paymentSql = "SELECT amount_owed FROM COLLECTION_RECORD WHERE request_id = ? AND actual_weight > 0 AND amount_owed > 0 ORDER BY collection_id DESC";
            PreparedStatement ps5 = conn.prepareStatement(paymentSql);
            ps5.setInt(1, requestId);
            ResultSet rs5 = ps5.executeQuery();
            if (rs5.next()) {
                lastAmountPaid = rs5.getDouble("amount_owed");
            }
            rs5.close();
            ps5.close();
        }
        
        conn.close();
        
    } catch (Exception e) {
        e.printStackTrace();
        System.err.println("Error loading request details: " + e.getMessage());
    }
    
    boolean isCompleted = "completed".equalsIgnoreCase(status);
    boolean isScheduled = "scheduled".equalsIgnoreCase(status);
    boolean isPending = "pending".equalsIgnoreCase(status);
    
    String todayDate = LocalDate.now().toString();
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Request Details - Recycle Ekhaya</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styling/Household_user_dashboard.css">
    <style>
        body { background: #1a1d21; font-family: 'Inter', sans-serif; padding: 40px 20px; }
        .container { max-width: 900px; margin: 0 auto; }
        .back-link { color: #597226; text-decoration: none; margin-bottom: 20px; display: inline-block; }
        .card { background: white; border-radius: 16px; overflow: hidden; margin-bottom: 20px; box-shadow: 0 4px 20px rgba(0,0,0,0.1); }
        .card-header { background: linear-gradient(135deg, #597226, #6e8f2f); color: white; padding: 20px 24px; }
        .card-header h1 { font-size: 22px; margin: 0; }
        .detail-section { padding: 20px 24px; border-bottom: 1px solid #eee; }
        .detail-section h3 { color: #597226; font-size: 16px; margin-bottom: 15px; }
        .detail-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .detail-label { font-size: 11px; color: #8a9680; text-transform: uppercase; }
        .detail-value { font-size: 14px; color: #333; margin-top: 4px; font-weight: 500; }
        .status-badge { padding: 6px 14px; border-radius: 20px; font-size: 13px; font-weight: 600; display: inline-block; }
        .status-pending { background: #fff3e0; color: #ff9800; }
        .status-scheduled { background: #e3f2fd; color: #2196f3; }
        .status-completed { background: #e8f5e9; color: #4caf50; }
        .btn { padding: 12px 24px; border: none; border-radius: 8px; cursor: pointer; font-weight: 600; text-decoration: none; display: inline-block; }
        .btn-back { background: #666; color: white; }
        .btn-accept { background: #4caf50; color: white; }
        .btn-decline { background: #f44336; color: white; }
        .action-buttons { padding: 20px 24px; background: #f9faf7; display: flex; gap: 15px; justify-content: flex-end; }
        .decline-form { display: inline-flex; align-items: flex-end; gap: 10px; }
        .decline-date-field label { display: block; font-size: 11px; font-weight: 600; color: #8a9680; margin-bottom: 5px; }
        .decline-date-field input { padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-family: inherit; }
        .amount-section { background: #f0f7e8; padding: 15px; border-radius: 8px; margin-top: 15px; border-left: 4px solid #597226; }
        .amount-field { margin-bottom: 15px; }
        .amount-field label { font-size: 12px; font-weight: 600; color: #597226; display: block; margin-bottom: 5px; }
        .amount-field input, .amount-field textarea { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 6px; font-family: inherit; }
        .amount-field input[type=number]::-webkit-outer-spin-button,
        .amount-field input[type=number]::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
        .amount-field input[type=number] { -moz-appearance: textfield; }
        .btn-confirm { background: #597226; color: white; width: 100%; }
        .wallet-box { background: #e8f5e9; padding: 15px; border-radius: 8px; margin-top: 10px; text-align: center; }
        .wallet-box .label { font-size: 12px; color: #2e7d32; }
        .wallet-box .amount { font-size: 24px; font-weight: 700; color: #2e7d32; }
        .payment-info { background: #e3f2fd; padding: 15px; border-radius: 8px; margin-top: 10px; }
        .payment-info .paid-amount { font-size: 20px; font-weight: 700; color: #1976d2; }
        .success-message { background: #e8f5e9; color: #2e7d32; padding: 12px; border-radius: 8px; margin-bottom: 15px; text-align: center; }
        .error-message { background: #ffebee; color: #c62828; padding: 12px; border-radius: 8px; margin-bottom: 15px; text-align: center; }
        .materials-list { background: #f9faf7; padding: 15px; border-radius: 8px; }
        .material-item { padding: 9px 0; border-bottom: 1px solid #e0e0e0; display: flex; align-items: center; justify-content: space-between; gap: 16px; }
        .material-item:last-child { border-bottom: none; }
        .material-name { color: #597226; font-weight: 600; }
        .material-inputs { width: 150px; }
        .material-field label { font-size: 11px; font-weight: 600; color: #597226; display: block; margin-bottom: 4px; }
        .material-number-input { width: 100%; padding: 9px 10px; border: 1px solid #ddd; border-radius: 6px; font-family: inherit; }
        .material-number-input::-webkit-outer-spin-button,
        .material-number-input::-webkit-inner-spin-button { -webkit-appearance: none; margin: 0; }
        .material-number-input { -moz-appearance: textfield; }
        .material-total { border-top: 2px solid #597226; margin-top: 8px; padding-top: 12px; color: #597226; font-weight: 700; }
        .modal-backdrop { position: fixed; inset: 0; background: rgba(17,24,39,0.58); display: none; align-items: center; justify-content: center; padding: 20px; z-index: 1000; }
        .modal-backdrop.is-open { display: flex; }
        .app-dialog { width: min(430px, 100%); background: #fff; border-radius: 12px; box-shadow: 0 24px 60px rgba(0,0,0,0.28); overflow: hidden; }
        .app-dialog-header { padding: 18px 20px; border-bottom: 1px solid #edf2e7; }
        .app-dialog-title { margin: 0; color: #1a1f0f; font-size: 18px; font-weight: 800; }
        .app-dialog-body { padding: 18px 20px; color: #4b5563; font-size: 14px; line-height: 1.5; }
        .app-dialog-actions { display: flex; justify-content: flex-end; gap: 10px; padding: 0 20px 20px; }
        .app-dialog-btn { border: none; border-radius: 8px; background: #597226; color: #fff; cursor: pointer; font-size: 13px; font-weight: 700; min-height: 40px; padding: 0 18px; }
        .app-dialog-btn.secondary { background: #eef2e8; color: #344019; }
        .app-dialog.error .app-dialog-btn:not(.secondary) { background: #dc2626; }
        @media (max-width: 700px) {
            .material-item { align-items: flex-start; flex-direction: column; }
            .material-inputs { grid-template-columns: 1fr; width: 100%; }
        }
    </style>
</head>
<body>

<div class="container">
    <a href="centre_requests.jsp" class="back-link">← Back to Requests</a>
    
    <div class="card">
        <div class="card-header">
            <h1>Request Details - #<%= requestId %></h1>
        </div>
        
        <div style="padding: 15px 24px;">
            <span class="status-badge status-<%= status %>">Status: <%= status != null ? status.toUpperCase() : "UNKNOWN" %></span>
        </div>
        
        <div class="detail-section">
            <h3>Request Information</h3>
            <div class="detail-grid">
                <div><span class="detail-label">Request ID</span><div class="detail-value">#<%= requestId %></div></div>
                <div><span class="detail-label">Scheduled Date</span><div class="detail-value"><%= scheduledDate %></div></div>
                <div><span class="detail-label">Created Date</span><div class="detail-value"><%= createdDate %></div></div>
                <div><span class="detail-label">Pickup Address</span><div class="detail-value"><%= pickupStreet %>, <%= pickupCity %>, <%= pickupProvince %></div></div>
            </div>
        </div>
        
        <div class="detail-section">
            <h3>Household Information</h3>
            <div class="detail-grid">
                <div><span class="detail-label">User ID</span><div class="detail-value"><%= householdId %></div></div>
                <div><span class="detail-label">Full Name</span><div class="detail-value"><%= userFirstName %> <%= userLastName %></div></div>
                <div><span class="detail-label">Email</span><div class="detail-value"><%= userEmail %></div></div>
                <div><span class="detail-label">Phone</span><div class="detail-value"><%= userPhone %></div></div>
            </div>
            <div style="margin-top: 10px; background: #f9faf7; padding: 10px; border-radius: 8px;">
                📍 Address: <%= userStreet %>, <%= userCity %>
            </div>
        </div>
        
        <div class="detail-section">
            <h3>Household Items to Collect</h3>
            <div class="materials-list">
                <% if (!materialsList.isEmpty()) {
                    for (String[] material : materialsList) {
                %>
                    <div class="material-item">
                        <span class="material-name"><%= material[0] %></span>
                        <% if (isScheduled && !isCompleted) { %>
                            <div class="material-inputs">
                                <div class="material-field">
                                    <label>Weight(kg)</label>
                                    <input type="hidden" name="materialName" form="paymentForm" value="<%= material[0] %>">
                                    <input type="number" class="material-number-input material-weight" form="paymentForm"
                                           name="materialWeight" step="0.1" min="0" max="250"
                                           data-material="<%= material[0] %>"
                                           placeholder="Weight(kg)" value="0.0">
                                </div>
                            </div>
                        <% } %>
                    </div>
                <%  }
                } else { %>
                    <div class="material-item">No items were found for this request.</div>
                <% } %>
            </div>
        </div>
        
        <% if (isCompleted) { %>
        <div class="detail-section" style="background: #e8f5e9;">
            <h3>✓ Payment Information</h3>
            <div class="payment-info">
                <div class="paid-amount">Amount Paid: R <%= String.format("%.2f", lastAmountPaid) %></div>
                <div style="margin-top: 10px;">This amount has been added to the household's wallet balance.</div>
            </div>
        </div>
        <% } %>
        
        <!-- Confirm Pickup Section -->
        <% if (!isCompleted && isScheduled) { %>
        <div class="detail-section" style="background: #f9faf7;">
            <h3>Complete Pickup - Enter Payment Amount</h3>
            <form action="ConfirmPickupServlet.do" method="POST" id="paymentForm">
                <input type="hidden" name="requestId" value="<%= requestId %>">
                <input type="hidden" name="householdUserId" value="<%= householdId %>">
                
                <div class="amount-section">
                    <div class="amount-field">
                        <label>Total Weight Collected(kg)</label>
                        <input type="number" id="actualWeight" name="actualWeight"
                               step="0.1" min="10" max="250" required readonly
                               placeholder="Total from material weights"
                               value="0.0">
                        <div class="calculation-hint" id="weightRangeHint" style="font-size: 11px; color: #666; margin-top: 5px;">
                            Total collected weight must be between 10kg and 250kg.
                        </div>
                    </div>
                    <div class="amount-field">
                        <label>Amount Payable(R)</label>
                        <input type="number" id="amountToPay" name="amountToPay"
                               step="0.01" min="0.01" required readonly
                               placeholder="Calculated amount payable"
                               value="0.00">
                        <div class="calculation-hint" style="font-size: 11px; color: #666; margin-top: 5px;">
                            Amount payable is calculated using the fixed rate for each material type.
                        </div>
                    </div>
                </div>
                
                <div style="margin-top: 15px;">
                    <button type="button" class="btn btn-confirm" onclick="confirmPayment()">
                        ✓ Confirm Pickup & Pay Household
                    </button>
                </div>
            </form>
        </div>
        <% } %>
        
        <div class="action-buttons">
            <a href="centre_requests.jsp" class="btn btn-back">Close</a>
            <% if (isPending) { %>
                <form action="AcceptRequestServlet.do" method="POST" style="display: inline;">
                    <input type="hidden" name="requestId" value="<%= requestId %>">
                    <input type="hidden" name="householdUserId" value="<%= householdId %>">
                    <button type="submit" class="btn btn-accept">Accept Request</button>
                </form>
                <form action="DeclineRequestServlet.do" method="POST" class="decline-form" id="declineForm">
                    <input type="hidden" name="requestId" value="<%= requestId %>">
                    <div class="decline-date-field">
                        <label for="date">Preferred pickup date</label>
                        <input type="date" name="preferredPickupDate" required min="<%= todayDate %>" id="preferredPickupDate">
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
        <div class="app-dialog-actions" id="messageModalActions">
            <button type="button" class="app-dialog-btn" id="messageModalClose">OK</button>
        </div>
    </div>
</div>

<script>
    const weightInput = document.getElementById('actualWeight');
    const amountInput = document.getElementById('amountToPay');
    const materialWeightInputs = document.querySelectorAll('.material-weight');
    const weightRangeHint = document.getElementById('weightRangeHint');
    const MIN_TOTAL_WEIGHT = 10;
    const MAX_TOTAL_WEIGHT = 250;
    const MATERIAL_RATES = {
        'plastic': 3.50,
        'scrap metal': 20.00,
        'metal': 20.00,
        'paper': 0.11,
        'cardboard': 0.11,
        'paper and cardboard': 0.11,
        'paper & cardboard': 0.11,
        'paper/cardboard': 0.11,
        'glass': 0.87
    };
    
    function calculateTotalWeight() {
        let total = 0;
        materialWeightInputs.forEach(input => {
            total += parseFloat(input.value) || 0;
        });
        return total;
    }

    function calculateAmountPayable() {
        let total = 0;
        materialWeightInputs.forEach(input => {
            const weight = parseFloat(input.value) || 0;
            const material = (input.dataset.material || '').trim().toLowerCase();
            const rate = MATERIAL_RATES[material] || 0;
            total += weight * rate;
        });
        return total;
    }

    function updateTotals() {
        if (weightInput && amountInput) {
            const totalWeight = calculateTotalWeight();
            weightInput.value = totalWeight.toFixed(1);
            amountInput.value = calculateAmountPayable().toFixed(2);

            if (weightRangeHint) {
                if (totalWeight > MAX_TOTAL_WEIGHT) {
                    weightRangeHint.textContent = 'Total collected weight cannot exceed 250kg.';
                    weightRangeHint.style.color = '#c62828';
                } else if (totalWeight > 0 && totalWeight < MIN_TOTAL_WEIGHT) {
                    weightRangeHint.textContent = 'Total collected weight must be at least 10kg.';
                    weightRangeHint.style.color = '#c62828';
                } else {
                    weightRangeHint.textContent = 'Total collected weight must be between 10kg and 250kg.';
                    weightRangeHint.style.color = '#666';
                }
            }
        }
    }
    
    function preventInvalidNumberKeys(input) {
        if (!input) {
            return;
        }

        input.addEventListener('keydown', function(event) {
            if (event.key === '-' || event.key.toLowerCase() === 'e') {
                event.preventDefault();
            }
        });

        input.addEventListener('input', function() {
            const min = parseFloat(this.min) || 0;
            const max = parseFloat(this.max);
            const value = parseFloat(this.value);
            if (!isNaN(value) && value < min) {
                this.value = min.toFixed(1);
            }
            if (!isNaN(max) && !isNaN(value) && value > max) {
                this.value = max.toFixed(1);
            }
            updateTotals();
        });
    }

    materialWeightInputs.forEach(preventInvalidNumberKeys);

    updateTotals();
    
    const messageModal = document.getElementById('messageModal');
    const messageDialog = document.getElementById('messageDialog');
    const messageTitle = document.getElementById('messageModalTitle');
    const messageBody = document.getElementById('messageModalBody');
    const messageActions = document.getElementById('messageModalActions');
    const messageClose = document.getElementById('messageModalClose');
    let pendingConfirmAction = null;

    function closeMessageModal() {
        messageModal.classList.remove('is-open');
        messageModal.setAttribute('aria-hidden', 'true');
        pendingConfirmAction = null;
        messageActions.innerHTML = '<button type="button" class="app-dialog-btn" id="messageModalClose">OK</button>';
        document.getElementById('messageModalClose').addEventListener('click', closeMessageModal);
    }

    function showMessage(title, message, type) {
        messageTitle.textContent = title;
        messageBody.textContent = message;
        messageDialog.classList.toggle('error', type === 'error');
        messageActions.innerHTML = '<button type="button" class="app-dialog-btn" id="messageModalClose">OK</button>';
        document.getElementById('messageModalClose').addEventListener('click', closeMessageModal);
        messageModal.classList.add('is-open');
        messageModal.setAttribute('aria-hidden', 'false');
        document.getElementById('messageModalClose').focus();
    }

    function showConfirm(title, message, onConfirm) {
        pendingConfirmAction = onConfirm;
        messageTitle.textContent = title;
        messageBody.textContent = message;
        messageDialog.classList.remove('error');
        messageActions.innerHTML = '<button type="button" class="app-dialog-btn secondary" id="messageModalCancel">Cancel</button><button type="button" class="app-dialog-btn" id="messageModalConfirm">Confirm</button>';
        document.getElementById('messageModalCancel').addEventListener('click', closeMessageModal);
        document.getElementById('messageModalConfirm').addEventListener('click', function() {
            const action = pendingConfirmAction;
            closeMessageModal();
            if (action) {
                action();
            }
        });
        messageModal.classList.add('is-open');
        messageModal.setAttribute('aria-hidden', 'false');
        document.getElementById('messageModalConfirm').focus();
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

    const params = new URLSearchParams(window.location.search);
    if (params.get('success') === 'true') {
        const amount = params.get('amount') || '0.00';
        showMessage('Pickup completed', 'Pickup completed successfully. R' + amount + ' has been added to the household wallet.', 'success');
        history.replaceState(null, '', window.location.pathname + '?requestId=<%= requestId %>&householdId=<%= householdId %>');
    } else if (params.get('error')) {
        showMessage('Action needed', 'Error completing pickup. Please try again.', 'error');
        history.replaceState(null, '', window.location.pathname + '?requestId=<%= requestId %>&householdId=<%= householdId %>');
    }

    function confirmPayment() {
        const amount = parseFloat(amountInput.value);
        const weight = parseFloat(weightInput.value);
        
        if (isNaN(amount) || amount <= 0) {
            showMessage('Action needed', 'Please enter a valid amount to pay the household.', 'error');
            return;
        }
        
        if (isNaN(weight) || weight < MIN_TOTAL_WEIGHT) {
            showMessage('Action needed', 'Total Weight Collected(kg) must be at least 10kg.', 'error');
            return;
        }

        if (weight > MAX_TOTAL_WEIGHT) {
            showMessage('Action needed', 'Total Weight Collected(kg) cannot exceed 250kg.', 'error');
            return;
        }
        
        showConfirm('Confirm payment', 'Confirm payment of R' + amount.toFixed(2) + ' to the household? This amount will be added to their wallet balance.', function() {
            document.getElementById('paymentForm').submit();
        });
    }

    // Date validation functions
    function validateDate(dateInput) {
        if (!dateInput || !dateInput.value) {
            showMessage('Invalid Date', 'Please select a pickup date.', 'error');
            return false;
        }
        
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const selectedDate = new Date(dateInput.value);
        selectedDate.setHours(0, 0, 0, 0);
        
        if (selectedDate < today) {
            showMessage('Invalid Date', 'Please select today or a future date.', 'error');
            dateInput.value = '';
            return false;
        }
        return true;
    }

    // Add form submission validation for decline form
    document.getElementById('declineForm')?.addEventListener('submit', function(e) {
        const dateInput = this.querySelector('input[name="preferredPickupDate"]');
        if (!validateDate(dateInput)) {
            e.preventDefault();
            return false;
        }
        return true;
    });

    // Validate date on change
        document.getElementById('preferredPickupDate')?.addEventListener('change', function() {
        validateDate(this);
    });
</script>

</body>
</html>