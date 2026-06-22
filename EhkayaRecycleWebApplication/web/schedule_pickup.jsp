<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.LinkedHashSet"%>
<%@page import="java.util.List"%>
<%@page import="java.util.Set"%>
<%@page import="za.ac.tut.web.WasteAnalysisResult"%>
<%!
    private boolean materialSelected(String material, Set<String> scannedMaterials) {
        return material != null && scannedMaterials != null && scannedMaterials.contains(material);
    }
%>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    String userEmail = (String) session.getAttribute("userEmail");

    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }

    String clearScan = request.getParameter("clearScan");
    if ("true".equals(clearScan)) {
        session.removeAttribute("latestScanResult");
        session.removeAttribute("scannedItems");
        response.sendRedirect("schedule_pickup.jsp");
        return;
    }

    String firstName = userName;
    if (userName != null && userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }

    WasteAnalysisResult scanResult = (WasteAnalysisResult) session.getAttribute("latestScanResult");
    String scannedItemName = "";
    String scannedNotes = "";
    List<WasteAnalysisResult> scannedItems = (List<WasteAnalysisResult>) session.getAttribute("scannedItems");
    Set<String> scannedMaterials = new LinkedHashSet<String>();
    StringBuilder scannedNotesBuilder = new StringBuilder();
    boolean hasScanResult = scannedItems != null && !scannedItems.isEmpty();

    if (hasScanResult) {
        for (WasteAnalysisResult item : scannedItems) {
            scannedMaterials.add(item.getPickupMaterial());
            if (scannedNotesBuilder.length() > 0) {
                scannedNotesBuilder.append("; ");
            }
            scannedNotesBuilder.append(item.getItemName()).append(" (").append(item.getPickupMaterial()).append(")");
        }
        scannedNotes = "Scanned items: " + scannedNotesBuilder.toString();
        if (scanResult != null && !scanResult.isError()) {
            scannedItemName = scanResult.getItemName();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Pickup Request</title>
    <link rel="stylesheet" href="styling/Schedule_pickup.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Pickup Request</h1>
            <p>Welcome, <%= firstName %>! Complete the form below to submit your pickup request.</p>
            <p><a href="household_user_dashboard.jsp">&lt;- Back to Dashboard</a> | <a href="scan_item.jsp">Scan an Item</a></p>
        </div>

        <% if (hasScanResult) { %>
            <div class="scan-summary">
                <div>
                    <span class="scan-label">Scanned items ready for pickup</span>
                    <h2><%= scannedItems.size() %> item<%= scannedItems.size() == 1 ? "" : "s" %> added</h2>
                    <p><strong>Latest item:</strong> <%= scannedItemName %></p>
                    <p><strong>Selected materials:</strong> <%= String.join(", ", scannedMaterials) %></p>
                </div>
                <a href="schedule_pickup.jsp?clearScan=true" class="scan-summary-link">Clear</a>
            </div>
        <% } else if ("success".equals(request.getParameter("scan"))) { %>
            <div class="scan-alert scan-alert-error">The scanner could not identify the item. Please choose the material manually.</div>
        <% } %>

        <form action="PickupRequestServlet.do" method="POST">
            <div class="form-group">
                <label>Material Type (Select all that apply)</label>
                <div class="materials-grid">
                    <div class="checkbox-item">
                        <input type="checkbox" id="plastic" name="material" value="Plastic" <%= materialSelected("Plastic", scannedMaterials) ? "checked" : "" %>>
                        <label for="plastic">Plastic</label>
                    </div>
                    <div class="checkbox-item">
                        <input type="checkbox" id="paper" name="material" value="Paper" <%= materialSelected("Paper", scannedMaterials) ? "checked" : "" %>>
                        <label for="paper">Paper</label>
                    </div>
                    <div class="checkbox-item">
                        <input type="checkbox" id="glass" name="material" value="Glass" <%= materialSelected("Glass", scannedMaterials) ? "checked" : "" %>>
                        <label for="glass">Glass</label>
                    </div>
                    <div class="checkbox-item">
                        <input type="checkbox" id="metal" name="material" value="Metal" <%= materialSelected("Metal", scannedMaterials) ? "checked" : "" %>>
                        <label for="metal">Metal</label>
                    </div>
                    <div class="checkbox-item">
                        <input type="checkbox" id="cardboard" name="material" value="Cardboard" <%= materialSelected("Cardboard", scannedMaterials) ? "checked" : "" %>>
                        <label for="cardboard">Cardboard</label>
                    </div>
                    <div class="checkbox-item">
                        <input type="checkbox" id="electronics" name="material" value="Electronics" <%= materialSelected("Electronics", scannedMaterials) ? "checked" : "" %>>
                        <label for="electronics">Electronics</label>
                    </div>
                    <div class="checkbox-item">
                        <input type="checkbox" id="organic" name="material" value="Organic" <%= materialSelected("Organic", scannedMaterials) ? "checked" : "" %>>
                        <label for="organic">Organic</label>
                    </div>
                    <div class="checkbox-item">
                        <input type="checkbox" id="mixed" name="material" value="Mixed" <%= materialSelected("Mixed", scannedMaterials) ? "checked" : "" %>>
                        <label for="mixed">Mixed</label>
                    </div>
                </div>
            </div>

            <div class="form-group">
                <label for="date">Preferred Date</label>
                <input type="date" id="date" name="date" required>
            </div>

            <div class="form-group">
                <label>Pickup Address</label>
                <div class="checkbox-item">
                    <input type="checkbox" id="useHouseholdAddress" name="useHouseholdAddress" checked>
                    <label for="useHouseholdAddress">Use household address</label>
                </div>
                <p class="field-note">Uncheck to enter a different pickup address below.</p>
            </div>

            <div id="otherAddressFields" style="display: none;">
                <div class="form-group">
                    <label for="street">Street Name</label>
                    <input type="text" id="street" name="street" placeholder="123 Green Street">
                </div>

                <div class="form-group">
                    <label for="city">City</label>
                    <input type="text" id="city" name="city" placeholder="Johannesburg">
                </div>

                <div class="form-group">
                    <label for="province">Province</label>
                    <input type="text" id="province" name="province" placeholder="Gauteng">
                </div>

                <div class="form-group">
                    <label for="postal">Postal Code</label>
                    <input type="text" id="postal" name="postal" placeholder="2000">
                </div>
            </div>

            <div class="form-group">
                <label for="notes">Notes (optional)</label>
                <textarea id="notes" name="notes" placeholder="Any special instructions..." maxlength="200"><%= scannedNotes %></textarea>
                <div class="field-note">Not more than 200 characters</div>
            </div>

            <button type="submit" class="submit-btn">Submit Pickup Request</button>
        </form>
    </div>

    <script>
        const useHouseholdCheckbox = document.getElementById('useHouseholdAddress');
        const otherAddressFields = document.getElementById('otherAddressFields');

        useHouseholdCheckbox.addEventListener('change', function() {
            otherAddressFields.style.display = this.checked ? 'none' : 'block';
        });

        const today = new Date().toISOString().split('T')[0];
        document.getElementById('date').min = today;
    </script>
</body>
</html>
