<%-- 
    File: admin_dashboard.jsp
    Admin Dashboard with dynamic data from database - Excludes admin from counts
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="java.time.LocalDate"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    // SESSION CHECK - Redirect to login if not authenticated
    Integer adminId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");
    String userRole = (String) session.getAttribute("userRole");
    
    if (adminId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Check if user is admin
    if (!"admin".equalsIgnoreCase(userRole)) {
        response.sendRedirect("household_user_dashboard.jsp");
        return;
    }
    
    // Get first name
    String firstName = userName;
    if (userName != null && userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }

    LocalDate reportEndDate = LocalDate.now();
    LocalDate reportStartDate = reportEndDate.withDayOfMonth(1);
    
    // Variables for admin statistics (excluding current admin)
    int totalHouseholds = 0;
    int totalRecycleCentres = 0;
    int totalUsers = 0;
    
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        conn = DBManager.getConnection();
        
        // Count total households
        String householdsSql = "SELECT COUNT(*) as count FROM HOUSEHOLD_USER";
        ps = conn.prepareStatement(householdsSql);
        rs = ps.executeQuery();
        if (rs.next()) {
            totalHouseholds = rs.getInt("count");
        }
        rs.close();
        ps.close();
        
        // Count total recycle centres
        String centresSql = "SELECT COUNT(*) as count FROM RECYCLE_CENTRE";
        ps = conn.prepareStatement(centresSql);
        rs = ps.executeQuery();
        if (rs.next()) {
            totalRecycleCentres = rs.getInt("count");
        }
        rs.close();
        ps.close();
        
        // Count total users EXCLUDING current admin
        String usersSql = "SELECT COUNT(*) as count FROM USERS WHERE user_id != ?";
        ps = conn.prepareStatement(usersSql);
        ps.setInt(1, adminId);
        rs = ps.executeQuery();
        if (rs.next()) {
            totalUsers = rs.getInt("count");
        }
        rs.close();
        ps.close();
        
    } catch (Exception e) {
        System.err.println("Error fetching admin data: " + e.getMessage());
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
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Recycle Ekhaya — Admin Dashboard</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />

    <!-- Local CSS file -->
    <link rel="stylesheet" href="styling/Household_user_dashboard.css" />
    
    <style>
        .stat-grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            border-radius: 16px;
            padding: 20px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            transition: transform 0.2s, box-shadow 0.2s;
            text-decoration: none;
            display: block;
        }
        .stat-card:hover {
            transform: translateY(-4px);
            box-shadow: 0 8px 24px rgba(0,0,0,0.1);
        }
        .stat-card--accent {
            background: linear-gradient(135deg, #597226 0%, #3d5119 100%);
            color: white;
        }
        .stat-card--accent .stat-label,
        .stat-card--accent .stat-value,
        .stat-card--accent .stat-icon svg {
            color: white;
            stroke: white;
        }
        .stat-top {
            display: flex;
            justify-content: space-between;
            align-items: flex-start;
        }
        .stat-label {
            font-size: 12px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            color: #8a9680;
            margin-bottom: 8px;
        }
        .stat-value {
            font-size: 32px;
            font-weight: 700;
            color: #1a1a2e;
        }
        .stat-icon svg {
            width: 32px;
            height: 32px;
            stroke: #597226;
        }
        .role-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
        }
        .role-household {
            background: #e3f2fd;
            color: #1976d2;
        }
        .role-centre {
            background: #e8f5e9;
            color: #2e7d32;
        }
        .pickup-table {
            width: 100%;
            border-collapse: collapse;
        }
        .pickup-table th {
            text-align: left;
            padding: 14px 16px;
            background: #f9faf7;
            color: #597226;
            font-size: 12px;
            font-weight: 600;
            border-bottom: 2px solid #eef2f6;
        }
        .pickup-table td {
            padding: 12px 16px;
            border-bottom: 1px solid #eef2f6;
            color: #333;
            font-size: 14px;
        }
        .pickup-table tr:hover {
            background: #f9faf7;
        }
        .user-link {
            color: #597226;
            text-decoration: none;
            font-weight: 500;
        }
        .user-link:hover {
            text-decoration: underline;
        }
        .admin-search-form {
            display: inline-flex;
            align-items: center;
            gap: 6px;
            background: #ffffff;
            border: 1px solid #e5e7eb;
            border-radius: 8px;
            padding: 4px 6px 4px 10px;
        }
        .admin-search-input {
            width: 190px;
            border: none;
            outline: none;
            font-size: 13px;
            color: #333;
            background: transparent;
        }
        .admin-search-btn {
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
        .admin-search-btn:hover {
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
            grid-template-columns: repeat(2, minmax(180px, 1fr)) auto;
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
    <!-- =============================================
         SIDEBAR NAVIGATION
         ============================================= -->
    <aside class="sidebar" id="sidebar">
        <div class="sidebar-logo">
            <div class="logo-icon">♻️</div>
            <a href="admin_dashboard.jsp" class="logo-text">Recycle Ekhaya</a>
        </div>

        <nav class="sidebar-nav" aria-label="Main navigation">
            <div class="sidebar-user-badge">
                <span class="house-icon" aria-hidden="true">
                    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                        <path d="M3 12l9-9 9 9" />
                        <path d="M9 21V12h6v9" />
                    </svg>
                </span>
                <span>Admin: <%= firstName %></span>
            </div>

            <span class="nav-label-section">Main</span>

            <a class="nav-item active" href="admin_dashboard.jsp" data-page="dashboard">
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

            <a class="nav-item" href="admin_users_list.jsp" data-page="users_list">
                <span class="nav-icon" aria-hidden="true">
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"
                        stroke-linecap="round" stroke-linejoin="round">
                        <rect x="2" y="5" width="20" height="14" rx="2" />
                        <line x1="2" y1="10" x2="22" y2="10" />
                    </svg>
                </span>
                <span class="nav-text">Users List</span>
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

    <!-- Main content area -->
    <div class="main" id="main">

        <!-- Header section with user greeting and actions -->
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
                <h2>Good <span id="greetingTime"></span>, <span id="userFirstName"><%= firstName %></span> 👋</h2>
                <p><span id="headerDate"></span> &nbsp;·&nbsp; <span id="headerLocation">Admin Dashboard, South Africa</span></p>
            </div>

            <div class="header-actions">
                <form action="admin_users_list.jsp" method="GET" class="admin-search-form" role="search">
                    <input type="search" name="q" class="admin-search-input" placeholder="Search user" aria-label="Search user account" required>
                    <button type="submit" class="admin-search-btn" aria-label="Search user account">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"
                        stroke-linecap="round">
                        <circle cx="11" cy="11" r="8" />
                        <line x1="21" y1="21" x2="16.65" y2="16.65" />
                    </svg>
                    </button>
                </form>

                <button class="icon-btn" type="button" aria-label="Notifications" id="notifBtn">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"
                        stroke-linecap="round">
                        <path d="M18 8A6 6 0 006 8c0 7-3 9-3 9h18s-3-2-3-9" />
                        <path d="M13.73 21a2 2 0 01-3.46 0" />
                    </svg>
                    <span class="notif-dot" id="notifDot" hidden></span>
                </button>

                <a href="admin_profile.jsp" class="avatar" id="userAvatar" aria-label="Profile">
                    <%= firstName.substring(0, 1).toUpperCase() %>
                </a>
            </div>
        </header>

        <!-- Page content -->
        <main class="content">
            <h1 class="page-title">Admin Overview</h1>
            <p class="page-subtitle">Welcome back, <%= firstName %>! Here's what's happening with the recycling platform today.</p>

            <!-- Statistics cards grid -->
            <div class="stat-grid">
                <div class="stat-card stat-card--accent">
                    <div class="stat-top">
                        <div>
                            <div class="stat-label">Total Users</div>
                            <div class="stat-value"><%= totalUsers %></div>
                        </div>
                        <div class="stat-icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
                                <circle cx="12" cy="7" r="4" />
                            </svg>
                        </div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-top">
                        <div>
                            <div class="stat-label">Households</div>
                            <div class="stat-value"><%= totalHouseholds %></div>
                        </div>
                        <div class="stat-icon">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                                <path d="M3 12l9-9 9 9" />
                                <path d="M9 21V12h6v9" />
                            </svg>
                        </div>
                    </div>
                </div>

                <div class="stat-card">
                    <div class="stat-top">
                        <div>
                            <div class="stat-label">Recycle Centres</div>
                            <div class="stat-value"><%= totalRecycleCentres %></div>
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
            </div>

            <div class="system-report-card">
                <div class="card-header" style="padding: 0 0 16px; border-bottom: none;">
                    <span class="card-title">System Report</span>
                </div>
                <form action="AdminSystemReportPdfServlet.do" method="GET" class="system-report-form">
                    <div class="report-field">
                        <label for="reportStartDate">Start date</label>
                        <input type="date" id="reportStartDate" name="startDate" value="<%= reportStartDate %>" required>
                    </div>
                    <div class="report-field">
                        <label for="reportEndDate">End date</label>
                        <input type="date" id="reportEndDate" name="endDate" value="<%= reportEndDate %>" required>
                    </div>
                    <button type="submit" class="btn-report-download">Download PDF Report</button>
                </form>
            </div>

            <!-- Recent Users Table (Excluding current admin) -->
            <div class="card">
                <div class="card-header">
                    <span class="card-title">Recent Users</span>
                    <a href="admin_users_list.jsp" class="card-action">View all →</a>
                </div>
                <div style="overflow-x: auto;">
                    <table class="pickup-table">
                        <thead>
                            <tr>
                                <th>User ID</th>
                                <th>Email Address</th>
                                <th>Role</th>
                                <th>Date Created</th>
                            </tr>
                        </thead>
                        <tbody>
                            <%
                                Connection conn2 = null;
                                PreparedStatement ps2 = null;
                                ResultSet rs2 = null;
                                try {
                                    conn2 = DBManager.getConnection();
                                    // Exclude current admin from recent users list
                                    String usersSql = "SELECT user_id, email_address, role, date_created FROM USERS WHERE user_id != ? ORDER BY user_id DESC LIMIT 10";
                                    ps2 = conn2.prepareStatement(usersSql);
                                    ps2.setInt(1, adminId);
                                    rs2 = ps2.executeQuery();
                                    
                                    boolean hasUsers = false;
                                    while (rs2.next()) {
                                        hasUsers = true;
                                        int uid = rs2.getInt("user_id");
                                        String email = rs2.getString("email_address");
                                        String role = rs2.getString("role");
                                        String dateCreated = rs2.getString("date_created");
                                        
                                        String roleClass = "";
                                        String displayRole = "";
                                        if ("household_user".equalsIgnoreCase(role)) {
                                            roleClass = "role-household";
                                            displayRole = "Household User";
                                        } else if ("recycle_center".equalsIgnoreCase(role)) {
                                            roleClass = "role-centre";
                                            displayRole = "Recycle Center";
                                        } else if ("admin".equalsIgnoreCase(role)) {
                                            roleClass = "role-admin";
                                            displayRole = "Admin";
                                        }
                            %>
                            <tr>
                                <td><a href="admin_view_user.jsp?userId=<%= uid %>&role=<%= role %>" class="user-link"><%= uid %></a></td>
                                <td><%= email %></td>
                                <td><span class="role-badge <%= roleClass %>"><%= displayRole %></span></td>
                                <td><%= dateCreated %></td>
                            </tr>
                            <%
                                    }
                                    if (!hasUsers) {
                            %>
                            <tr>
                                <td colspan="4" style="text-align: center; padding: 40px;">No other users found. You are the only admin.</td>
                            </tr>
                            <%
                                    }
                                    rs2.close();
                                    ps2.close();
                                    conn2.close();
                                } catch (Exception e) {
                                    e.printStackTrace();
                            %>
                            <tr>
                                <td colspan="4" style="text-align: center; color: red; padding: 40px;">Error loading users: <%= e.getMessage() %></td>
                            </tr>
                            <%
                                }
                            %>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Static page footer -->
            <footer class="page-footer">
                © 2026 <strong>Recycle Ekhaya</strong>. Built for a greener South Africa.
            </footer>
        </main>
    </div>

    <script>
        // Set greeting based on time of day
        const hour = new Date().getHours();
        const greeting = hour < 12 ? "Morning" : (hour < 18 ? "Afternoon" : "Evening");
        document.getElementById('greetingTime').textContent = greeting;
        
        // Set current date
        const options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
        document.getElementById('headerDate').textContent = new Date().toLocaleDateString('en-ZA', options);
        
        // Sidebar toggle functionality
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
