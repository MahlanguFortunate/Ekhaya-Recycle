<%-- 
    File: household_user_dashboard.jsp
    Fixed version with correct queries matching your database schema
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    // SESSION CHECK - Redirect to login if not authenticated
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");
    
    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Get first name
    String firstName = userName;
    if (userName != null && userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }
    
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    // Variables for statistics
    double walletBalance = 0.00;
    double totalRecycled = 0.00;
    int pickupsCompleted = 0;
    double co2Saved = 0.00;
    String userCity = "";
    String userProvince = "";
    String userCountry = "South Africa";
    double totalEarned = 0.00;
    int pendingPickupsCount = 0;
    
    try {
        conn = DBManager.getConnection();
        
        // Get user location from HOUSEHOLD_USER table
        String locationSql = "SELECT city, province FROM HOUSEHOLD_USER WHERE user_id = ?";
        ps = conn.prepareStatement(locationSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
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
        
        // Get wallet balance
        String walletSql = "SELECT balance FROM WALLET WHERE household_user_id = ?";
        ps = conn.prepareStatement(walletSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            walletBalance = rs.getDouble("balance");
        }
        rs.close();
        ps.close();
        
        // FIXED: Get total earned from COLLECTION_RECORD using amount_owed (not points_earned)
        // Join with PICKUP_REQUEST to filter by household_user_id
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
        
        // FIXED: Get total recycled weight from COLLECTION_RECORD actual_weight
        // This is the actual weight collected, not estimated
        String recycledSql = "SELECT SUM(cr.actual_weight) as total FROM COLLECTION_RECORD cr "
                           + "JOIN PICKUP_REQUEST pr ON cr.request_id = pr.request_id "
                           + "WHERE pr.household_user_id = ? AND pr.request_status = 'completed' AND cr.actual_weight > 0 AND cr.amount_owed > 0";
        ps = conn.prepareStatement(recycledSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next() && rs.getDouble("total") > 0) {
            totalRecycled = rs.getDouble("total");
            co2Saved = totalRecycled * 0.5; // 0.5kg CO2 saved per kg recycled
        }
        rs.close();
        ps.close();
        
        // FIXED: Get completed pickups count from COLLECTION_RECORD
        String completedSql = "SELECT COUNT(*) as count FROM COLLECTION_RECORD cr "
                            + "JOIN PICKUP_REQUEST pr ON cr.request_id = pr.request_id "
                            + "WHERE pr.household_user_id = ? AND pr.request_status = 'completed' AND cr.actual_weight > 0 AND cr.amount_owed > 0";
        ps = conn.prepareStatement(completedSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            pickupsCompleted = rs.getInt("count");
        }
        rs.close();
        ps.close();
        
        // Get pending pickups count for badge (from PICKUP_REQUEST)
        String pendingSql = "SELECT COUNT(*) as count FROM PICKUP_REQUEST WHERE household_user_id = ? AND request_status = 'pending'";
        ps = conn.prepareStatement(pendingSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            pendingPickupsCount = rs.getInt("count");
        }
        rs.close();
        ps.close();
        
    } catch (Exception e) {
        System.err.println("Error fetching dashboard data: " + e.getMessage());
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (ps != null) ps.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }
    
    // Build location string for display
    String displayLocation = userCountry;
    if (!userCity.isEmpty() && !userProvince.isEmpty()) {
        displayLocation = userCity + ", " + userProvince + ", " + userCountry;
    } else if (!userCity.isEmpty()) {
        displayLocation = userCity + ", " + userCountry;
    } else if (!userProvince.isEmpty()) {
        displayLocation = userProvince + ", " + userCountry;
    }
%>

<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Recycle Ekhaya - Household Dashboard</title>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
        <link rel="stylesheet" href="styling/Household_user_dashboard.css" />
        <style>
            .wallet-highlight {
                background: linear-gradient(135deg, #597226 0%, #3d5119 100%);
                border-radius: 16px;
                padding: 20px;
                margin-bottom: 24px;
                color: white;
                position: relative;
                overflow: hidden;
            }
            .wallet-highlight::before {
                content: "💰";
                position: absolute;
                right: 20px;
                top: 20px;
                font-size: 60px;
                opacity: 0.15;
            }
            .wallet-balance-large {
                font-size: 42px;
                font-weight: 700;
                margin-bottom: 5px;
            }
            .wallet-label-large {
                font-size: 14px;
                opacity: 0.9;
                text-transform: uppercase;
                letter-spacing: 1px;
            }
            .wallet-stats {
                display: flex;
                gap: 20px;
                margin-top: 15px;
                padding-top: 15px;
                border-top: 1px solid rgba(255,255,255,0.2);
            }
            .wallet-stat {
                flex: 1;
            }
            .wallet-stat-value {
                font-size: 20px;
                font-weight: 600;
            }
            .wallet-stat-label {
                font-size: 11px;
                opacity: 0.8;
            }
            .btn-wallet {
                background: white;
                color: #597226;
                padding: 10px 20px;
                border-radius: 8px;
                text-decoration: none;
                font-weight: 600;
                font-size: 13px;
                display: inline-flex;
                align-items: center;
                gap: 8px;
                transition: all 0.3s;
                margin-top: 15px;
            }
            .btn-wallet:hover {
                transform: translateY(-2px);
                box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            }
            .btn-report {
                background: #597226;
                color: #fff;
                border-radius: 8px;
                padding: 10px 14px;
                text-decoration: none;
                font-weight: 600;
                font-size: 13px;
                display: inline-flex;
                align-items: center;
                gap: 8px;
            }
            .btn-report:hover {
                background: #3d5119;
            }
            .system-report-card {
                background: #ffffff;
                border-radius: 12px;
                padding: 20px;
                margin-bottom: 30px;
                box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            }
            .system-report-form {
                display: grid;
                grid-template-columns: 1fr auto;
                gap: 12px;
                align-items: end;
            }
            .report-field {
                display: flex;
                flex-direction: column;
                gap: 6px;
            }
            .report-field label {
                color: #667085;
                font-size: 12px;
                font-weight: 700;
            }
            .report-field input {
                min-height: 40px;
                border: 1px solid #d9e0d2;
                border-radius: 8px;
                padding: 0 12px;
                color: #333;
                font-size: 14px;
            }
            .btn-report-download {
                min-height: 40px;
                border: none;
                border-radius: 8px;
                background: #597226;
                color: #ffffff;
                cursor: pointer;
                font-size: 13px;
                font-weight: 700;
                padding: 0 16px;
            }
            .btn-report-download:hover {
                background: #3d5119;
            }
            @media (max-width: 760px) {
                .system-report-form {
                    grid-template-columns: 1fr;
                }
            }
        </style>
    </head>
    <body>
        <aside class="sidebar" id="sidebar">
            <div class="sidebar-logo">
                <div class="logo-icon">♻️</div>
                <a href="household_user_dashboard.jsp" class="logo-text">Recycle Ekhaya</a>
            </div>

            <nav class="sidebar-nav" aria-label="Main navigation">
                <div class="sidebar-user-badge">
                    <span class="house-icon" aria-hidden="true">
                        <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M3 12l9-9 9 9" />
                        <path d="M9 21V12h6v9" />
                        </svg>
                    </span>
                    <span>Welcome, <%= firstName %>!</span>
                </div>

                <span class="nav-label-section">Main</span>

                <a class="nav-item active" href="household_user_dashboard.jsp" data-page="dashboard">
                    <span class="nav-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="3" width="7" height="7" />
                        <rect x="14" y="3" width="7" height="7" />
                        <rect x="14" y="14" width="7" height="7" />
                        <rect x="3" y="14" width="7" height="7" />
                        </svg>
                    </span>
                    <span class="nav-text">Dashboard</span>
                </a>

                <a class="nav-item" href="scan_item.jsp" data-page="scan">
                    <span class="nav-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                        <path d="M4 7V5a2 2 0 012-2h2" />
                        <path d="M16 3h2a2 2 0 012 2v2" />
                        <path d="M20 17v2a2 2 0 01-2 2h-2" />
                        <path d="M8 21H6a2 2 0 01-2-2v-2" />
                        <circle cx="12" cy="12" r="3" />
                        </svg>
                    </span>
                    <span class="nav-text">Scan Item</span>
                </a>

                <a class="nav-item" href="schedule_pickup.jsp" data-page="pickups">
                    <span class="nav-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                        <rect x="3" y="4" width="18" height="18" rx="2" />
                        <line x1="16" y1="2" x2="16" y2="6" />
                        <line x1="8" y1="2" x2="8" y2="6" />
                        <line x1="3" y1="10" x2="21" y2="10" />
                        </svg>
                    </span>
                    <span class="nav-text">Pickup Request</span>
                    <% if (pendingPickupsCount > 0) { %>
                        <span class="nav-badge" id="pendingPickupsBadge"><%= pendingPickupsCount %></span>
                    <% } %>
                </a>

                <a class="nav-item" href="wallet.jsp" data-page="wallet">
                    <span class="nav-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                        <rect x="2" y="5" width="20" height="14" rx="2" />
                        <line x1="2" y1="10" x2="22" y2="10" />
                        </svg>
                    </span>
                    <span class="nav-text">Wallet</span>
                </a>

                <span class="nav-label-section">Insights</span>

                <a class="nav-item" href="AIDashboardServlet.do" data-page="analytics">
                    <span class="nav-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
                        <line x1="18" y1="20" x2="18" y2="10" />
                        <line x1="12" y1="20" x2="12" y2="4" />
                        <line x1="6" y1="20" x2="6" y2="14" />
                        </svg>
                    </span>
                    <span class="nav-text">AI Analytics</span>
                </a>

                <span class="nav-label-section">Account</span>

                <a class="nav-item" href="profile.jsp" data-page="profile">
                    <span class="nav-icon" aria-hidden="true">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                             stroke-linecap="round" stroke-linejoin="round">
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
                        <span class="nav-icon" aria-hidden="true">
                            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                                 stroke-linecap="round" stroke-linejoin="round">
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
                <button class="toggle-btn" id="toggleBtn" type="button" aria-label="Toggle sidebar">
                    <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"
                         stroke-linecap="round">
                    <line x1="3" y1="6" x2="21" y2="6" />
                    <line x1="3" y1="12" x2="21" y2="12" />
                    <line x1="3" y1="18" x2="21" y2="18" />
                    </svg>
                </button>

                <div class="header-welcome">
                    <h2>Good <span id="greetingTime"></span>, <%= firstName %> 👋</h2>
                    <p><span id="headerDate"></span> &nbsp;·&nbsp; <%= displayLocation %></p>
                </div>

                <div class="header-actions">
                    <a href="profile.jsp" class="avatar" aria-label="Profile">
                        <%= firstName.substring(0, 1).toUpperCase() %>
                    </a>
                </div>
            </header>

            <main class="content">
                <h1 class="page-title">Overview</h1>
                <p class="page-subtitle">Welcome back, <strong><%= firstName %></strong>! Here's what's happening with your recycling activity today.</p>

                <div class="system-report-card">
                    <div class="card-header" style="padding: 0 0 16px; border-bottom: none;">
                        <span class="card-title">Household Report</span>
                    </div>
                    <form action="UserReportPdfServlet.do" method="GET" class="system-report-form">
                        <div class="report-field">
                            <label for="householdReportType">Report type</label>
                            <input type="text" id="householdReportType" value="Individual activity PDF" readonly>
                        </div>
                        <button type="submit" class="btn-report-download">Download PDF Report</button>
                    </form>
                </div>

                <!-- Wallet Highlight Section -->
                <div class="wallet-highlight">
                    <div class="wallet-label-large">Wallet Balance</div>
                    <div class="wallet-balance-large">R <%= String.format("%.2f", walletBalance) %></div>
                    <div class="wallet-stats">
                        <div class="wallet-stat">
                            <div class="wallet-stat-value">R <%= String.format("%.2f", totalEarned) %></div>
                            <div class="wallet-stat-label">Total Earned</div>
                        </div>
                        <div class="wallet-stat">
                            <div class="wallet-stat-value"><%= pickupsCompleted %></div>
                            <div class="wallet-stat-label">Pickups Completed</div>
                        </div>
                        <div class="wallet-stat">
                            <div class="wallet-stat-value"><%= String.format("%.1f", totalRecycled) %> kg</div>
                            <div class="wallet-stat-label">Total Recycled</div>
                        </div>
                    </div>
                    <a href="wallet.jsp" class="btn-wallet">
                        View Wallet Details →
                    </a>
                </div>

                <!-- Statistics cards grid -->
                <div class="stat-grid">
                    <a href="wallet.jsp" class="stat-card stat-card--accent">
                        <div class="stat-top">
                            <div>
                                <div class="stat-label">Wallet Balance</div>
                                <div class="stat-value">R <%= String.format("%.2f", walletBalance) %></div>
                            </div>
                            <div class="stat-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <rect x="2" y="7" width="20" height="12" rx="2" />
                                <path d="M2 11h20" />
                                <circle cx="17" cy="13" r="1.5" />
                                </svg>
                            </div>
                        </div>
                    </a>

                    <a href="#analytics" class="stat-card">
                        <div class="stat-top">
                            <div>
                                <div class="stat-label">Total Recycled</div>
                                <div class="stat-value"><%= String.format("%.1f", totalRecycled) %> kg</div>
                            </div>
                            <div class="stat-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <path d="M3 6l3-3 3 3" />
                                <path d="M21 18l-3 3-3-3" />
                                <path d="M7 12a5 5 0 019 0" />
                                <path d="M17 12a5 5 0 01-9 0" />
                                </svg>
                            </div>
                        </div>
                    </a>

                    <a href="#orders" class="stat-card">
                        <div class="stat-top">
                            <div>
                                <div class="stat-label">Pickups Completed</div>
                                <div class="stat-value"><%= pickupsCompleted %></div>
                            </div>
                            <div class="stat-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <rect x="1" y="12" width="15" height="6" rx="2" />
                                <path d="M16 12V8h4l3 4" />
                                <circle cx="5.5" cy="19.5" r="2.5" />
                                <circle cx="18.5" cy="19.5" r="2.5" />
                                </svg>
                            </div>
                        </div>
                    </a>

                    <a href="#analytics" class="stat-card">
                        <div class="stat-top">
                            <div>
                                <div class="stat-label">CO₂ Saved</div>
                                <div class="stat-value"><%= String.format("%.1f", co2Saved) %> kg</div>
                            </div>
                            <div class="stat-icon">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <path d="M12 22s7-4 7-10a7 7 0 10-14 0c0 6 7 10 7 10z" />
                                <path d="M12 12V7" />
                                <path d="M12 12l2-2" />
                                <path d="M12 12l-2-2" />
                                </svg>
                            </div>
                        </div>
                    </a>
                </div>

                <div class="bottom-grid">
                    <div class="card">
                        <div class="card-header">
                            <span class="card-title">Pickup Requests</span>
                            <a href="schedule_pickup.jsp" class="card-action">New Request →</a>
                        </div>
                        <table class="pickup-table">
                            <thead>
                                <tr>
                                    <th>Request ID</th>
                                    <th>Date</th>
                                    <th>Type</th>
                                    <th>Weight</th>
                                    <th>Status</th>
                                </tr>
                            </thead>
                            <tbody>
                                <%
                                    Connection conn2 = null;
                                    PreparedStatement ps2 = null;
                                    ResultSet rs2 = null;
                                    try {
                                        conn2 = DBManager.getConnection();
                                        String pickupSql = "SELECT pr.request_id, pr.scheduled_date, pr.request_status, "
                                                         + "GROUP_CONCAT(DISTINCT rm.material_name) as materials, "
                                                         + "SUM(pi.estimated_weight) as total_weight "
                                                         + "FROM PICKUP_REQUEST pr "
                                                         + "LEFT JOIN PICKUP_ITEM pi ON pr.request_id = pi.request_id "
                                                         + "LEFT JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id "
                                                         + "WHERE pr.household_user_id = ? "
                                                         + "GROUP BY pr.request_id "
                                                         + "ORDER BY pr.request_id DESC LIMIT 10";
                                        
                                        ps2 = conn2.prepareStatement(pickupSql);
                                        ps2.setInt(1, userId);
                                        rs2 = ps2.executeQuery();
                                        
                                        boolean hasRequests = false;
                                        while (rs2.next()) {
                                            hasRequests = true;
                                            int requestIdVal = rs2.getInt("request_id");
                                            String date = rs2.getString("scheduled_date");
                                            String materials = rs2.getString("materials");
                                            if (materials == null) materials = "Pending";
                                            double weight = rs2.getDouble("total_weight");
                                            String status = rs2.getString("request_status");
                                            
                                            String statusClass = "";
                                            if ("pending".equalsIgnoreCase(status)) {
                                                statusClass = "status-pending";
                                            } else if ("scheduled".equalsIgnoreCase(status)) {
                                                statusClass = "status-scheduled";
                                            } else if ("completed".equalsIgnoreCase(status)) {
                                                statusClass = "status-completed";
                                            } else if ("cancelled".equalsIgnoreCase(status)) {
                                                statusClass = "status-cancelled";
                                            }
                                %>
                                <tr>
                                    <td>#<%= requestIdVal %></a></td>
                                    <td><%= date %></a></td>
                                    <td><%= materials %></a></td>
                                    <td><%= String.format("%.1f", weight) %> kg</a></td>
                                    <td><span class="status-badge <%= statusClass %>"><%= status %></span></a></td>
                                </tr>
                                <%
                                        }
                                        if (!hasRequests) {
                                %>
                                <tr>
                                    <td colspan="5" style="text-align: center;">No pickup requests yet. <a href="schedule_pickup.jsp">Create your first request</a></a></a></a></td>
                                </tr>
                                <%
                                        }
                                        rs2.close();
                                        ps2.close();
                                        conn2.close();
                                    } catch (Exception e) {
                                        System.err.println("Error fetching pickup requests: " + e.getMessage());
                                        e.printStackTrace();
                                %>
                                <tr>
                                    <td colspan="5" style="text-align: center; color: red;">Error loading pickup requests</a></a></a></a></td>
                                </tr>
                                <%
                                    }
                                %>
                            </tbody>
                        </table>
                    </div>

                    
                </div>

                <footer class="page-footer">
                    © 2026 <strong>Recycle Ekhaya</strong>. Built for a greener South Africa.
                </footer>
            </main>
        </div>

        <script src="scripts/Household_user_dashboard.js"></script>
        
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
            
            <% if (pendingPickupsCount > 0) { %>
                const pendingBadge = document.getElementById('pendingPickupsBadge');
                if (pendingBadge) {
                    pendingBadge.textContent = "<%= pendingPickupsCount %>";
                    pendingBadge.removeAttribute('hidden');
                }
            <% } %>
        </script>
    </body>
</html>
