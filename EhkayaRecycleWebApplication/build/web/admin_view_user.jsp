<%--
    File: admin_view_user.jsp
    Admin account details page
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    Integer adminId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userRole = (String) session.getAttribute("userRole");

    if (adminId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }

    if (!"admin".equalsIgnoreCase(userRole)) {
        response.sendRedirect("household_user_dashboard.jsp");
        return;
    }

    String firstName = userName;
    if (userName != null && userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }

    int viewedUserId = -1;
    String userIdParam = request.getParameter("userId");
    String errorMessage = null;

    if (userIdParam == null || userIdParam.trim().isEmpty()) {
        errorMessage = "No user account was selected.";
    } else {
        try {
            viewedUserId = Integer.parseInt(userIdParam.trim());
        } catch (NumberFormatException e) {
            errorMessage = "Invalid user account selected.";
        }
    }

    boolean foundUser = false;
    String email = "";
    String role = "";
    String dateCreated = "";
    String displayName = "";
    String phoneNumber = "";
    String streetAddress = "";
    String city = "";
    String province = "";
    String postalCode = "";
    String latitude = "";
    String longitude = "";

    if (errorMessage == null) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        try {
            conn = DBManager.getConnection();
            String sql = "SELECT u.user_id, u.email_address, u.role, u.date_created, "
                    + "hu.first_name, hu.last_name, hu.phone_number AS household_phone, "
                    + "hu.street_address AS household_street, hu.city AS household_city, "
                    + "hu.province AS household_province, hu.postal_code AS household_postal, "
                    + "hu.latitude AS household_latitude, hu.longitude AS household_longitude, "
                    + "rc.centre_name, rc.phone_number AS centre_phone, "
                    + "rc.street_address AS centre_street, rc.city AS centre_city, "
                    + "rc.province AS centre_province, rc.postal_code AS centre_postal, "
                    + "rc.latitude AS centre_latitude, rc.longitude AS centre_longitude "
                    + "FROM USERS u "
                    + "LEFT JOIN HOUSEHOLD_USER hu ON u.user_id = hu.user_id "
                    + "LEFT JOIN RECYCLE_CENTRE rc ON u.user_id = rc.user_id "
                    + "WHERE u.user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, viewedUserId);
            rs = ps.executeQuery();

            if (rs.next()) {
                foundUser = true;
                email = rs.getString("email_address") != null ? rs.getString("email_address") : "";
                role = rs.getString("role") != null ? rs.getString("role") : "";
                dateCreated = rs.getString("date_created") != null ? rs.getString("date_created") : "";

                if ("household_user".equalsIgnoreCase(role)) {
                    String fn = rs.getString("first_name") != null ? rs.getString("first_name") : "";
                    String ln = rs.getString("last_name") != null ? rs.getString("last_name") : "";
                    displayName = (fn + " " + ln).trim();
                    phoneNumber = rs.getString("household_phone") != null ? rs.getString("household_phone") : "";
                    streetAddress = rs.getString("household_street") != null ? rs.getString("household_street") : "";
                    city = rs.getString("household_city") != null ? rs.getString("household_city") : "";
                    province = rs.getString("household_province") != null ? rs.getString("household_province") : "";
                    postalCode = rs.getString("household_postal") != null ? rs.getString("household_postal") : "";
                    latitude = rs.getString("household_latitude") != null ? rs.getString("household_latitude") : "";
                    longitude = rs.getString("household_longitude") != null ? rs.getString("household_longitude") : "";
                } else if ("recycle_centre".equalsIgnoreCase(role) || "recycle_center".equalsIgnoreCase(role)) {
                    displayName = rs.getString("centre_name") != null ? rs.getString("centre_name") : "";
                    phoneNumber = rs.getString("centre_phone") != null ? rs.getString("centre_phone") : "";
                    streetAddress = rs.getString("centre_street") != null ? rs.getString("centre_street") : "";
                    city = rs.getString("centre_city") != null ? rs.getString("centre_city") : "";
                    province = rs.getString("centre_province") != null ? rs.getString("centre_province") : "";
                    postalCode = rs.getString("centre_postal") != null ? rs.getString("centre_postal") : "";
                    latitude = rs.getString("centre_latitude") != null ? rs.getString("centre_latitude") : "";
                    longitude = rs.getString("centre_longitude") != null ? rs.getString("centre_longitude") : "";
                } else if ("admin".equalsIgnoreCase(role)) {
                    displayName = "Administrator";
                }
            } else {
                errorMessage = "User account was not found.";
            }
        } catch (Exception e) {
            errorMessage = "Error loading user account: " + e.getMessage();
            e.printStackTrace();
        } finally {
            try { if (rs != null) rs.close(); } catch (SQLException e) {}
            try { if (ps != null) ps.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }

    if (displayName == null || displayName.trim().isEmpty()) {
        displayName = email != null && !email.isEmpty() ? email : "User " + viewedUserId;
    }

    String roleClass = "";
    String displayRole = role;
    if ("household_user".equalsIgnoreCase(role)) {
        roleClass = "role-household";
        displayRole = "Household User";
    } else if ("recycle_centre".equalsIgnoreCase(role) || "recycle_center".equalsIgnoreCase(role)) {
        roleClass = "role-centre";
        displayRole = "Recycle Centre";
    } else if ("admin".equalsIgnoreCase(role)) {
        roleClass = "role-admin";
        displayRole = "Admin";
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Recycle Ekhaya - Account Details</title>
    <link rel="preconnect" href="https://fonts.googleapis.com" />
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
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
            max-width: 980px;
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
        .details-header {
            display: flex;
            align-items: flex-start;
            justify-content: space-between;
            gap: 18px;
            margin-bottom: 20px;
        }
        .details-header h1 {
            color: #ffffff;
            font-size: 28px;
            margin: 0 0 8px;
        }
        .details-header p {
            color: #cbd5e1;
            font-size: 14px;
            margin: 0;
        }
        .action-buttons {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            justify-content: flex-end;
        }
        .btn {
            display: inline-flex;
            align-items: center;
            justify-content: center;
            border-radius: 8px;
            padding: 10px 14px;
            font-size: 13px;
            font-weight: 600;
            text-decoration: none;
            border: none;
            cursor: pointer;
        }
        .btn-back {
            background: #ffffff;
            color: #334155;
        }
        .btn-delete {
            background: #f44336;
            color: #ffffff;
        }
        .btn-delete.disabled {
            opacity: 0.55;
            cursor: not-allowed;
        }
        .card {
            background: #ffffff;
            border-radius: 12px;
            padding: 22px;
            margin-bottom: 18px;
        }
        .section-title {
            color: #1f2937;
            font-size: 16px;
            font-weight: 700;
            margin: 0 0 16px;
        }
        .details-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 14px 18px;
        }
        .detail-item {
            border: 1px solid #eef2f6;
            border-radius: 8px;
            padding: 12px;
            min-width: 0;
        }
        .detail-label {
            color: #667085;
            display: block;
            font-size: 12px;
            font-weight: 600;
            margin-bottom: 6px;
        }
        .detail-value {
            color: #111827;
            font-size: 14px;
            overflow-wrap: anywhere;
        }
        .role-badge {
            display: inline-block;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 700;
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
        .alert-error {
            background: #ffebee;
            color: #c62828;
            padding: 14px 16px;
            border-radius: 8px;
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
        @media (max-width: 720px) {
            .details-header {
                display: block;
            }
            .action-buttons {
                justify-content: flex-start;
                margin-top: 16px;
            }
            .details-grid {
                grid-template-columns: 1fr;
            }
        }
    </style>
</head>
<body>
    <div class="main no-sidebar">
        <main class="content">
            <div class="page-brand">
                <div class="logo-icon">R</div>
                <div>
                    <h2 class="brand-title">Recycle Ekhaya</h2>
                    <p class="brand-subtitle">Account Details</p>
                </div>
            </div>

            <% if (errorMessage != null) { %>
                <div class="alert-error"><%= errorMessage %></div>
                <p><a href="admin_users_list.jsp" class="btn btn-back" style="margin-top: 18px;">Back to Users</a></p>
            <% } else { %>
                <div class="details-header">
                    <div>
                        <h1><%= displayName %></h1>
                        <p>User ID <%= viewedUserId %> - <span class="role-badge <%= roleClass %>"><%= displayRole %></span></p>
                    </div>
                    <div class="action-buttons">
                        <a href="admin_users_list.jsp" class="btn btn-back">Back to Users</a>
                        <% if (viewedUserId != adminId) { %>
                            <a href="javascript:void(0);" onclick="confirmDelete(<%= viewedUserId %>, '<%= email.replace("'", "\\'") %>')" class="btn btn-delete">Delete Account</a>
                        <% } else { %>
                            <span class="btn btn-delete disabled">Delete Account</span>
                        <% } %>
                    </div>
                </div>

                <div class="card">
                    <h2 class="section-title">Login Account</h2>
                    <div class="details-grid">
                        <div class="detail-item">
                            <span class="detail-label">User ID</span>
                            <span class="detail-value"><%= viewedUserId %></span>
                        </div>
                        <div class="detail-item">
                            <span class="detail-label">Email Address</span>
                            <span class="detail-value"><%= email %></span>
                        </div>
                        <div class="detail-item">
                            <span class="detail-label">Role</span>
                            <span class="detail-value"><%= displayRole %></span>
                        </div>
                        <div class="detail-item">
                            <span class="detail-label">Date Created</span>
                            <span class="detail-value"><%= dateCreated == null || dateCreated.isEmpty() ? "N/A" : dateCreated %></span>
                        </div>
                    </div>
                </div>

                <% if (!"admin".equalsIgnoreCase(role)) { %>
                    <div class="card">
                        <h2 class="section-title"><%= "household_user".equalsIgnoreCase(role) ? "Household Profile" : "Recycle Centre Profile" %></h2>
                        <div class="details-grid">
                            <div class="detail-item">
                                <span class="detail-label">Name</span>
                                <span class="detail-value"><%= displayName %></span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-label">Phone Number</span>
                                <span class="detail-value"><%= phoneNumber == null || phoneNumber.isEmpty() ? "N/A" : phoneNumber %></span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-label">Street Address</span>
                                <span class="detail-value"><%= streetAddress == null || streetAddress.isEmpty() ? "N/A" : streetAddress %></span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-label">City</span>
                                <span class="detail-value"><%= city == null || city.isEmpty() ? "N/A" : city %></span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-label">Province</span>
                                <span class="detail-value"><%= province == null || province.isEmpty() ? "N/A" : province %></span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-label">Postal Code</span>
                                <span class="detail-value"><%= postalCode == null || postalCode.isEmpty() ? "N/A" : postalCode %></span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-label">Latitude</span>
                                <span class="detail-value"><%= latitude == null || latitude.isEmpty() ? "N/A" : latitude %></span>
                            </div>
                            <div class="detail-item">
                                <span class="detail-label">Longitude</span>
                                <span class="detail-value"><%= longitude == null || longitude.isEmpty() ? "N/A" : longitude %></span>
                            </div>
                        </div>
                    </div>
                <% } %>
            <% } %>
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
