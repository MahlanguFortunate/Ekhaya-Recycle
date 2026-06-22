<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    Integer centreId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userRole = (String) session.getAttribute("userRole");

    if (centreId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }

    if (!"recycle_center".equalsIgnoreCase(userRole) && !"recycle_centre".equalsIgnoreCase(userRole)) {
        response.sendRedirect("login.html");
        return;
    }

    String query = request.getParameter("q");
    String searchTerm = query == null ? "" : query.trim();
    String escapedSearchTerm = searchTerm.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    boolean hasSearch = !searchTerm.isEmpty();
    boolean numericSearch = searchTerm.matches("\\d+");
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - User Search</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="styling/Household_user_dashboard.css">
    <style>
        body {
            background: #1a1d21;
            font-family: 'Inter', sans-serif;
            min-height: 100vh;
        }
        .main.no-sidebar {
            margin-left: 0;
        }
        .content {
            max-width: 1180px;
            margin: 0 auto;
            padding: 28px;
        }
        .page-brand {
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 18px;
        }
        .brand-title {
            color: #ffffff;
            font-size: 18px;
            font-weight: 700;
            margin: 0;
        }
        .brand-subtitle {
            color: #cbd5e1;
            font-size: 13px;
            margin: 0;
        }
        .search-panel {
            background: #ffffff;
            border-radius: 12px;
            padding: 18px;
            margin-bottom: 20px;
        }
        .search-form {
            display: flex;
            gap: 10px;
            align-items: center;
        }
        .search-input {
            flex: 1;
            min-height: 44px;
            border: 1px solid #d9e0d2;
            border-radius: 8px;
            padding: 0 14px;
            font-size: 14px;
        }
        .btn-search,
        .btn-view {
            border: none;
            border-radius: 8px;
            background: #597226;
            color: #fff;
            font-size: 13px;
            font-weight: 600;
            padding: 12px 16px;
            text-decoration: none;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            justify-content: center;
        }
        .btn-search:hover,
        .btn-view:hover {
            background: #3d5119;
        }
        .back-link {
            display: inline-block;
            margin-top: 18px;
            color: #dbe8c9;
            text-decoration: none;
            font-size: 13px;
            font-weight: 600;
        }
        .table-responsive {
            overflow-x: auto;
        }
        .pickup-table {
            min-width: 900px;
            width: 100%;
            border-collapse: collapse;
        }
        .pickup-table th {
            text-align: left;
            padding: 12px 16px;
            background: #f9faf7;
            color: #597226;
            font-size: 12px;
            font-weight: 600;
            border-bottom: 1px solid #eef2f6;
        }
        .pickup-table td {
            padding: 12px 16px;
            border-bottom: 1px solid #eef2f6;
            color: #333;
            font-size: 13px;
        }
        .empty-state {
            background: #ffffff;
            border-radius: 12px;
            padding: 24px;
            color: #333;
            text-align: center;
        }
        .muted {
            color: #667085;
            font-size: 12px;
        }
    </style>
</head>
<body>
<div class="main no-sidebar">
    <main class="content">
        <div class="page-brand">
            <div class="logo-icon">♻</div>
            <div>
                <h2 class="brand-title">Recycle Ekhaya</h2>
                <p class="brand-subtitle">Household User Search</p>
            </div>
        </div>

        <div class="search-panel">
            <form action="recycle_center_user_search.jsp" method="GET" class="search-form">
                <input type="search" name="q" class="search-input" value="<%= escapedSearchTerm %>"
                       placeholder="Search by user ID, name, or email" required>
                <button type="submit" class="btn-search">Search</button>
            </form>
        </div>

        <% if (!hasSearch) { %>
            <div class="empty-state">Enter a household user ID, name, or email address to search.</div>
        <% } else { %>
            <div class="card">
                <div class="card-header">
                    <span class="card-title">Search Results for "<%= escapedSearchTerm %>"</span>
                    <a href="recycle_center_dashboard.jsp" class="card-action">Dashboard →</a>
                </div>
                <div class="table-responsive">
                    <table class="pickup-table">
                        <thead>
                            <tr>
                                <th>User ID</th>
                                <th>Name</th>
                                <th>Email</th>
                                <th>Phone</th>
                                <th>Location</th>
                                <th>Requests With Centre</th>
                                <th>Completed</th>
                                <th>Actions</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            Connection conn = null;
                            PreparedStatement ps = null;
                            ResultSet rs = null;
                            boolean hasResults = false;

                            try {
                                conn = DBManager.getConnection();
                                String likeTerm = "%" + searchTerm + "%";
                                String sql = "SELECT hu.user_id, hu.first_name, hu.last_name, hu.phone_number, "
                                        + "hu.city, hu.province, u.email_address, "
                                        + "COUNT(pr.request_id) AS centre_requests, "
                                        + "SUM(CASE WHEN pr.request_status = 'completed' THEN 1 ELSE 0 END) AS completed_requests "
                                        + "FROM HOUSEHOLD_USER hu "
                                        + "JOIN USERS u ON hu.user_id = u.user_id "
                                        + "LEFT JOIN PICKUP_REQUEST pr ON hu.user_id = pr.household_user_id AND pr.centre_id = ? "
                                        + "WHERE u.role = 'household_user' AND ("
                                        + (numericSearch ? "hu.user_id = ? OR " : "")
                                        + "LOWER(hu.first_name) LIKE LOWER(?) OR "
                                        + "LOWER(hu.last_name) LIKE LOWER(?) OR "
                                        + "LOWER(CONCAT(hu.first_name, ' ', hu.last_name)) LIKE LOWER(?) OR "
                                        + "LOWER(u.email_address) LIKE LOWER(?)) "
                                        + "GROUP BY hu.user_id, hu.first_name, hu.last_name, hu.phone_number, hu.city, hu.province, u.email_address "
                                        + "ORDER BY hu.first_name, hu.last_name LIMIT 25";
                                ps = conn.prepareStatement(sql);
                                int param = 1;
                                ps.setInt(param++, centreId);
                                if (numericSearch) {
                                    ps.setInt(param++, Integer.parseInt(searchTerm));
                                }
                                ps.setString(param++, likeTerm);
                                ps.setString(param++, likeTerm);
                                ps.setString(param++, likeTerm);
                                ps.setString(param++, likeTerm);
                                rs = ps.executeQuery();

                                while (rs.next()) {
                                    hasResults = true;
                                    int householdId = rs.getInt("user_id");
                                    String fullName = rs.getString("first_name") + " " + rs.getString("last_name");
                                    String email = rs.getString("email_address");
                                    String phone = rs.getString("phone_number");
                                    String city = rs.getString("city");
                                    String province = rs.getString("province");
                                    int centreRequests = rs.getInt("centre_requests");
                                    int completedRequests = rs.getInt("completed_requests");
                        %>
                            <tr>
                                <td><%= householdId %></td>
                                <td><%= fullName %></td>
                                <td><%= email %></td>
                                <td><%= phone != null ? phone : "N/A" %></td>
                                <td><%= city != null ? city : "N/A" %>, <%= province != null ? province : "N/A" %></td>
                                <td><%= centreRequests %></td>
                                <td><%= completedRequests %></td>
                                <td>
                                    <% if (centreRequests > 0) { %>
                                        <a class="btn-view" href="centre_requests.jsp?householdId=<%= householdId %>">View Requests</a>
                                    <% } else { %>
                                        <span class="muted">No centre requests yet</span>
                                    <% } %>
                                </td>
                            </tr>
                        <%
                                }

                                if (!hasResults) {
                        %>
                            <tr>
                                <td colspan="8" style="text-align:center;">No household users matched your search.</td>
                            </tr>
                        <%
                                }
                            } catch (Exception e) {
                                e.printStackTrace();
                        %>
                            <tr>
                                <td colspan="8" style="text-align:center;color:red;">Error searching users: <%= e.getMessage() %></td>
                            </tr>
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
        <% } %>

        <a href="recycle_center_dashboard.jsp" class="back-link">← Back to Dashboard</a>
    </main>
</div>
</body>
</html>
