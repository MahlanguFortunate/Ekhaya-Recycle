<%-- 
    File: wallet.jsp
    Fixed version with correct transaction history matching your schema
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");
    
    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    String firstName = userName;
    if (userName != null && userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }
    
    double walletBalance = 0.00;
    double totalEarned = 0.00;
    int walletId = 0;
    
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        conn = DBManager.getConnection();
        
        // Get wallet balance and wallet_id
        String walletSql = "SELECT wallet_id, balance FROM WALLET WHERE household_user_id = ?";
        ps = conn.prepareStatement(walletSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            walletId = rs.getInt("wallet_id");
            walletBalance = rs.getDouble("balance");
        }
        rs.close();
        ps.close();
        
        // Get total earned from COLLECTION_RECORD using amount_owed
        String earningsSql = "SELECT SUM(cr.amount_owed) as total FROM COLLECTION_RECORD cr "
                           + "JOIN PICKUP_REQUEST pr ON cr.request_id = pr.request_id "
                           + "WHERE pr.household_user_id = ? AND pr.request_status = 'completed' AND cr.actual_weight > 0 AND cr.amount_owed > 0";
        ps = conn.prepareStatement(earningsSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next() && rs.getDouble("total") > 0) {
            totalEarned = rs.getDouble("total");
        }
        rs.close();
        ps.close();
        
        // Get user location
        String userLocationSql = "SELECT city, province FROM HOUSEHOLD_USER WHERE user_id = ?";
        ps = conn.prepareStatement(userLocationSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        String userCity = "South Africa";
        String userProvince = "";
        if (rs.next()) {
            if (rs.getString("city") != null && !rs.getString("city").isEmpty()) {
                userCity = rs.getString("city");
            }
            if (rs.getString("province") != null && !rs.getString("province").isEmpty()) {
                userProvince = rs.getString("province");
            }
        }
        rs.close();
        ps.close();
        
    } catch (Exception e) {
        System.err.println("Error fetching wallet data: " + e.getMessage());
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (ps != null) ps.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Recycle Ekhaya - My Wallet</title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
        <link rel="stylesheet" href="styling/Household_user_dashboard.css" />
        <style>
            .wallet-container {
                max-width: 800px;
                margin: 0 auto;
            }
            .wallet-card {
                background: linear-gradient(135deg, #597226 0%, #3d5119 100%);
                border-radius: 20px;
                padding: 30px;
                color: white;
                margin-bottom: 30px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            }
            .wallet-label {
                font-size: 14px;
                opacity: 0.9;
                margin-bottom: 10px;
                letter-spacing: 0.5px;
            }
            .wallet-amount {
                font-size: 48px;
                font-weight: 700;
                margin-bottom: 5px;
            }
            .wallet-sub {
                font-size: 14px;
                opacity: 0.8;
            }
            .transaction-history {
                background: white;
                border-radius: 16px;
                padding: 24px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            }
            .section-title {
                font-size: 20px;
                font-weight: 600;
                margin-bottom: 20px;
                color: #1a1a2e;
            }
            .transaction-item {
                display: flex;
                justify-content: space-between;
                align-items: center;
                padding: 16px 0;
                border-bottom: 1px solid #eef2f6;
            }
            .transaction-item:last-child {
                border-bottom: none;
            }
            .transaction-info {
                display: flex;
                align-items: center;
                gap: 12px;
            }
            .transaction-icon {
                width: 40px;
                height: 40px;
                background: #e8f5e9;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                color: #597226;
            }
            .transaction-details {
                display: flex;
                flex-direction: column;
            }
            .transaction-name {
                font-weight: 500;
                color: #1a1a2e;
            }
            .transaction-date {
                font-size: 12px;
                color: #666;
            }
            .transaction-amount {
                font-weight: 600;
                font-size: 18px;
            }
            .transaction-amount.positive {
                color: #597226;
            }
            .btn-withdraw {
                background-color: #597226;
                color: white;
                border: none;
                padding: 12px 24px;
                border-radius: 8px;
                font-weight: 600;
                cursor: pointer;
                margin-top: 20px;
                width: 100%;
                transition: all 0.3s;
            }
            .btn-withdraw:hover:not(:disabled) {
                background-color: #3d5119;
                transform: translateY(-2px);
            }
            .btn-withdraw:disabled {
                background-color: #ccc;
                cursor: not-allowed;
            }
            .empty-state {
                text-align: center;
                padding: 40px;
                color: #666;
            }
            .empty-state a {
                color: #597226;
                text-decoration: none;
                font-weight: 500;
            }
            .empty-state a:hover {
                text-decoration: underline;
            }
            .error-state {
                text-align: center;
                padding: 40px;
                color: #d32f2f;
            }
        </style>
    </head>
    <body>
        <aside class="sidebar" id="sidebar">
            <div class="sidebar-logo">
                <div class="logo-icon">♻️</div>
                <a href="household_user_dashboard.jsp" class="logo-text">Recycle Ekhaya</a>
            </div>
            <nav class="sidebar-nav">
                <div class="sidebar-user-badge">
                    <span class="house-icon">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M3 12l9-9 9 9" />
                            <path d="M9 21V12h6v9" />
                        </svg>
                    </span>
                    <span>Welcome, <%= firstName %>!</span>
                </div>
                <span class="nav-label-section">Main</span>
                <a class="nav-item" href="household_user_dashboard.jsp">
                    <span class="nav-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="3" y="3" width="7" height="7" />
                            <rect x="14" y="3" width="7" height="7" />
                            <rect x="14" y="14" width="7" height="7" />
                            <rect x="3" y="14" width="7" height="7" />
                        </svg>
                    </span>
                    <span class="nav-text">Dashboard</span>
                </a>
                <a class="nav-item" href="schedule_pickup.jsp">
                    <span class="nav-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="3" y="4" width="18" height="18" rx="2" />
                            <line x1="16" y1="2" x2="16" y2="6" />
                            <line x1="8" y1="2" x2="8" y2="6" />
                            <line x1="3" y1="10" x2="21" y2="10" />
                        </svg>
                    </span>
                    <span class="nav-text">Pickup Request</span>
                </a>
                <a class="nav-item active" href="wallet.jsp">
                    <span class="nav-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <rect x="2" y="5" width="20" height="14" rx="2" />
                            <line x1="2" y1="10" x2="22" y2="10" />
                        </svg>
                    </span>
                    <span class="nav-text">Wallet</span>
                </a>
                <span class="nav-label-section">Insights</span>
                <a class="nav-item" href="AIDashboardServlet.do">
                    <span class="nav-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <line x1="18" y1="20" x2="18" y2="10" />
                            <line x1="12" y1="20" x2="12" y2="4" />
                            <line x1="6" y1="20" x2="6" y2="14" />
                        </svg>
                    </span>
                    <span class="nav-text">AI Analytics</span>
                </a>
                <span class="nav-label-section">Account</span>
                <a class="nav-item" href="profile.jsp">
                    <span class="nav-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                            <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
                            <circle cx="12" cy="7" r="4" />
                        </svg>
                    </span>
                    <span class="nav-text">Profile</span>
                </a>
            </nav>
            <div class="sidebar-footer">
                <form action="LogoutServlet.do" method="GET" style="margin: 0; padding: 0; width: 100%;">
                    <button class="nav-item sign-out-btn" type="submit" style="width: 100%; background: none; border: none; cursor: pointer;">
                        <span class="nav-icon">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" />
                                <polyline points="16 17 21 12 16 7" />
                                <line x1="21" y1="12" x2="9" y2="12" />
                            </svg>
                        </span>
                        <span class="nav-text">Sign Out</span>
                    </button>
                </form>
            </div>
        </aside>

        <div class="main" id="main">
            <header class="header">
                <button class="toggle-btn" id="toggleBtn" type="button">
                    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                        <line x1="3" y1="6" x2="21" y2="6" />
                        <line x1="3" y1="12" x2="21" y2="12" />
                        <line x1="3" y1="18" x2="21" y2="18" />
                    </svg>
                </button>
                <div class="header-welcome">
                    <h2>Good <span id="greetingTime"></span>, <span id="userFirstName"><%=firstName%></span> 👋</h2>
                    <p><span id="headerDate"></span> &nbsp;·&nbsp; <span id="headerLocation">Wallet</span></p>
                </div>
                <div class="header-actions">
                    <a href="household_user_dashboard.jsp" class="avatar"><%= firstName.substring(0, 1).toUpperCase() %></a>
                </div>
            </header>

            <main class="content">
                <div class="wallet-container">
                    <div class="wallet-card">
                        <div class="wallet-label">Available Balance</div>
                        <div class="wallet-amount">R <%= String.format("%.2f", walletBalance) %></div>
                        <div class="wallet-sub">Earn rewards by recycling more!</div>
                    </div>

                    <div class="transaction-history">
                        <div class="section-title">Transaction History</div>
                        <%
                            Connection conn2 = null;
                            PreparedStatement ps2 = null;
                            ResultSet rs2 = null;
                            try {
                                conn2 = DBManager.getConnection();
                                
                                // FIXED: Query using WALLET_TRANSACTION table joined with COLLECTION_RECORD
                                String historySql = "SELECT wt.transaction_id, wt.amount, wt.transaction_date, wt.transaction_type, "
                                                   + "cr.actual_weight, cr.collection_date, cr.amount_owed "
                                                   + "FROM WALLET_TRANSACTION wt "
                                                   + "JOIN WALLET w ON wt.wallet_id = w.wallet_id "
                                                   + "LEFT JOIN COLLECTION_RECORD cr ON wt.collection_id = cr.collection_id "
                                                   + "WHERE w.household_user_id = ? "
                                                   + "ORDER BY wt.transaction_date DESC LIMIT 20";
                                ps2 = conn2.prepareStatement(historySql);
                                ps2.setInt(1, userId);
                                rs2 = ps2.executeQuery();
                                
                                boolean hasTransactions = false;
                                while (rs2.next()) {
                                    hasTransactions = true;
                                    double amount = rs2.getDouble("amount");
                                    String transactionDate = rs2.getString("transaction_date");
                                    String transactionType = rs2.getString("transaction_type");
                                    double actualWeight = rs2.getDouble("actual_weight");
                                    String collectionDate = rs2.getString("collection_date");
                        %>
                        <div class="transaction-item">
                            <div class="transaction-info">
                                <div class="transaction-icon">
                                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="10" />
                                        <path d="M12 6v6l4 2" />
                                    </svg>
                                </div>
                                <div class="transaction-details">
                                    <div class="transaction-name">
                                        <% if ("credit".equalsIgnoreCase(transactionType)) { %>
                                            Recycling Reward - Payment Received
                                        <% } else { %>
                                            Transaction
                                        <% } %>
                                    </div>
                                    <div class="transaction-date">
                                        <%= transactionDate %> 
                                        <% if (actualWeight > 0) { %>
                                            • <%= String.format("%.1f", actualWeight) %> kg recycled
                                        <% } %>
                                    </div>
                                </div>
                            </div>
                            <div class="transaction-amount positive">
                                +R <%= String.format("%.2f", amount) %>
                            </div>
                        </div>
                        <%
                                }
                                if (!hasTransactions) {
                        %>
                        <div class="empty-state">
                            <p>No transactions yet. Start recycling to earn rewards!</p>
                            <a href="schedule_pickup.jsp">Schedule a pickup →</a>
                        </div>
                        <%
                                }
                                rs2.close();
                                ps2.close();
                                conn2.close();
                            } catch (Exception e) {
                                e.printStackTrace();
                        %>
                        <div class="error-state">
                            <p>Error loading transactions: <%= e.getMessage() %></p>
                            <p style="font-size: 12px; margin-top: 10px;">Please try again later.</p>
                        </div>
                        <%
                            } finally {
                                try { if (rs2 != null) rs2.close(); } catch (SQLException e) {}
                                try { if (ps2 != null) ps2.close(); } catch (SQLException e) {}
                                try { if (conn2 != null) conn2.close(); } catch (SQLException e) {}
                            }
                        %>
                        
                        
                    </div>
                </div>

                <footer class="page-footer">
                    © 2026 <strong>Recycle Ekhaya</strong>. Built for a greener South Africa.
                </footer>
            </main>
        </div>

        <script>
            const hour = new Date().getHours();
            const greeting = hour < 12 ? "Morning" : (hour < 18 ? "Afternoon" : "Evening");
            document.getElementById('greetingTime').textContent = greeting;
            const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
            document.getElementById('headerDate').textContent = new Date().toLocaleDateString('en-ZA', options);
            
            const sidebar = document.getElementById('sidebar');
            const toggleBtn = document.getElementById('toggleBtn');
            if (toggleBtn) {
                toggleBtn.addEventListener('click', () => {
                    sidebar.classList.toggle('collapsed');
                    document.body.classList.toggle('sidebar-collapsed');
                });
            }
        </script>
    </body>
</html>
