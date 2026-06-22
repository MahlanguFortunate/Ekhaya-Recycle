<%-- 
    Document   : signup_centre4
    Created on : 23 Apr 2026, 17:15:44
    Author     : DELL
--%>

<%@page import="za.ac.tut.object.credentials.Credentials" %>
<%@page import="za.ac.tut.object.address.Address" %>
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
                    
                    <%
                        // Get data from session with null checks
                        Credentials cred = (Credentials) session.getAttribute("credentials");
                        Address address = (Address) session.getAttribute("address");
                        String centerName = (String) session.getAttribute("centerName");
                        String centerNumber = (String) session.getAttribute("centerNumber");
                        
                        // If any data is missing, redirect to step 1
                        if (cred == null || address == null || centerName == null || centerNumber == null) {
                            response.sendRedirect("signup_centre1.jsp");
                            return;
                        }
                        
                        String email = cred.getEmail();
                        String street = address.getStreetAddress();
                        String city = address.getCity();
                        String province = address.getProvince();
                        String code = address.getPostalCode();
                    %>
                    
                    <div class="signup-review-box">
                        <p><strong>Centre Name:</strong> <%= centerName %></p>
                        <p><strong>Email:</strong> <%= email %></p>
                        <p><strong>Phone:</strong> <%= centerNumber %></p>
                        <p><strong>Street Address:</strong> <%= street %></p>
                        <p><strong>City:</strong> <%= city %></p>
                        <p><strong>Province:</strong> <%= province %></p>
                        <p><strong>Postal Code:</strong> <%= code %></p>
                    </div>

                    <% if(session.getAttribute("errorMessage") != null) { %>
                        <p style="color: red; font-size: 14px; text-align: center; margin: 10px 0;">
                            <%= session.getAttribute("errorMessage") %>
                        </p>
                        <% session.removeAttribute("errorMessage"); %>
                    <% } %>

                    <div class="signup-navigation">
                        <a href="signup_centre3.jsp" class="signup-btn secondary">Back</a>
                        <form action="RegisterServlet.do" method="POST" style="display: inline;">
                            <input type="hidden" name="step" value="confirm">
                            <input type="submit" value="CREATE ACCOUNT" class="signup-btn" />
                        </form>
                    </div>

                </div>
            </div>
        </div>

    </body>
</html>