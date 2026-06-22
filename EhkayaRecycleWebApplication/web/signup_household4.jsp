<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    <title>Recycle Ekhaya - Step 4</title>
    <link rel="stylesheet" href="styling/landingPagecss.css">
</head>
<body>
    <div class="signup-wrapper">
        <div class="signup-bg"></div>
        <div class="signup-overlay"></div>

        <div class="signup-container">
            <div class="signup-box">
                <div class="signup-step-wrapper">
                    <p class="signup-step">Step 4 of 4</p>
                    <p class="signup-step-title">Review & Complete</p>
                </div>

                <p class="signup-review-text">
                    Please review your details before creating your account.
                </p>

                <div class="signup-review-box">
                    <p><strong>First Name:</strong> ${sessionScope.personalInfo.firstName}</p>
                    <p><strong>Last Name:</strong> ${sessionScope.personalInfo.lastName}</p>
                    <p><strong>Email:</strong> ${sessionScope.credentials.email}</p>
                    <p><strong>Phone:</strong> ${sessionScope.personalInfo.phoneNumber}</p>
                    <p><strong>Street Address:</strong> ${sessionScope.address.streetAddress}</p>
                    <p><strong>City:</strong> ${sessionScope.address.city}</p>
                    <p><strong>Province:</strong> ${sessionScope.address.province}</p>
                    <p><strong>Postal Code:</strong> ${sessionScope.address.postalCode}</p>
                </div>

                <% if(session.getAttribute("errorMessage") != null) { %>
                    <p style="color: red; font-size: 14px; text-align: center;">
                        <%= session.getAttribute("errorMessage") %>
                    </p>
                    <% session.removeAttribute("errorMessage"); %>
                <% } %>

                <div class="signup-navigation">
                    <a href="signup_household3.jsp" class="signup-btn secondary">Back</a>
                    <form action="RegisterServlet.do" method="POST" style="display: inline;">
                        <input type="hidden" name="step" value="confirm">
                        <input type="submit" value="Create Account" class="signup-btn">
                    </form>
                </div>
            </div>
        </div>
    </div>
</body>
</html>