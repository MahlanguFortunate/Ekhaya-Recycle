<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Step 2 - Personal Information</title>
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
                    <p class="signup-step-title">Personal Information</p>
                </div>

                <form class="signup-form" action="RegisterServlet.do" method="POST">
                    <input type="hidden" name="step" value="personalInfo">
                    
                    <input type="text" name="firstname" placeholder="First Name" required>
                    <input type="text" name="lastname" placeholder="Last Name" required>
                    <input type="tel" name="phone" placeholder="Phone Number" required>

                    <% if(session.getAttribute("errorMessage") != null) { %>
                        <p style="color: red; font-size: 14px; margin-top: 5px;">
                            <%= session.getAttribute("errorMessage") %>
                        </p>
                        <% session.removeAttribute("errorMessage"); %>
                    <% } %>

                    <div class="signup-navigation">
                        <a href="signup_household1.jsp" class="signup-btn secondary">Back</a>
                        <input type="submit" value="NEXT" class="signup-btn" />
                    </div>
                </form>
            </div>
        </div>
    </div>
</body>
</html>