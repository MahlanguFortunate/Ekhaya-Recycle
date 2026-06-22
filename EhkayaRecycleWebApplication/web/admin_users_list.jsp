<%-- 
    File: admin_users_list.jsp
    Admin Users List Page with dynamic data from database
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    // SESSION CHECK - Redirect to login if not authenticated
    Integer adminId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
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
    
    // Handle delete action
    String deleteUserId = request.getParameter("deleteId");
    String deleteMessage = null;
    String deleteError = null;
    
    if (deleteUserId != null && !deleteUserId.isEmpty()) {
        int idToDelete = Integer.parseInt(deleteUserId);
        
        // Don't allow admin to delete themselves
        if (idToDelete == adminId) {
            deleteError = "You cannot delete your own admin account!";
        } else {
            Connection delConn = null;
            PreparedStatement delPs = null;
            
            try {
                delConn = DBManager.getConnection();
                delConn.setAutoCommit(false);
                
                // First, get the role to know which table to delete from
                String getRoleSql = "SELECT role FROM USERS WHERE user_id = ?";
                delPs = delConn.prepareStatement(getRoleSql);
                delPs.setInt(1, idToDelete);
                ResultSet rs = delPs.executeQuery();
                
                if (rs.next()) {
                    String role = rs.getString("role");
                    rs.close();
                    delPs.close();
                    
                    // Delete from role-specific table first (due to foreign keys)
                    if ("household_user".equalsIgnoreCase(role)) {
                        String deleteHouseholdSql = "DELETE FROM HOUSEHOLD_USER WHERE user_id = ?";
                        delPs = delConn.prepareStatement(deleteHouseholdSql);
                        delPs.setInt(1, idToDelete);
                        delPs.executeUpdate();
                        delPs.close();
                    } else if ("recycle_centre".equalsIgnoreCase(role) || "recycle_center".equalsIgnoreCase(role)) {
                        String deleteCentreSql = "DELETE FROM RECYCLE_CENTRE WHERE user_id = ?";
                        delPs = delConn.prepareStatement(deleteCentreSql);
                        delPs.setInt(1, idToDelete);
                        delPs.executeUpdate();
                        delPs.close();
                    } else if ("admin".equalsIgnoreCase(role)) {
                        String deleteAdminSql = "DELETE FROM ADMIN WHERE user_id = ?";
                        delPs = delConn.prepareStatement(deleteAdminSql);
                        delPs.setInt(1, idToDelete);
                        delPs.executeUpdate();
                        delPs.close();
                    }
                    
                    // Delete from WALLET if exists
                    String deleteWalletSql = "DELETE FROM WALLET WHERE household_user_id = ?";
                    delPs = delConn.prepareStatement(deleteWalletSql);
                    delPs.setInt(1, idToDelete);
                    delPs.executeUpdate();
                    delPs.close();
                    
                    // Finally delete from USERS table
                    String deleteUserSql = "DELETE FROM USERS WHERE user_id = ?";
                    delPs = delConn.prepareStatement(deleteUserSql);
                    delPs.setInt(1, idToDelete);
                    int rowsDeleted = delPs.executeUpdate();
                    delPs.close();
                    
                    if (rowsDeleted > 0) {
                        delConn.commit();
                        deleteMessage = "User successfully deleted!";
                    } else {
                        delConn.rollback();
                        deleteError = "Failed to delete user.";
                    }
                } else {
                    deleteError = "User not found.";
                }
                
            } catch (Exception e) {
                try {
                    if (delConn != null) delConn.rollback();
                } catch (SQLException ex) {}
                deleteError = "Error deleting user: " + e.getMessage();
                e.printStackTrace();
            } finally {
                try { if (delPs != null) delPs.close(); } catch (SQLException e) {}
                try { if (delConn != null) delConn.close(); } catch (SQLException e) {}
            }
        }
    }
    
    // Variables for pagination
    int currentPage = 1;
    int recordsPerPage = 15;
    String pageParam = request.getParameter("page");
    if (pageParam != null && !pageParam.isEmpty()) {
        currentPage = Integer.parseInt(pageParam);
    }
    int offset = (currentPage - 1) * recordsPerPage;
    int totalRecords = 0;
    int totalPages = 0;
    String query = request.getParameter("q");
    String searchTerm = query == null ? "" : query.trim();
    boolean hasSearch = !searchTerm.isEmpty();
    boolean numericSearch = searchTerm.matches("\\d+");
    String escapedSearchTerm = searchTerm.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    String pageSearchParam = hasSearch ? "&q=" + java.net.URLEncoder.encode(searchTerm, "UTF-8") : "";
%>

<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Recycle Ekhaya — Users List</title>

    <!-- Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />

    <!-- Local CSS file -->
    <link rel="stylesheet" href="styling/Household_user_dashboard.css" />

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
            padding: 28px 28px 40px;
            max-width: 1280px;
            width: 100%;
            margin: 0 auto;
        }

        .users-container {
            width: 100%;
            max-width: 1200px;
            margin: 0 auto;
        }

        .users-header {
            text-align: left;
            margin-bottom: 24px;
        }

        .users-header h1 {
            font-size: 28px;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 8px;
        }

        .users-header p {
            font-size: 14px;
            color: #cbd5e1;
        }

        .page-brand {
            display: flex;
            align-items: center;
            gap: 14px;
            margin-bottom: 18px;
        }

        .brand-title {
            font-size: 18px;
            font-weight: 700;
            color: #ffffff;
            margin: 0;
        }

        .brand-subtitle {
            font-size: 13px;
            color: #cbd5e1;
            margin: 0;
        }

        .table-responsive {
            overflow-x: auto;
        }

        .pickup-table {
            min-width: 800px;
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

        .pickup-table tr:hover {
            background: #f9faf7;
        }

        .action-buttons {
            display: flex;
            gap: 8px;
            flex-wrap: wrap;
        }

        .btn-view {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            border-radius: 20px;
            padding: 6px 14px;
            font-size: 12px;
            font-weight: 600;
            transition: all 0.2s ease;
            text-decoration: none;
            cursor: pointer;
            background: #2196f3;
            color: white;
            border: none;
        }

        .btn-view:hover {
            background: #1976d2;
            transform: translateY(-1px);
        }

        .btn-delete {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
            border-radius: 20px;
            padding: 6px 14px;
            font-size: 12px;
            font-weight: 600;
            transition: all 0.2s ease;
            text-decoration: none;
            cursor: pointer;
            background: #f44336;
            color: white;
            border: none;
        }

        .btn-delete:hover {
            background: #d32f2f;
            transform: translateY(-1px);
        }

        .back-link {
            display: inline-block;
            margin-top: 24px;
            color: #597226;
            text-decoration: none;
            font-size: 13px;
            font-weight: 600;
        }

        .back-link:hover {
            text-decoration: underline;
        }

        .pagination {
            display: flex;
            justify-content: center;
            gap: 10px;
            margin-top: 20px;
            padding: 20px;
        }

        .pagination a {
            padding: 8px 14px;
            background: #597226;
            color: white;
            text-decoration: none;
            border-radius: 6px;
            font-size: 13px;
        }

        .pagination a:hover {
            background: #3d5119;
        }

        .pagination .active {
            background: #3d5119;
        }

        .role-badge {
            display: inline-block;
            padding: 4px 10px;
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

        .role-admin {
            background: #fff3e0;
            color: #ff9800;
        }

        .alert-success {
            background: #e8f5e9;
            color: #2e7d32;
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }

        .alert-error {
            background: #ffebee;
            color: #c62828;
            padding: 12px 16px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }
        .search-panel {
            background: #ffffff;
            border-radius: 12px;
            padding: 16px;
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
        .btn-search {
            border: none;
            border-radius: 8px;
            background: #597226;
            color: #fff;
            font-size: 13px;
            font-weight: 600;
            padding: 12px 16px;
            cursor: pointer;
        }
        .btn-search:hover {
            background: #3d5119;
        }
        .clear-search {
            color: #597226;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
        }
        .modal-backdrop {
            position: fixed;
            inset: 0;
            background: rgba(17, 24, 39, 0.52);
            display: none;
            align-items: center;
            justify-content: center;
            padding: 20px;
            z-index: 1000;
        }
        .modal-backdrop.is-open {
            display: flex;
        }
        .confirm-dialog {
            width: min(440px, 100%);
            background: #ffffff;
            border-radius: 12px;
            box-shadow: 0 24px 60px rgba(17, 24, 39, 0.24);
            overflow: hidden;
        }
        .confirm-dialog-header {
            padding: 18px 20px;
            border-bottom: 1px solid #edf2e7;
        }
        .confirm-dialog-title {
            margin: 0;
            color: #1f2937;
            font-size: 18px;
            font-weight: 800;
        }
        .confirm-dialog-body {
            padding: 18px 20px 4px;
            color: #4b5563;
            font-size: 14px;
            line-height: 1.5;
        }
        .confirm-user {
            margin-top: 12px;
            padding: 12px;
            background: #f8faf5;
            border: 1px solid #dfe8d5;
            border-radius: 8px;
            color: #1f2937;
            overflow-wrap: anywhere;
        }
        .confirm-dialog-actions {
            display: flex;
            justify-content: flex-end;
            gap: 10px;
            padding: 18px 20px 20px;
        }
        .modal-btn {
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 13px;
            font-weight: 700;
            min-height: 40px;
            padding: 0 16px;
        }
        .modal-btn-cancel {
            background: #eef2e8;
            color: #334155;
        }
        .modal-btn-delete {
            background: #dc2626;
            color: #ffffff;
        }
        .modal-btn-delete:hover {
            background: #b91c1c;
        }
    </style>
</head>

<body>
    <div class="main no-sidebar">
        <main class="content">
            <div class="users-container">
                <div class="page-brand">
                    <div class="logo-icon">♻️</div>
                    <div>
                        <h2 class="brand-title">Recycle Ekhaya</h2>
                        <p class="brand-subtitle">Users List</p>
                    </div>
                </div>

                <div class="users-header">
                    <h1><%= hasSearch ? "Search Users" : "All Registered Users" %></h1>
                    <p>View and manage all user accounts in the system.</p>
                </div>

                <% if (deleteMessage != null) { %>
                    <div class="alert-success">
                        ✓ <%= deleteMessage %>
                    </div>
                <% } %>
                
                <% if (deleteError != null) { %>
                    <div class="alert-error">
                        ✗ <%= deleteError %>
                    </div>
                <% } %>

                <div class="search-panel">
                    <form action="admin_users_list.jsp" method="GET" class="search-form">
                        <input type="search" name="q" class="search-input" value="<%= escapedSearchTerm %>"
                               placeholder="Search by user ID, name, email, or role" required>
                        <button type="submit" class="btn-search">Search</button>
                        <% if (hasSearch) { %>
                            <a href="admin_users_list.jsp" class="clear-search">Clear search</a>
                        <% } %>
                    </form>
                </div>

                <div class="card">
                    <div class="card-header">
                        <span class="card-title"><%= hasSearch ? "Search Results for \"" + escapedSearchTerm + "\"" : "Users" %></span>
                        <a href="admin_users_list.jsp" class="card-action">Refresh →</a>
                    </div>
                    <div class="table-responsive">
                        <table class="pickup-table">
                            <thead>
                                <tr>
                                    <th>User ID</th>
                                    <th>Email Address</th>
                                    <th>Role</th>
                                    <th>Date Created</th>
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
                                        
                                        String searchWhere = "";
                                        String likeTerm = "%" + searchTerm + "%";
                                        if (hasSearch) {
                                            searchWhere = " WHERE "
                                                    + (numericSearch ? "u.user_id = ? OR " : "")
                                                    + "LOWER(u.email_address) LIKE LOWER(?) OR "
                                                    + "LOWER(u.role) LIKE LOWER(?) OR "
                                                    + "LOWER(hu.first_name) LIKE LOWER(?) OR "
                                                    + "LOWER(hu.last_name) LIKE LOWER(?) OR "
                                                    + "LOWER(CONCAT(hu.first_name, ' ', hu.last_name)) LIKE LOWER(?) OR "
                                                    + "LOWER(rc.centre_name) LIKE LOWER(?)";
                                        }

                                        // Get total count for pagination
                                        String countSql = "SELECT COUNT(*) as total FROM USERS u "
                                                + "LEFT JOIN HOUSEHOLD_USER hu ON u.user_id = hu.user_id "
                                                + "LEFT JOIN RECYCLE_CENTRE rc ON u.user_id = rc.user_id "
                                                + searchWhere;
                                        ps = conn.prepareStatement(countSql);
                                        int countParam = 1;
                                        if (hasSearch) {
                                            if (numericSearch) {
                                                ps.setInt(countParam++, Integer.parseInt(searchTerm));
                                            }
                                            ps.setString(countParam++, likeTerm);
                                            ps.setString(countParam++, likeTerm);
                                            ps.setString(countParam++, likeTerm);
                                            ps.setString(countParam++, likeTerm);
                                            ps.setString(countParam++, likeTerm);
                                            ps.setString(countParam++, likeTerm);
                                        }
                                        rs = ps.executeQuery();
                                        if (rs.next()) {
                                            totalRecords = rs.getInt("total");
                                            totalPages = (int) Math.ceil((double) totalRecords / recordsPerPage);
                                        }
                                        rs.close();
                                        ps.close();
                                        
                                        // Get users with pagination
                                        String usersSql = "SELECT u.user_id, u.email_address, u.role, u.date_created "
                                                + "FROM USERS u "
                                                + "LEFT JOIN HOUSEHOLD_USER hu ON u.user_id = hu.user_id "
                                                + "LEFT JOIN RECYCLE_CENTRE rc ON u.user_id = rc.user_id "
                                                + searchWhere
                                                + " ORDER BY u.user_id DESC LIMIT ? OFFSET ?";
                                        ps = conn.prepareStatement(usersSql);
                                        int usersParam = 1;
                                        if (hasSearch) {
                                            if (numericSearch) {
                                                ps.setInt(usersParam++, Integer.parseInt(searchTerm));
                                            }
                                            ps.setString(usersParam++, likeTerm);
                                            ps.setString(usersParam++, likeTerm);
                                            ps.setString(usersParam++, likeTerm);
                                            ps.setString(usersParam++, likeTerm);
                                            ps.setString(usersParam++, likeTerm);
                                            ps.setString(usersParam++, likeTerm);
                                        }
                                        ps.setInt(usersParam++, recordsPerPage);
                                        ps.setInt(usersParam++, offset);
                                        rs = ps.executeQuery();
                                        
                                        boolean hasUsers = false;
                                        while (rs.next()) {
                                            hasUsers = true;
                                            int uid = rs.getInt("user_id");
                                            String email = rs.getString("email_address");
                                            String role = rs.getString("role");
                                            String dateCreated = rs.getString("date_created");
                                            
                                            String roleClass = "";
                                            if ("household_user".equalsIgnoreCase(role)) {
                                                roleClass = "role-household";
                                            } else if ("recycle_centre".equalsIgnoreCase(role)) {
                                                roleClass = "role-centre";
                                            } else if ("recycle_center".equalsIgnoreCase(role)) {
                                                roleClass = "role-centre";
                                            } else if ("admin".equalsIgnoreCase(role)) {
                                                roleClass = "role-admin";
                                            }
                                %>
                                <tr>
                                    <td><a href="admin_view_user.jsp?userId=<%= uid %>&role=<%= role %>" style="color: #333; text-decoration: none; font-weight: 500;"><%= uid %></a></td>
                                    <td><%= email %></td>
                                    <td><span class="role-badge <%= roleClass %>"><%= role %></span></td>
                                    <td><%= dateCreated %></td>
                                    <td class="action-cell">
                                        <div class="action-buttons">
                                            <!-- View Details Button -->
                                            <a href="admin_view_user.jsp?userId=<%= uid %>&role=<%= role %>" class="btn-view">👁️ View Details</a>
                                            
                                            <!-- Delete Button (don't allow deleting self) -->
                                            <% if (uid != adminId) { %>
                                                <a href="javascript:void(0);" onclick="confirmDelete(<%= uid %>, '<%= email %>')" class="btn-delete">🗑️ Delete</a>
                                            <% } else { %>
                                                <button class="btn-delete" disabled style="opacity: 0.5; cursor: not-allowed;">🗑️ Delete</button>
                                            <% } %>
                                        </div>
                                    </td>
                                </tr>
                                <%
                                        }
                                        if (!hasUsers) {
                                %>
                                <tr>
                                    <td colspan="5" style="text-align: center;"><%= hasSearch ? "No users matched your search." : "No users found" %></td>
                                </tr>
                                <%
                                        }
                                        rs.close();
                                        ps.close();
                                        conn.close();
                                    } catch (Exception e) {
                                        e.printStackTrace();
                                %>
                                <tr>
                                    <td colspan="5" style="text-align: center; color: red;">Error loading users: <%= e.getMessage() %></td>
                                </tr>
                                <%
                                    }
                                %>
                            </tbody>
                        </table>
                    </div>
                    
                    <!-- Pagination -->
                    <% if (totalPages > 1) { %>
                    <div class="pagination">
                        <% if (currentPage > 1) { %>
                            <a href="admin_users_list.jsp?page=<%= currentPage - 1 %>">← Previous</a>
                        <% } %>
                        
                        <% for (int i = 1; i <= totalPages; i++) { %>
                            <% if (i == currentPage) { %>
                                <a href="admin_users_list.jsp?page=<%= i %><%= pageSearchParam %>" class="active"><%= i %></a>
                            <% } else { %>
                                <a href="admin_users_list.jsp?page=<%= i %><%= pageSearchParam %>"><%= i %></a>
                            <% } %>
                        <% } %>
                        
                        <% if (currentPage < totalPages) { %>
                            <a href="admin_users_list.jsp?page=<%= currentPage + 1 %>">Next →</a>
                        <% } %>
                    </div>
                    <% } %>
                </div>
                
                <a href="admin_dashboard.jsp" class="back-link">← Back to Dashboard</a>
            </div>
        </main>
    </div>

    <div class="modal-backdrop" id="deleteConfirmModal" aria-hidden="true">
        <div class="confirm-dialog" role="dialog" aria-modal="true" aria-labelledby="deleteConfirmTitle">
            <div class="confirm-dialog-header">
                <h2 class="confirm-dialog-title" id="deleteConfirmTitle">Delete user account?</h2>
            </div>
            <div class="confirm-dialog-body">
                <p>This action cannot be undone. The selected user and related account records will be removed.</p>
                <div class="confirm-user" id="deleteConfirmUser"></div>
            </div>
            <div class="confirm-dialog-actions">
                <button type="button" class="modal-btn modal-btn-cancel" id="deleteCancelBtn">Cancel</button>
                <button type="button" class="modal-btn modal-btn-delete" id="deleteConfirmBtn">Delete user</button>
            </div>
        </div>
    </div>

    <script>
        const deleteModal = document.getElementById('deleteConfirmModal');
        const deleteUserText = document.getElementById('deleteConfirmUser');
        const deleteCancelBtn = document.getElementById('deleteCancelBtn');
        const deleteConfirmBtn = document.getElementById('deleteConfirmBtn');
        let selectedDeleteUserId = null;

        function confirmDelete(userId, email) {
            selectedDeleteUserId = userId;
            deleteUserText.textContent = email + ' (ID: ' + userId + ')';
            deleteModal.classList.add('is-open');
            deleteModal.setAttribute('aria-hidden', 'false');
            deleteConfirmBtn.focus();
        }

        function closeDeleteModal() {
            selectedDeleteUserId = null;
            deleteModal.classList.remove('is-open');
            deleteModal.setAttribute('aria-hidden', 'true');
        }

        deleteCancelBtn.addEventListener('click', closeDeleteModal);
        deleteModal.addEventListener('click', function (event) {
            if (event.target === deleteModal) {
                closeDeleteModal();
            }
        });
        document.addEventListener('keydown', function (event) {
            if (event.key === 'Escape' && deleteModal.classList.contains('is-open')) {
                closeDeleteModal();
            }
        });
        deleteConfirmBtn.addEventListener('click', function () {
            if (selectedDeleteUserId) {
                window.location.href = 'admin_users_list.jsp?deleteId=' + encodeURIComponent(selectedDeleteUserId);
            }
        });
    </script>
</body>

</html>
