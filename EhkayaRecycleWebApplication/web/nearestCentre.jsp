<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="za.ac.tut.web.FindNearestCentreServlet.CentreWithDistance"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Find Nearest Recycle Centre</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        
        body {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        .header {
            background: white;
            border-radius: 20px;
            padding: 25px;
            margin-bottom: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .header h1 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .header p {
            color: #666;
        }
        
        .ai-card {
            background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%);
            color: white;
            border-radius: 20px;
            padding: 20px;
            margin-bottom: 25px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.1);
        }
        
        .ai-card h3 {
            margin-bottom: 10px;
        }
        
        .ai-card .recommendation {
            font-size: 1.2em;
            margin-top: 10px;
            padding: 10px;
            background: rgba(255,255,255,0.2);
            border-radius: 10px;
        }
        
        .centres-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }
        
        .centre-card {
            background: white;
            border-radius: 15px;
            padding: 20px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        
        .centre-card:hover {
            transform: translateY(-5px);
        }
        
        .centre-card.closest {
            border-left: 5px solid #4caf50;
            background: #f0fff4;
        }
        
        .centre-name {
            font-size: 1.3em;
            font-weight: bold;
            color: #333;
            margin-bottom: 10px;
        }
        
        .centre-distance {
            display: inline-block;
            background: #4caf50;
            color: white;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.9em;
            margin-bottom: 15px;
        }
        
        .centre-distance.far {
            background: #ff9800;
        }
        
        .centre-distance.very-far {
            background: #f44336;
        }
        
        .centre-address {
            color: #666;
            margin-bottom: 10px;
            line-height: 1.4;
        }
        
        .centre-coords {
            font-family: monospace;
            font-size: 0.8em;
            color: #999;
            margin-top: 10px;
            padding-top: 10px;
            border-top: 1px solid #eee;
        }
        
        .select-btn {
            background: #2196f3;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 10px;
            cursor: pointer;
            margin-top: 15px;
            width: 100%;
            font-size: 1em;
            transition: background 0.3s;
        }
        
        .select-btn:hover {
            background: #1976d2;
        }
        
        .back-btn {
            background: #666;
            color: white;
            border: none;
            padding: 12px 25px;
            border-radius: 10px;
            cursor: pointer;
            margin-top: 20px;
            font-size: 1em;
        }
        
        .error {
            background: #ffebee;
            color: #c62828;
            padding: 15px;
            border-radius: 10px;
            margin-bottom: 20px;
        }
        
        .badge {
            background: #4caf50;
            color: white;
            padding: 3px 10px;
            border-radius: 15px;
            font-size: 0.7em;
            margin-left: 10px;
        }
        
        @keyframes pulse {
            0% { transform: scale(1); }
            50% { transform: scale(1.02); }
            100% { transform: scale(1); }
        }
        
        .closest {
            animation: pulse 1s ease;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📍 Find Your Nearest Recycle Centre</h1>
            <p>Hello, <%= request.getAttribute("userName") != null ? request.getAttribute("userName") : "User" %>!</p>
            <p>Based on your location, here are the recycling centres near you.</p>
        </div>
        
        <% if (request.getAttribute("errorMessage") != null) { %>
            <div class="error">
                ❌ <%= request.getAttribute("errorMessage") %>
            </div>
        <% } %>
        
        <% if (request.getAttribute("centres") != null) { 
            List<CentreWithDistance> centres = (List<CentreWithDistance>) request.getAttribute("centres");
            String aiRecommendation = (String) request.getAttribute("aiRecommendation");
        %>
        
        <!-- AI Recommendation Card -->
        <div class="ai-card">
            <h3>🤖 AI Recommendation</h3>
            <p>Based on distance analysis and historical data:</p>
            <div class="recommendation">
                💡 <%= aiRecommendation != null ? aiRecommendation : "Use the closest centre for fastest service" %>
            </div>
        </div>
        
        <!-- Results Summary -->
        <div style="margin-bottom: 20px;">
            <p>📊 Found <strong><%= centres.size() %></strong> recycling centres near you</p>
        </div>
        
        <!-- Centres Grid -->
        <div class="centres-grid">
            <% for (int i = 0; i < centres.size(); i++) {
                CentreWithDistance centre = centres.get(i);
                boolean isClosest = (i == 0);
                String distanceClass = "";
                if (centre.distance < 3) distanceClass = "";
                else if (centre.distance < 7) distanceClass = "far";
                else distanceClass = "very-far";
            %>
            <div class="centre-card <%= isClosest ? "closest" : "" %>">
                <div class="centre-name">
                    <%= centre.name %>
                    <% if (isClosest) { %>
                        <span class="badge">🏆 CLOSEST</span>
                    <% } %>
                </div>
                <div class="centre-distance <%= distanceClass %>">
                    📍 <%= String.format("%.1f", centre.distance) %> km away
                </div>
                <div class="centre-address">
                    📮 <%= centre.address %><br>
                    <%= centre.city %>, <%= centre.province %><br>
                    <%= centre.postalCode %>
                </div>
                <div class="centre-coords">
                    📐 Lat: <%= String.format("%.6f", centre.latitude) %><br>
                    📐 Lon: <%= String.format("%.6f", centre.longitude) %>
                </div>
                
            </div>
            <% } %>
        </div>
        
        <% } else { %>
            <div class="error">
                ⚠️ No recycle centres found with location coordinates. Please contact support.
            </div>
        <% } %>
        
        <div style="text-align: center; margin-top: 30px;">
            <button class="back-btn" onclick="location.href='household_user_dashboard.jsp'">
                ← Back to Dashboard
            </button>
        </div>
    </div>
    
    <script>
        function selectCentre(centreId, centreName) {
            if (confirm("Would you like to schedule a pickup with " + centreName + "?")) {
                window.location.href = "schedulePickup.jsp?centreId=" + centreId + "&centreName=" + encodeURIComponent(centreName);
            }
        }
    </script>
</body>
</html>