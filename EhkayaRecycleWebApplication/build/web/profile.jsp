<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.sql.*"%>
<%@page import="za.ac.tut.db.DBManager"%>

<%
    // SESSION CHECK - Redirect to login if not authenticated
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");
    String userRole = (String) session.getAttribute("userRole");
    
    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }
    
    // Get user details from database
    String firstName = "";
    String lastName = "";
    String phoneNumber = "";
    String streetAddress = "";
    String city = "";
    String province = "";
    String postalCode = "";
    String memberSince = "";
    
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        conn = DBManager.getConnection();
        
        // Get user details based on role
        if ("household_user".equalsIgnoreCase(userRole)) {
            String sql = "SELECT h.first_name, h.last_name, h.phone_number, h.street_address, h.city, h.province, h.postal_code, u.date_created "
                       + "FROM HOUSEHOLD_USER h "
                       + "JOIN USERS u ON h.user_id = u.user_id "
                       + "WHERE h.user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            if (rs.next()) {
                firstName = rs.getString("first_name") != null ? rs.getString("first_name") : "";
                lastName = rs.getString("last_name") != null ? rs.getString("last_name") : "";
                phoneNumber = rs.getString("phone_number") != null ? rs.getString("phone_number") : "";
                streetAddress = rs.getString("street_address") != null ? rs.getString("street_address") : "";
                city = rs.getString("city") != null ? rs.getString("city") : "";
                province = rs.getString("province") != null ? rs.getString("province") : "";
                postalCode = rs.getString("postal_code") != null ? rs.getString("postal_code") : "";
                memberSince = rs.getString("date_created") != null ? rs.getString("date_created") : "";
            }
        } else if ("recycle_center".equalsIgnoreCase(userRole) || "recycle_centre".equalsIgnoreCase(userRole)) {
            String sql = "SELECT rc.centre_name, rc.phone_number, rc.street_address, rc.city, rc.province, rc.postal_code, u.date_created "
                       + "FROM RECYCLE_CENTRE rc "
                       + "JOIN USERS u ON rc.user_id = u.user_id "
                       + "WHERE rc.user_id = ?";
            ps = conn.prepareStatement(sql);
            ps.setInt(1, userId);
            rs = ps.executeQuery();
            if (rs.next()) {
                firstName = rs.getString("centre_name") != null ? rs.getString("centre_name") : "";
                lastName = "";
                phoneNumber = rs.getString("phone_number") != null ? rs.getString("phone_number") : "";
                streetAddress = rs.getString("street_address") != null ? rs.getString("street_address") : "";
                city = rs.getString("city") != null ? rs.getString("city") : "";
                province = rs.getString("province") != null ? rs.getString("province") : "";
                postalCode = rs.getString("postal_code") != null ? rs.getString("postal_code") : "";
                memberSince = rs.getString("date_created") != null ? rs.getString("date_created") : "";
            }
        }
        
    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) {}
        try { if (ps != null) ps.close(); } catch (SQLException e) {}
        try { if (conn != null) conn.close(); } catch (SQLException e) {}
    }
    
    String fullName = firstName + " " + lastName;
    String initials = "";
    if (firstName.length() > 0) {
        initials = firstName.substring(0, 1).toUpperCase();
        if (lastName.length() > 0) {
            initials += lastName.substring(0, 1).toUpperCase();
        }
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Profile — Recycle Ekhaya</title>
    <link rel="stylesheet" href="styling/profile.css" />
    <style>
        .btn-loader {
            display: inline-block;
            width: 16px;
            height: 16px;
            border: 2px solid #fff;
            border-radius: 50%;
            border-top-color: transparent;
            animation: spin 0.6s linear infinite;
            margin-left: 8px;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        .toast.success { background: #d4edda; color: #155724; border-color: #c3e6cb; }
        .toast.error { background: #f8d7da; color: #721c24; border-color: #f5c6cb; }
        .field-input.is-invalid { border-color: #dc3545; }
        .field-error { color: #dc3545; font-size: 12px; margin-top: 4px; display: block; }
        .modal-overlay[hidden] { display: none; }
        .modal-overlay {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0,0,0,0.5);
            display: flex;
            align-items: center;
            justify-content: center;
            z-index: 1000;
        }
        .modal {
            background: white;
            border-radius: 8px;
            padding: 24px;
            max-width: 400px;
            width: 90%;
        }
        .modal-title { font-size: 20px; margin-bottom: 12px; }
        .modal-body { margin-bottom: 20px; color: #666; }
        .modal-actions { display: flex; justify-content: flex-end; gap: 10px; }
        .role-badge {
            display: inline-block;
            padding: 6px 14px;
            background: #e8f5e9;
            color: #2e7d32;
            border-radius: 20px;
            font-size: 12px;
            font-weight: 500;
            text-transform: capitalize;
        }
    </style>
</head>
<body>

    <!-- Top Bar -->
    <header class="topbar">
        <button class="back-btn" id="backBtn" onclick="goToDashboard()">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <polyline points="15 18 9 12 15 6"/>
            </svg>
            Dashboard
        </button>
        <span class="topbar-title">Account Management</span>
    </header>

    <!-- Main Content -->
    <main class="main">
        <div class="page-header">
            <h1 class="page-title">Profile</h1>
            <p class="page-sub">Manage your account settings and personal information.</p>
        </div>

        <div class="card">

            <!-- Identity Summary Section -->
            <section class="identity-summary">
                <h2>Identity Summary</h2>
                <div class="identity">
                    <div class="avatar" id="avatarEl"><%= initials %></div>
                    <div class="identity-info">
                        <div class="identity-name" id="displayName"><%= fullName %></div>
                        <span class="role-badge" id="displayRole"><%= userRole != null ? userRole.replace("_", " ") : "User" %></span>
                    </div>
                </div>
            </section>

            <div class="divider"></div>

            <!-- Toast -->
            <div class="toast" id="toast" style="display: none;"></div>

            <!-- Form -->
            <form id="profileForm" action="UpdateProfileServlet.do" method="POST" novalidate>

                <!-- Account Information Section -->
                <section class="account-info">
                    <h2>Account Information</h2>
                    <div class="form-grid">
                        <div class="field-group">
                            <label class="field-label" for="userId">User ID</label>
                            <input class="field-input field-readonly" type="text" id="userId" name="userId"
                                value="<%= userId %>" readonly />
                        </div>

                        <div class="field-group">
                            <label class="field-label" for="role">Role</label>
                            <input class="field-input field-readonly" type="text" id="role" name="role"
                                value="<%= userRole != null ? userRole.replace("_", " ") : "User" %>" readonly />
                            <span class="field-hint">Assigned by administrator</span>
                        </div>

                        <div class="field-group">
                            <label class="field-label" for="memberSince">Member Since</label>
                            <input class="field-input field-readonly" type="text" id="memberSince" name="memberSince"
                                value="<%= memberSince %>" readonly />
                        </div>

                        <div class="field-group">
                            <label class="field-label" for="email">Email Address</label>
                            <input class="field-input field-readonly" type="email" id="email" name="email"
                                value="<%= userEmail %>" readonly />
                            <span class="field-hint">Contact support to change email</span>
                        </div>
                    </div>
                </section>

                <div class="divider"></div>

                <!-- Editable Contact Info Section -->
                <section class="contact-info">
                    <h2>Editable Contact Info</h2>
                    <div class="form-grid">
                        <div class="field-group">
                            <label class="field-label" for="firstName">First Name</label>
                            <input class="field-input" type="text" id="firstName" name="firstName"
                                value="<%= firstName %>" placeholder="Enter first name" required />
                            <span class="field-error" id="firstName-error"></span>
                        </div>

                        <% if (!"recycle_center".equalsIgnoreCase(userRole) && !"recycle_centre".equalsIgnoreCase(userRole)) { %>
                        <div class="field-group">
                            <label class="field-label" for="lastName">Last Name</label>
                            <input class="field-input" type="text" id="lastName" name="lastName"
                                value="<%= lastName %>" placeholder="Enter last name" required />
                            <span class="field-error" id="lastName-error"></span>
                        </div>
                        <% } %>

                        <div class="field-group">
                            <label class="field-label" for="phone">Phone Number</label>
                            <input class="field-input" type="tel" id="phone" name="phone"
                                value="<%= phoneNumber %>" placeholder="Enter phone number" />
                            <span class="field-error" id="phone-error"></span>
                        </div>

                        <div class="field-group field-full">
                            <label class="field-label" for="street">Street Address</label>
                            <input class="field-input" type="text" id="street" name="street"
                                value="<%= streetAddress %>" placeholder="Enter street address" />
                        </div>

                        <div class="field-group">
                            <label class="field-label" for="city">City</label>
                            <input class="field-input" type="text" id="city" name="city"
                                value="<%= city %>" placeholder="Enter city" />
                        </div>

                        <div class="field-group">
                            <label class="field-label" for="province">Province</label>
                            <input class="field-input" type="text" id="province" name="province"
                                value="<%= province %>" placeholder="Enter province" />
                        </div>

                        <div class="field-group">
                            <label class="field-label" for="postal">Postal Code</label>
                            <input class="field-input" type="text" id="postal" name="postal"
                                value="<%= postalCode %>" placeholder="Enter postal code" />
                        </div>
                    </div>
                </section>

                <div class="divider"></div>

                <!-- Actions Section -->
                <section class="actions-section">
                    <div class="actions">
                        <% if ("household_user".equalsIgnoreCase(userRole)) { %>
                        <button type="button" class="btn-logout" id="deleteAccountBtn">Delete Account</button>
                        <% } %>
                        <div class="action-right">
                            <button type="button" class="btn-secondary" id="cancelBtn">Cancel</button>
                            <button type="submit" class="btn-primary" id="saveBtn">
                                <span class="btn-text">Save Changes</span>
                                <span class="btn-loader" style="display: none;">Saving...</span>
                            </button>
                        </div>
                    </div>
                </section>

            </form>
        </div>
    </main>

    <!-- Delete Account Confirm Modal -->
    <div class="modal-overlay" id="deleteAccountModal" hidden>
        <div class="modal">
            <h2 class="modal-title">Delete Account</h2>
            <p class="modal-body" id="deleteAccountMessage">A one-time password will be sent to your email address before your account can be deleted.</p>
            <form id="deleteAccountForm" action="DeleteAccountServlet.do" method="POST">
                <input type="hidden" name="action" id="deleteAction" value="sendCode" />
                <div class="field-group" id="deleteOtpGroup" style="display: none; margin-bottom: 18px;">
                    <label class="field-label" for="deleteOtp">Email OTP</label>
                    <input class="field-input" type="text" id="deleteOtp" name="otp" maxlength="6" inputmode="numeric" placeholder="Enter 6-digit OTP" />
                    <span class="field-hint">Check <%= userEmail %> for the OTP.</span>
                </div>
                <div class="modal-actions">
                    <button type="button" class="btn-secondary" id="cancelDeleteAccount">Cancel</button>
                    <button type="submit" class="btn-danger" id="confirmDeleteAccount">Send OTP</button>
                </div>
            </form>
        </div>
    </div>

    <script>
        // Show toast message
        function showToast(message, type) {
            const toast = document.getElementById('toast');
            toast.textContent = message;
            toast.className = 'toast ' + type;
            toast.style.display = 'block';
            setTimeout(() => {
                toast.style.display = 'none';
            }, 3000);
        }

        // Go to dashboard based on role
        function goToDashboard() {
            const role = '<%= userRole %>';
            if (role === 'household_user') {
                window.location.href = 'household_user_dashboard.jsp';
            } else if (role === 'recycle_center' || role === 'recycle_centre') {
                window.location.href = 'recycle_center_dashboard.jsp';
            } else {
                window.location.href = 'index.html';
            }
        }

        // Cancel button - return to dashboard
        document.getElementById('cancelBtn').addEventListener('click', function() {
            goToDashboard();
        });

        // Save button - show loader
        document.getElementById('profileForm').addEventListener('submit', function(e) {
            const saveBtn = document.getElementById('saveBtn');
            const btnText = saveBtn.querySelector('.btn-text');
            const btnLoader = saveBtn.querySelector('.btn-loader');
            
            btnText.style.display = 'none';
            btnLoader.style.display = 'inline-block';
            saveBtn.disabled = true;
        });

        // Delete account modal
        const deleteAccountBtn = document.getElementById('deleteAccountBtn');
        const deleteAccountModal = document.getElementById('deleteAccountModal');
        const deleteAccountForm = document.getElementById('deleteAccountForm');
        const cancelDeleteAccount = document.getElementById('cancelDeleteAccount');
        const deleteAction = document.getElementById('deleteAction');
        const deleteOtpGroup = document.getElementById('deleteOtpGroup');
        const deleteOtp = document.getElementById('deleteOtp');
        const confirmDeleteAccount = document.getElementById('confirmDeleteAccount');
        const deleteAccountMessage = document.getElementById('deleteAccountMessage');

        if (deleteAccountBtn) {
            deleteAccountBtn.addEventListener('click', function() {
                deleteAccountModal.hidden = false;
            });
        }

        cancelDeleteAccount.addEventListener('click', function() {
            deleteAccountModal.hidden = true;
        });

        deleteAccountForm.addEventListener('submit', function(e) {
            if (deleteAction.value === 'verifyCode') {
                if (!/^[0-9]{6}$/.test(deleteOtp.value.trim())) {
                    e.preventDefault();
                    showToast('Please enter the 6-digit OTP sent to your email.', 'error');
                }
                return;
            }

            confirmDeleteAccount.disabled = true;
            confirmDeleteAccount.textContent = 'Sending...';
        });

        // Close modal when clicking outside
        window.addEventListener('click', function(event) {
            if (event.target === deleteAccountModal) {
                deleteAccountModal.hidden = true;
            }
        });

        // Display any error/success messages from URL parameters
        const urlParams = new URLSearchParams(window.location.search);
        if (urlParams.get('success') === 'true') {
            showToast('Profile updated successfully!', 'success');
        } else if (urlParams.get('error')) {
            showToast(urlParams.get('error'), 'error');
        } else if (urlParams.get('deleteSent') === 'true') {
            showToast('A deletion OTP has been sent to your email address.', 'success');
            deleteAccountModal.hidden = false;
            deleteAction.value = 'verifyCode';
            deleteOtpGroup.style.display = 'flex';
            deleteOtp.required = true;
            confirmDeleteAccount.textContent = 'Delete Account';
            deleteAccountMessage.textContent = 'Enter the OTP sent to your email address to permanently delete your account.';
            deleteOtp.focus();
        } else if (urlParams.get('deleteError')) {
            showToast(urlParams.get('deleteError'), 'error');
            deleteAccountModal.hidden = false;
            deleteAction.value = 'verifyCode';
            deleteOtpGroup.style.display = 'flex';
            deleteOtp.required = true;
            confirmDeleteAccount.textContent = 'Delete Account';
            deleteAccountMessage.textContent = 'Enter the OTP sent to your email address to permanently delete your account.';
        }
    </script>
</body>
</html>
