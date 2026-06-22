<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%@page import="java.util.List"%>
<%@page import="za.ac.tut.web.WasteAnalysisResult"%>
<%!
    private String safe(String value) {
        if (value == null) {
            return "";
        }
        return value.replace("&", "&amp;")
                .replace("<", "&lt;")
                .replace(">", "&gt;")
                .replace("\"", "&quot;");
    }
%>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");

    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }

    String firstName = userName;
    if (userName != null && userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }

    WasteAnalysisResult latestScan = (WasteAnalysisResult) session.getAttribute("latestScanResult");
    List<WasteAnalysisResult> scannedItems = (List<WasteAnalysisResult>) session.getAttribute("scannedItems");
    int scannedCount = scannedItems == null ? 0 : scannedItems.size();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Scan Item</title>
    <link rel="stylesheet" href="styling/Schedule_pickup.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Scan Item</h1>
            <p>Hi, <%= safe(firstName) %>. Scan each item, sort it into the right bin, then submit one pickup request when you are done.</p>
            <p><a href="household_user_dashboard.jsp">&lt;- Back to Dashboard</a> | <a href="schedule_pickup.jsp">Go to Pickup Request</a></p>
        </div>

        <% if (request.getAttribute("scanError") != null) { %>
            <div class="scan-alert scan-alert-error"><%= safe(String.valueOf(request.getAttribute("scanError"))) %></div>
        <% } %>

        <% if (latestScan != null && !latestScan.isError()) { %>
            <div class="scan-result-card">
                <span class="scan-label">Latest scan result</span>
                <h2><%= safe(latestScan.getItemName()) %></h2>
                <div class="scan-result-grid">
                    <div>
                        <span>Material</span>
                        <strong><%= safe(latestScan.getMaterialType()) %></strong>
                    </div>
                    <div>
                        <span>Category</span>
                        <strong><%= safe(latestScan.getCategoryLabel()) %></strong>
                    </div>
                    <div>
                        <span>Put it in</span>
                        <strong><%= safe(latestScan.getBinLabel()) %></strong>
                    </div>
                </div>

                <div class="scan-instructions">
                    <h3>How to dispose of it</h3>
                    <ol>
                        <% for (String instruction : latestScan.getDisposalInstructions()) { %>
                            <li><%= safe(instruction) %></li>
                        <% } %>
                    </ol>
                </div>

                <p class="scan-impact"><%= safe(latestScan.getEnvironmentalImpact()) %></p>

                <div class="scan-actions">
                    <a href="#scanForm" class="submit-btn scan-action-secondary">Add Another Item</a>
                    <a href="schedule_pickup.jsp" class="submit-btn">Submit Pickup Request</a>
                </div>
            </div>
        <% } %>

        <% if (scannedCount > 0) { %>
            <div class="scanned-list">
                <span class="scan-label">Items added to this pickup</span>
                <% for (int i = 0; i < scannedItems.size(); i++) {
                    WasteAnalysisResult item = scannedItems.get(i);
                %>
                    <div class="scanned-list-row">
                        <strong><%= i + 1 %>. <%= safe(item.getItemName()) %></strong>
                        <span><%= safe(item.getPickupMaterial()) %> | <%= safe(item.getBinLabel()) %></span>
                    </div>
                <% } %>
            </div>
        <% } %>

        <form id="scanForm" action="WasteScanServlet.do" method="POST" enctype="multipart/form-data">
            <div class="scanner-panel">
                <label class="upload-zone" id="uploadZone" for="fileInput">
                    <span class="upload-icon">+</span>
                    <strong>Drop an item photo here</strong>
                    <span>or choose an image from your device</span>
                    <small>JPEG or PNG, up to 5 MB</small>
                    <input type="file" id="fileInput" name="wasteImage" accept="image/png,image/jpeg,image/*">
                </label>

                <div class="scan-input-actions" aria-label="Scanner input options">
                    <label class="scan-option-btn" for="fileInput">Choose Image</label>
                    <label class="scan-option-btn scan-option-primary camera-option" id="cameraOption" for="cameraInput">Take Photo</label>
                    <input type="file" id="cameraInput" accept="image/*" capture="environment">
                </div>
                <p class="scan-helper" id="scanHelper">On a phone, Take Photo opens the camera so you can scan a fresh picture.</p>
                <div class="scan-alert scan-alert-error" id="clientScanError" style="display:none;"></div>
            </div>

            <div id="previewContainer" class="preview-container" style="display:none;">
                <img id="previewImage" src="#" alt="Selected item preview">
                <p id="selectedName"></p>
            </div>

            <button type="submit" id="scanButton" class="submit-btn" disabled>Scan Item</button>
        </form>
    </div>

    <div class="scanner-overlay" id="scannerOverlay">
        <div class="scanner-loader"></div>
        <p>Analysing your item...</p>
    </div>

    <script>
        const fileInput = document.getElementById('fileInput');
        const cameraInput = document.getElementById('cameraInput');
        const cameraOption = document.getElementById('cameraOption');
        const uploadZone = document.getElementById('uploadZone');
        const previewContainer = document.getElementById('previewContainer');
        const previewImage = document.getElementById('previewImage');
        const selectedName = document.getElementById('selectedName');
        const scanButton = document.getElementById('scanButton');
        const scanForm = document.getElementById('scanForm');
        const scannerOverlay = document.getElementById('scannerOverlay');
        const clientScanError = document.getElementById('clientScanError');

        function updateCameraOptionVisibility() {
            const isTouchDevice = window.matchMedia('(pointer: coarse)').matches || navigator.maxTouchPoints > 0;
            cameraOption.hidden = !isTouchDevice;
        }

        updateCameraOptionVisibility();

        function showClientError(message) {
            clientScanError.textContent = message;
            clientScanError.style.display = 'block';
        }

        function clearClientError() {
            clientScanError.textContent = '';
            clientScanError.style.display = 'none';
        }

        function attachFileToUploadInput(file) {
            if (!file) {
                return false;
            }
            if (typeof DataTransfer === 'undefined') {
                return false;
            }
            const dataTransfer = new DataTransfer();
            dataTransfer.items.add(file);
            fileInput.files = dataTransfer.files;
            return true;
        }

        function setActiveUploadInput(input) {
            fileInput.removeAttribute('name');
            cameraInput.removeAttribute('name');
            input.setAttribute('name', 'wasteImage');
        }

        function useFile(file) {
            clearClientError();
            if (!file || !file.type.startsWith('image/')) {
                showClientError('Please select an image file.');
                return;
            }
            if (file.size > 5 * 1024 * 1024) {
                showClientError('Image is too large. Please choose a file under 5 MB.');
                return;
            }
            const reader = new FileReader();
            reader.onload = function(e) {
                previewImage.src = e.target.result;
                previewContainer.style.display = 'block';
            };
            reader.readAsDataURL(file);
            selectedName.textContent = file.name;
            scanButton.disabled = false;
        }

        fileInput.addEventListener('change', function() {
            if (fileInput.files.length > 0) {
                setActiveUploadInput(fileInput);
                useFile(fileInput.files[0]);
            }
        });

        cameraInput.addEventListener('change', function() {
            if (cameraInput.files.length > 0) {
                const file = cameraInput.files[0];
                setActiveUploadInput(cameraInput);
                useFile(file);
            }
        });

        uploadZone.addEventListener('dragover', function(e) {
            e.preventDefault();
            uploadZone.classList.add('drag-over');
        });

        uploadZone.addEventListener('dragleave', function() {
            uploadZone.classList.remove('drag-over');
        });

        uploadZone.addEventListener('drop', function(e) {
            e.preventDefault();
            uploadZone.classList.remove('drag-over');
            const file = e.dataTransfer.files[0];
            if (attachFileToUploadInput(file)) {
                setActiveUploadInput(fileInput);
                useFile(file);
            } else {
                showClientError('This browser does not support dropped file uploads. Please use Choose Image instead.');
            }
        });

        scanForm.addEventListener('submit', function(e) {
            const activeInput = document.querySelector('input[name="wasteImage"]');
            if (!activeInput || !activeInput.files.length) {
                e.preventDefault();
                showClientError('Please choose, drop, or take a photo before scanning.');
                return;
            }
            scannerOverlay.classList.add('active');
        });
    </script>
</body>
</html>
