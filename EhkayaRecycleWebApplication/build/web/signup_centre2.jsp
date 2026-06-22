<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Step 2 - Centre Information</title>
    <link rel="stylesheet" href="styling/landingPagecss.css">
</head>
<body>

<div class="signup-wrapper">
    <div class="signup-bg" style="background-image: url('images/image-bg-02.jpg');"></div>
    <div class="signup-overlay"></div>

    <div class="signup-container">
        <div class="signup-box">
            <div class="signup-step-wrapper">
                <p class="signup-step">Step 2 of 4</p>
                <p class="signup-step-title">Centre Information</p>
            </div>

            <form class="signup-form" action="RegisterServlet.do" method="POST">
                <input type="hidden" name="step" value="centerInfo">
                
                <input type="text" name="centre_name" placeholder="Centre Name" required>
                <input type="tel" name="centre_number" placeholder="Phone Number (e.g., 0123456789)" required>

                <% if(session.getAttribute("errorMessage") != null) { %>
                    <p style="color: red; font-size: 14px; margin-top: 5px;">
                        <%= session.getAttribute("errorMessage") %>
                    </p>
                    <% session.removeAttribute("errorMessage"); %>
                <% } %>

                <div class="signup-navigation">
                    <a href="signup_centre1.jsp" class="signup-btn secondary">Back</a>
                    <input type="submit" value="NEXT" class="signup-btn" />
                </div>
            </form>
        </div>
    </div>
</div>

</body>
</html>