<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Center - Pending Approval</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            margin: 0;
            padding: 0;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        .container {
            background: white;
            border-radius: 10px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            padding: 40px;
            width: 500px;
            text-align: center;
        }
        .pending-icon {
            font-size: 80px;
            margin-bottom: 20px;
        }
        h1 {
            color: #f39c12;
            margin-bottom: 20px;
        }
        .message {
            background: #fef5e7;
            border-left: 4px solid #f39c12;
            padding: 15px;
            margin: 20px 0;
            text-align: left;
            border-radius: 5px;
        }
        .info-box {
            background: #f8f9fa;
            border-radius: 5px;
            padding: 15px;
            margin: 20px 0;
            text-align: left;
        }
        .info-box p {
            margin: 10px 0;
        }
        .logout-btn {
            background-color: #e74c3c;
            color: white;
            padding: 12px 30px;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            margin-top: 20px;
            text-decoration: none;
            display: inline-block;
        }
        .logout-btn:hover {
            background-color: #c0392b;
        }
        .warning-text {
            color: #e67e22;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="pending-icon">?</div>
        <h1>Approval Pending</h1>
        
        <% 
            String pendingMessage = (String) session.getAttribute("pendingMessage");
            String userName = (String) session.getAttribute("userName");
            String userEmail = (String) session.getAttribute("userEmail");
            String centerStatus = (String) session.getAttribute("centerStatus");
        %>
        
        <div class="message">
            <p><%= pendingMessage != null ? pendingMessage : "Your registration is being reviewed by administrators." %></p>
        </div>
        
        <div class="info-box">
            <h3>Registration Details:</h3>
            <p><strong>Center Name:</strong> <%= userName != null ? userName : "Not specified" %></p>
            <p><strong>Email:</strong> <%= userEmail != null ? userEmail : "Not specified" %></p>
            <p><strong>Status:</strong> <span class="warning-text"><%= centerStatus != null ? centerStatus.toUpperCase() : "PENDING" %></span></p>
        </div>
        
        <div class="info-box">
            <h3>What happens next?</h3>
            <p>? An administrator will review your application</p>
            <p>? You will receive an email notification once approved</p>
            <p>? After approval, you can log in and access the full dashboard</p>
            <p>? This process usually takes 1-2 business days</p>
        </div>
        
        <form action="LogoutServlet" method="get">
            <button type="submit" class="logout-btn">Logout</button>
        </form>
    </div>
</body>
</html>