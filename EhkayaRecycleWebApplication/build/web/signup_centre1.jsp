<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Centre Sign Up</title>
    <link rel="stylesheet" href="styling/landingPagecss.css">
</head>
<body>

<div class="signup-wrapper">
    <div class="signup-bg" style="background-image: url('images/image-bg-02.jpg');"></div>
    <div class="signup-overlay"></div>

    <div class="signup-container">
        <div class="signup-box">
            <h2 class="signup-title">Sign Up as a Centre</h2>

            <div class="signup-step-wrapper">
                <p class="signup-step">Step 1 of 4</p>
                <p class="signup-step-title">Account Credentials</p>
            </div>

            <form class="signup-form" action="RegisterServlet.do" method="POST">
                <input type="hidden" name="role" value="recycle_center">
                <input type="hidden" name="step" value="credentials">
                
                <input type="email" name="email" placeholder="Email Address" required>
                <input type="password" id="password" name="password" placeholder="Password" required>
                <input type="password" id="passwordConfirm" name="passwordConfirm" placeholder="Confirm Password" required>

                <% if(session.getAttribute("errorMessage") != null) { %>
                    <p style="color: red; font-size: 14px; margin-top: 5px;">
                        <%= session.getAttribute("errorMessage") %>
                    </p>
                    <% session.removeAttribute("errorMessage"); %>
                <% } %>

                <button type="submit" class="signup-btn">NEXT</button>
            </form>
            <p class="signup-note">
                Already have an account? 
                <a href="login.html">Log in</a>
            </p>
        </div>
    </div>
</div>

</body>
</html>