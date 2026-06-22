<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
    <title>Recycle Ekhaya · Forgot Password</title>
    <link href="https://fonts.googleapis.com/css2?family=Oswald:wght@300;400;500;600;700&family=Source+Sans+3:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        /* --- CSS Variables --- */
        :root {
            --font-heading: 'Oswald', sans-serif;
            --font-body: 'Source Sans 3', sans-serif;
            --white: #ffffff;
            --white-70: rgba(255, 255, 255, 0.7);
            --white-40: rgba(255, 255, 255, 0.4);
            --transition-smooth: 0.3s ease;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: var(--font-body);
            font-weight: 300;
            color: var(--white);
            line-height: 1.7;
            overflow-x: hidden;
            background: #111;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .reset-wrapper {
            width: 100%;
            padding: 2rem 1.5rem;
        }

        .reset-box {
            max-width: 450px;
            margin: 0 auto;
            padding: 45px 40px;
            background: rgba(0, 0, 0, 0.45);
            border: 1px solid rgba(255, 255, 255, 0.2);
            backdrop-filter: blur(6px);
            text-align: center;
            transition: transform 0.3s ease, box-shadow 0.3s ease;
        }

        .reset-box:hover {
            transform: translateY(-4px);
            background: rgba(0, 0, 0, 0.55);
            border-color: rgba(255, 255, 255, 0.3);
        }

        .reset-title {
            font-family: var(--font-heading);
            letter-spacing: 6px;
            font-size: 28px;
            margin-bottom: 15px;
            color: var(--white);
            font-weight: 400;
        }

        .reset-subtitle {
            font-size: 14px;
            color: var(--white-70);
            margin-bottom: 30px;
            letter-spacing: 1px;
        }

        .reset-form {
            display: flex;
            flex-direction: column;
            gap: 18px;
        }

        .reset-form input {
            width: 100%;
            padding: 15px 18px;
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.2);
            color: #fff;
            font-family: var(--font-body);
            font-size: 15px;
            outline: none;
            transition: border-color 0.2s ease, background 0.2s ease;
        }

        .reset-form input:focus {
            border-color: var(--white-70);
            background: rgba(255, 255, 255, 0.12);
        }

        .reset-form input::placeholder {
            color: rgba(255, 255, 255, 0.5);
        }

        .password-hint-row {
            text-align: right;
            margin-top: -8px;
            margin-bottom: 4px;
        }

        .toggle-password-btn {
            background: none;
            border: none;
            color: var(--white-70);
            font-size: 11px;
            font-family: var(--font-body);
            cursor: pointer;
            text-decoration: underline;
        }

        .toggle-password-btn:hover {
            color: var(--white);
        }

        .reset-btn {
            margin-top: 15px;
            padding: 15px;
            background: transparent;
            border: 1px solid rgba(255, 255, 255, 0.4);
            color: #fff;
            letter-spacing: 3px;
            font-family: var(--font-heading);
            font-size: 13px;
            cursor: pointer;
            transition: 0.3s ease;
            text-transform: uppercase;
            width: 100%;
        }

        .reset-btn:hover {
            background: #fff;
            color: #111;
            border-color: #fff;
        }

        .reset-footer-link {
            margin-top: 28px;
            font-size: 14px;
            color: rgba(255, 255, 255, 0.7);
        }

        .reset-footer-link a {
            color: #fff;
            text-decoration: underline;
            margin-left: 5px;
        }

        .reset-footer-link a:hover {
            opacity: 0.8;
        }

        /* Message boxes */
        .error-message {
            margin-top: 18px;
            padding: 12px 16px;
            background: rgba(220, 53, 69, 0.18);
            color: #ffb3b3;
            border-left: 3px solid #dc3545;
            font-size: 13px;
            text-align: center;
        }

        .success-message {
            margin-top: 18px;
            padding: 12px 16px;
            background: rgba(40, 167, 69, 0.16);
            color: #b3ffcf;
            border-left: 3px solid #28a745;
            font-size: 13px;
            text-align: center;
        }

        .eco-stats-micro {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
            display: flex;
            justify-content: center;
            gap: 24px;
            flex-wrap: wrap;
        }

        .micro-stat {
            font-size: 10px;
            letter-spacing: 1.5px;
            color: var(--white-40);
            font-family: var(--font-heading);
            text-transform: uppercase;
        }

        .micro-stat span {
            color: var(--white-70);
            font-weight: 500;
            margin-right: 4px;
        }

        @media (max-width: 500px) {
            .reset-box {
                padding: 35px 24px;
            }
            .reset-title {
                font-size: 24px;
                letter-spacing: 4px;
            }
        }
    </style>
</head>
<body>
<div class="reset-wrapper">
    <div class="reset-box">
        <%
            Boolean verificationSentAttr = (Boolean) request.getAttribute("verificationSent");
            boolean verificationSent = Boolean.TRUE.equals(verificationSentAttr) || session.getAttribute("resetCode") != null;
            String resetEmail = (String) request.getAttribute("resetEmail");
            if (resetEmail == null) {
                resetEmail = (String) session.getAttribute("resetEmail");
            }
            if (resetEmail == null) {
                resetEmail = "";
            }
        %>
        <h2 class="reset-title">FORGOT PASSWORD</h2>
        <div class="reset-subtitle">
            <%= verificationSent ? "Enter the email verification code and your new password" : "Verify your email before changing your password" %>
        </div>

        <%
            String error = (String) request.getAttribute("error");
            if (error != null && !error.isEmpty()) {
        %>
            <div class="error-message"><%= error %></div>
        <%
            }
            String success = (String) request.getAttribute("success");
            if (success != null && !success.isEmpty()) {
        %>
            <div class="success-message"><%= success %></div>
        <%
            }
        %>

        <% if (!verificationSent) { %>
            <form class="reset-form" action="ResetPasswordServlet.do" method="post" data-step="send-code">
                <input type="hidden" name="action" value="sendCode">
                <input type="email" name="email" placeholder="Registered Email Address" required>
                <button type="submit" class="reset-btn">SEND VERIFICATION CODE</button>
            </form>
        <% } else { %>
            <form class="reset-form" action="ResetPasswordServlet.do" method="post" data-step="reset-password">
                <input type="hidden" name="action" value="resetPassword">
                <input type="email" name="email" placeholder="Registered Email Address" value="<%= resetEmail %>" readonly required>
                <input type="text" id="verificationCode" name="verificationCode" placeholder="6-Digit Verification Code" maxlength="6" required>

                <input type="password" id="newPassword" name="newPassword" placeholder="New Password" required>
                <div class="password-hint-row">
                    <button type="button" class="toggle-password-btn" onclick="togglePassword('newPassword', this)">Show password</button>
                </div>

                <input type="password" id="confirmPassword" name="confirmPassword" placeholder="Confirm Password" required>
                <div class="password-hint-row">
                    <button type="button" class="toggle-password-btn" onclick="togglePassword('confirmPassword', this)">Show password</button>
                </div>

                <button type="submit" class="reset-btn">VERIFY & UPDATE PASSWORD</button>
            </form>

            <form class="reset-form" action="ResetPasswordServlet.do" method="post" style="margin-top: 12px;" data-step="send-code">
                <input type="hidden" name="action" value="sendCode">
                <input type="hidden" name="email" value="<%= resetEmail %>">
                <button type="submit" class="toggle-password-btn" style="text-decoration: none;">Resend verification code</button>
            </form>
        <% } %>

        <div class="reset-footer-link">
            Remember your password? <a href="login.html">Back to Login</a>
        </div>

        <div class="eco-stats-micro">
            <div class="micro-stat"><span>♻️</span> 590 kg CO₂ saved</div>
            <div class="micro-stat"><span>✓</span> 5 pickups</div>
            <div class="micro-stat"><span>🌱</span> R590 earned</div>
        </div>
    </div>
</div>

<script>
    function togglePassword(fieldId, btn) {
        const input = document.getElementById(fieldId);
        if (input.type === 'password') {
            input.type = 'text';
            btn.textContent = 'Hide password';
        } else {
            input.type = 'password';
            btn.textContent = 'Show password';
        }
    }

    document.querySelectorAll('.reset-form').forEach(function(form) {
        form.addEventListener('submit', function(e) {
            const step = form.getAttribute('data-step');
            const emailInput = form.querySelector('input[name="email"]');
            const email = emailInput ? emailInput.value.trim() : '';
        
            if (!email) {
                e.preventDefault();
                alert('Please enter your email address.');
                return;
            }

            if (step !== 'reset-password') {
                return;
            }

            const verificationCode = form.querySelector('input[name="verificationCode"]').value.trim();
            const newPassword = form.querySelector('input[name="newPassword"]').value;
            const confirmPassword = form.querySelector('input[name="confirmPassword"]').value;

            if (!/^[0-9]{6}$/.test(verificationCode)) {
                e.preventDefault();
                alert('Please enter the 6-digit verification code.');
                return;
            }

            if (!newPassword) {
                e.preventDefault();
                alert('Please enter a new password.');
                return;
            }

            if (newPassword.length < 6) {
                e.preventDefault();
                alert('Password must be at least 6 characters long.');
                return;
            }

            if (newPassword !== confirmPassword) {
                e.preventDefault();
                alert('Passwords do not match.');
            }
        });
    });
</script>
</body>
</html>
