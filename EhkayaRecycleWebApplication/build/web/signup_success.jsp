<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Success</title>
    <link rel="stylesheet" href="styling/landingPagecss.css">
</head>
<body>
    <div class="signup-wrapper">
        <div class="signup-bg"></div>
        <div class="signup-overlay"></div>

        <div class="signup-container">
            <div class="signup-box">
                <div class="signup-step-wrapper">
                    <p class="signup-step">Success</p>
                    <p class="signup-step-title">Account Created</p>
                </div>

                <% if(session.getAttribute("successMessage") != null) { %>
                    <p class="signup-review-text" style="color: green;">
                        <%= session.getAttribute("successMessage") %>
                    </p>
                    <% session.removeAttribute("successMessage"); %>
                <% } %>

                <p class="signup-review-text">
                    Your account has been successfully created. You can now log in and start using Recycle Ekhaya.
                </p>

                <div class="signup-review-box">
                    <p>Your registration was completed successfully.</p>
                    <p>You may now proceed to login.</p>
                </div>

                <div class="signup-navigation">
                    <a href="login.html" class="login-btn success-btn">GO TO LOGIN</a>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
