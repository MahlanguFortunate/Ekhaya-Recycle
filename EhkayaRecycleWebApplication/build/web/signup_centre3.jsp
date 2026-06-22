<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Step 3</title>
    <link rel="stylesheet" href="styling/landingPagecss.css">
</head>
<body>

<div class="signup-wrapper">
    <div class="signup-bg" style="background-image: url('images/image-bg-02.jpg');"></div>
    <div class="signup-overlay"></div>

    <div class="signup-container">
        <div class="signup-box">

            <div class="signup-step-wrapper">
                <p class="signup-step">Step 3 of 4</p>
                <p class="signup-step-title">Address Information</p>
            </div>

            <form action="RegisterServlet.do" method="POST" class="signup-form">
                <input type="hidden" name="step" value="address">
                
                <input type="text" name="street" placeholder="Street Address" required>
                <input type="text" name="city" placeholder="City" required>
                <input type="text" name="province" placeholder="Province" required>
                <input type="text" name="postal" placeholder="Postal Code" required>

                <% if(session.getAttribute("errorMessage") != null) { %>
                    <p style="color: red; font-size: 14px; margin-top: 5px;">
                        <%= session.getAttribute("errorMessage") %>
                    </p>
                    <% session.removeAttribute("errorMessage"); %>
                <% } %>

                <div class="signup-navigation">
                    <a href="signup_centre2.jsp" class="signup-btn secondary">Back</a>
                    <input type="submit" value="NEXT" class="signup-btn" />
                </div>
            </form>

        </div>
    </div>
</div>

</body>
</html>