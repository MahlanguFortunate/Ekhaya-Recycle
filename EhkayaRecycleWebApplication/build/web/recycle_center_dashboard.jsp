<%-- 
    File: recycle_centre_dashboard.jsp
    Fixed version that loads properly
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");
    String userRole = (String) session.getAttribute("userRole");
    
    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Get first name for display
    String firstName = userName;
    if (userName != null && userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }
    
    int pendingRequests = 0;
    int totalPickups = 0;
    double totalWeight = 0.0;
    
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        conn = DBManager.getConnection();
        
        String pendingSql = "SELECT COUNT(*) as count FROM PICKUP_REQUEST WHERE request_status = 'pending' AND centre_id = ?";
        ps = conn.prepareStatement(pendingSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            pendingRequests = rs.getInt("count");
        }
        rs.close();
        ps.close();
        
        String completedSql = "SELECT COUNT(*) as count FROM COLLECTION_RECORD cr JOIN PICKUP_REQUEST pr ON cr.request_id = pr.request_id WHERE cr.centre_id = ? AND pr.request_status = 'completed' AND cr.actual_weight > 0 AND cr.amount_owed > 0";
        ps = conn.prepareStatement(completedSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next()) {
            totalPickups = rs.getInt("count");
        }
        rs.close();
        ps.close();
        
        String weightSql = "SELECT SUM(cr.actual_weight) as total FROM COLLECTION_RECORD cr JOIN PICKUP_REQUEST pr ON cr.request_id = pr.request_id WHERE cr.centre_id = ? AND pr.request_status = 'completed' AND cr.actual_weight > 0 AND cr.amount_owed > 0";
        ps = conn.prepareStatement(weightSql);
        ps.setInt(1, userId);
        rs = ps.executeQuery();
        if (rs.next() && rs.getDouble("total") > 0) {
            totalWeight = rs.getDouble("total");
        }
        rs.close();
        ps.close();
        
    } catch (Exception e) {
        System.err.println("Error fetching centre data: " + e.getMessage());
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (ps != null) ps.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya — Recycle Centre Dashboard</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styling/Household_user_dashboard.css">
    <style>
        .status-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
        }
        .status-pending {
            background-color: #fff3e0;
            color: #ff9800;
        }
        .status-scheduled {
            background-color: #e3f2fd;
            color: #2196f3;
        }
        .status-completed {
            background-color: #e8f5e9;
            color: #4caf50;
        }
        .status-cancelled {
            background-color: #ffebee;
            color: #f44336;
        }
        .btn-accept {
            background-color: #4caf50;
            color: white;
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
            font-size: 12px;
            display: inline-block;
        }
        .btn-accept:hover {
            background-color: #45a049;
        }
        .btn-view {
            background-color: #2196f3;
            color: white;
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
            font-size: 12px;
            display: inline-block;
        }
        .btn-view:hover {
            background-color: #1976d2;
        }
        .btn-decline {
            background-color: #f44336;
            color: white;
            padding: 6px 12px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            text-decoration: none;
            font-size: 12px;
            display: inline-block;
        }
        .btn-decline:hover {
            background-color: #d32f2f;
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
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        .btn-report-download:hover {
            background: #3d5119;
        }
        @media (max-width: 760px) {
            .system-report-form {
                grid-template-columns: 1fr;
            }
        }
        .user-search-form {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: #ffffff;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            padding: 4px 6px 4px 10px;
        }
        .user-search-input {
            width: 190px;
            border: none;
            outline: none;
            font-size: 13px;
            color: #333;
            background: transparent;
        }
        .user-search-btn {
            width: 34px;
            height: 34px;
            border: none;
            border-radius: 6px;
            background: #597226;
            color: #fff;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
        }
        .user-search-btn:hover {
            background: #3d5119;
        }
    </style>
</head>
<body>

<aside class="sidebar" id="sidebar">
    <div class="sidebar-logo">
        <div class="logo-icon">♻️</div>
        <a href="recycle_center_dashboard.jsp" class="logo-text">Recycle Ekhaya</a>
    </div>
    <nav class="sidebar-nav">
        <div class="sidebar-user-badge">
            <span class="house-icon">
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <path d="M3 12l9-9 9 9" />
                    <path d="M9 21V12h6v9" />
                </svg>
            </span>
            <span><%= firstName %></span>
        </div>
        <span class="nav-label-section">Main</span>
        <a class="nav-item active" href="recycle_center_dashboard.jsp">
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
        <a class="nav-item" href="centre_requests.jsp">
            <span class="nav-icon">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="3" y="4" width="18" height="18" rx="2" />
                    <line x1="16" y1="2" x2="16" y2="6" />
                    <line x1="8" y1="2" x2="8" y2="6" />
                    <line x1="3" y1="10" x2="21" y2="10" />
                </svg>
            </span>
            <span class="nav-text">Center Requests</span>
            <% if (pendingRequests > 0) { %>
                <span class="nav-badge"><%= pendingRequests %></span>
            <% } %>
        </a>
        <a class="nav-item" href="collection_records.jsp">
            <span class="nav-icon">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                    <rect x="2" y="5" width="20" height="14" rx="2" />
                    <line x1="2" y1="10" x2="22" y2="10" />
                </svg>
            </span>
            <span class="nav-text">Collection Records</span>
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
            <h2>Good <span id="greetingTime"></span>, <span id="userFirstName"><%= firstName %></span> 👋</h2>
            <p><span id="headerDate"></span> &nbsp;·&nbsp; Recycle Centre, South Africa</p>
        </div>
        <div class="header-actions">
            <form action="recycle_center_user_search.jsp" method="GET" class="user-search-form" role="search">
                <input type="search" name="q" class="user-search-input" placeholder="Search user" aria-label="Search household user" required>
                <button type="submit" class="user-search-btn" aria-label="Search household user">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                    <circle cx="11" cy="11" r="8" />
                    <line x1="21" y1="21" x2="16.65" y2="16.65" />
                </svg>
                </button>
            </form>
            <a href="profile.jsp" class="avatar"><%= firstName.substring(0, 1).toUpperCase() %></a>
        </div>
    </header>

    <main class="content">
        <h1 class="page-title">Recycle Center Dashboard</h1>
        <p class="page-subtitle">Welcome back, <%= firstName %>! Here's what's happening with your recycling centre today.</p>

        <div class="system-report-card">
            <div class="card-header" style="padding: 0 0 16px; border-bottom: none;">
                <span class="card-title">Recycle Centre Report</span>
            </div>
            <form action="UserReportPdfServlet.do" method="GET" class="system-report-form">
                <div class="report-field">
                    <label for="centreReportType">Report type</label>
                    <input type="text" id="centreReportType" value="Individual activity PDF" readonly>
                </div>
                <button type="submit" class="btn-report-download">Download PDF Report</button>
            </form>
        </div>

        <div class="stat-grid">
            <div class="stat-card stat-card--accent">
                <div class="stat-top">
                    <div>
                        <div class="stat-label">Pending Requests</div>
                        <div class="stat-value"><%= pendingRequests %></div>
                    </div>
                    <div class="stat-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <rect x="3" y="4" width="18" height="18" rx="2" />
                            <line x1="16" y1="2" x2="16" y2="6" />
                            <line x1="8" y1="2" x2="8" y2="6" />
                        </svg>
                    </div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-top">
                    <div>
                        <div class="stat-label">Total Pickups</div>
                        <div class="stat-value"><%= totalPickups %></div>
                    </div>
                    <div class="stat-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <path d="M3 6l3-3 3 3" />
                            <path d="M21 18l-3 3-3-3" />
                        </svg>
                    </div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-top">
                    <div>
                        <div class="stat-label">Total Weight Collected</div>
                        <div class="stat-value"><%= String.format("%.1f", totalWeight) %> kg</div>
                    </div>
                    <div class="stat-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <rect x="1" y="12" width="15" height="6" rx="2" />
                            <path d="M16 12V8h4l3 4" />
                        </svg>
                    </div>
                </div>
            </div>
            <div class="stat-card">
                <div class="stat-top">
                    <div>
                        <div class="stat-label">Active Since</div>
                        <div class="stat-value">2026</div>
                    </div>
                    <div class="stat-icon">
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                            <path d="M12 22s7-4 7-10a7 7 0 10-14 0c0 6 7 10 7 10z" />
                            <path d="M12 8v4l2 2" />
                        </svg>
                    </div>
                </div>
            </div>
        </div>

        <div class="card">
            <div class="card-header">
                <span class="card-title">Recent Pickup Requests</span>
                <a href="centre_requests.jsp" class="card-action">View all →</a>
            </div>
            <table class="pickup-table">
                <thead>
                    <tr>
                        <th>Request ID</th>
                        <th>Household ID</th>
                        <th>City</th>
                        <th>Province</th>
                        <th>Scheduled Date</th>
                        <th>Status</th>
                        <th>Actions</th>
                    </tr>
                </thead>
                <tbody>
                    <%
                        Connection conn2 = null;
                        PreparedStatement ps2 = null;
                        ResultSet rs2 = null;
                        try {
                            conn2 = DBManager.getConnection();
                            String sql = "SELECT request_id, household_user_id, pickup_city, pickup_province, scheduled_date, request_status FROM PICKUP_REQUEST WHERE request_status = 'pending' AND centre_id = ? ORDER BY scheduled_date ASC LIMIT 5";
                            ps2 = conn2.prepareStatement(sql);
                            ps2.setInt(1, userId);
                            rs2 = ps2.executeQuery();
                            
                            boolean hasData = false;
                            while (rs2.next()) {
                                hasData = true;
                                int reqId = rs2.getInt("request_id");
                                int householdId = rs2.getInt("household_user_id");
                                String city = rs2.getString("pickup_city");
                                String province = rs2.getString("pickup_province");
                                String date = rs2.getString("scheduled_date");
                                String status = rs2.getString("request_status");
                    %>
                    <tr>
                        <td><%= reqId %></a></td>
                        <td><%= householdId %></a></td>
                        <td><%= city != null ? city : "N/A" %></a></td>
                        <td><%= province != null ? province : "N/A" %></a></td>
                        <td><%= date %></a></td>
                        <td><span class="status-badge status-pending">pending</span></a></td>
                        <td>
                            <a href="request_details.jsp?requestId=<%= reqId %>&householdId=<%= householdId %>" class="btn-view">View Details</a>
                        </a></td>
                    </tr>
                    <%
                            }
                            if (!hasData) {
                    %>
                    <tr>
                        <td colspan="7" style="text-align: center;">No pending pickup requests</a></a></a></td>
                    </tr>
                    <%
                            }
                        } catch (Exception e) {
                            e.printStackTrace();
                    %>
                    <tr>
                        <td colspan="7" style="text-align: center; color: red;">Error loading requests. Please try again.</a></a></a></td>
                    </tr>
                    <%
                        } finally {
                            try { if (rs2 != null) rs2.close(); } catch (SQLException e) {}
                            try { if (ps2 != null) ps2.close(); } catch (SQLException e) {}
                            try { if (conn2 != null) conn2.close(); } catch (SQLException e) {}
                        }
                    %>
                </tbody>
            </table>
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
