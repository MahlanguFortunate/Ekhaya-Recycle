<%@page contentType="text/html" pageEncoding="UTF-8"%>
<%
    Integer userId = (Integer) session.getAttribute("userId");
    String userName = (String) session.getAttribute("userName");
    if (userId == null || userName == null) {
        response.sendRedirect("login.html");
        return;
    }

    String firstName = userName;
    if (userName.contains(" ")) {
        firstName = userName.substring(0, userName.indexOf(" "));
    }

    String mapboxToken = application.getInitParameter("mapbox.access.token");
    if (mapboxToken == null) {
        mapboxToken = "";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recycle Ekhaya - Smart City Analytics</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link href="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.css" rel="stylesheet">
    <script src="https://api.mapbox.com/mapbox-gl-js/v2.15.0/mapbox-gl.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <style>
        :root {
            --bg: #050806;
            --panel: rgba(9, 16, 13, 0.78);
            --panel-strong: rgba(12, 20, 16, 0.94);
            --stroke: rgba(163, 255, 67, 0.18);
            --stroke-strong: rgba(163, 255, 67, 0.42);
            --neon: #a7ff3d;
            --neon-soft: #74d83c;
            --cyan: #4be7ff;
            --text: #efffed;
            --muted: #93a994;
            --warning: #ffd166;
            --danger: #ff5c7a;
            --shadow: 0 0 24px rgba(135, 255, 56, 0.22);
        }

        * { box-sizing: border-box; }
        html, body { min-height: 100%; }
        body {
            margin: 0;
            font-family: 'Inter', sans-serif;
            color: var(--text);
            background:
                radial-gradient(circle at 76% 16%, rgba(122, 255, 54, 0.13), transparent 28%),
                radial-gradient(circle at 26% 82%, rgba(75, 231, 255, 0.10), transparent 30%),
                linear-gradient(135deg, #030503 0%, #0b100d 54%, #050806 100%);
            overflow-x: hidden;
        }

        .shell {
            display: grid;
            grid-template-columns: 260px minmax(0, 1fr);
            min-height: 100vh;
        }

        .sidebar {
            position: sticky;
            top: 0;
            height: 100vh;
            padding: 18px;
            background: rgba(3, 7, 5, 0.86);
            border-right: 1px solid var(--stroke);
            backdrop-filter: blur(18px);
            z-index: 5;
        }

        .brand {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 8px 8px 18px;
            border-bottom: 1px solid rgba(255,255,255,0.07);
        }

        .brand-mark {
            width: 34px;
            height: 34px;
            display: grid;
            place-items: center;
            border-radius: 8px;
            color: #071007;
            background: linear-gradient(135deg, var(--neon), var(--cyan));
            box-shadow: var(--shadow);
            font-weight: 900;
        }

        .brand h1 {
            margin: 0;
            font-size: 14px;
            line-height: 1.1;
        }

        .brand span {
            display: block;
            margin-top: 3px;
            color: var(--muted);
            font-size: 11px;
            font-weight: 500;
        }

        .user-chip {
            margin: 18px 0;
            padding: 12px;
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 8px;
            background: rgba(255,255,255,0.045);
        }

        .user-chip small,
        .section-label {
            display: block;
            color: var(--muted);
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 700;
        }

        .user-chip strong {
            display: block;
            margin-top: 4px;
            font-size: 14px;
        }

        .nav-link,
        .filter-row {
            display: flex;
            align-items: center;
            gap: 10px;
            min-height: 38px;
            padding: 10px 12px;
            border-radius: 8px;
            color: #d8ead6;
            text-decoration: none;
            font-size: 13px;
            border: 1px solid transparent;
        }

        .nav-link.active {
            color: #071007;
            background: linear-gradient(135deg, var(--neon), #7edc2c);
            box-shadow: var(--shadow);
            font-weight: 800;
        }

        .nav-link:hover,
        .filter-row:hover {
            border-color: var(--stroke-strong);
            background: rgba(163, 255, 67, 0.08);
        }

        .section-label { margin: 20px 10px 8px; }

        .filter-row {
            justify-content: space-between;
            color: var(--muted);
        }

        .filter-row input {
            accent-color: var(--neon);
        }

        .province-filter {
            width: calc(100% - 20px);
            margin: 10px;
            padding: 10px 12px;
            border-radius: 8px;
            border: 1px solid var(--stroke);
            color: var(--text);
            background: rgba(0,0,0,0.35);
            outline: none;
        }

        .main {
            min-width: 0;
            padding: 14px;
        }

        .topbar {
            min-height: 58px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
            padding: 10px 14px;
            border: 1px solid var(--stroke);
            border-radius: 8px;
            background: rgba(10, 13, 11, 0.78);
            backdrop-filter: blur(18px);
            box-shadow: 0 12px 38px rgba(0,0,0,0.28);
        }

        .topbar h2 {
            margin: 0;
            font-size: 16px;
            font-weight: 800;
        }

        .subline {
            margin-top: 4px;
            color: var(--muted);
            font-size: 12px;
        }

        .status-strip {
            display: flex;
            align-items: center;
            gap: 10px;
            flex-wrap: wrap;
            color: var(--muted);
            font-size: 12px;
        }

        .live-dot {
            width: 9px;
            height: 9px;
            border-radius: 999px;
            background: var(--neon);
            box-shadow: 0 0 14px var(--neon);
            animation: pulse 1.6s infinite;
        }

        .grid {
            display: grid;
            grid-template-columns: minmax(0, 1.45fr) minmax(330px, 0.55fr);
            gap: 14px;
            margin-top: 14px;
        }

        .map-panel,
        .panel,
        .stat-card {
            border: 1px solid var(--stroke);
            border-radius: 8px;
            background: var(--panel);
            backdrop-filter: blur(18px);
            box-shadow: 0 18px 42px rgba(0,0,0,0.30);
        }

        .map-panel {
            min-height: 620px;
            position: relative;
            overflow: hidden;
        }

        #map {
            position: absolute;
            inset: 0;
        }

        .map-vignette {
            position: absolute;
            inset: 0;
            pointer-events: none;
            box-shadow: inset 0 0 80px rgba(0,0,0,0.86);
            z-index: 1;
        }

        .map-hud {
            position: absolute;
            left: 14px;
            right: 14px;
            bottom: 14px;
            z-index: 2;
            display: grid;
            grid-template-columns: repeat(3, minmax(0, 1fr));
            gap: 10px;
        }

        .hud-card,
        .floating-card {
            padding: 12px;
            border: 1px solid var(--stroke);
            border-radius: 8px;
            background: rgba(4, 8, 6, 0.76);
            backdrop-filter: blur(16px);
        }

        .hud-card span,
        .stat-label,
        .panel-title span {
            color: var(--muted);
            font-size: 11px;
            text-transform: uppercase;
            font-weight: 800;
        }

        .hud-card strong {
            display: block;
            margin-top: 5px;
            font-size: 18px;
            color: var(--neon);
            text-shadow: 0 0 15px rgba(167,255,61,0.44);
        }

        .floating-card {
            position: absolute;
            top: 14px;
            left: 14px;
            z-index: 2;
            width: min(360px, calc(100% - 28px));
        }

        .floating-card h3 {
            margin: 4px 0 6px;
            font-size: 18px;
        }

        .floating-card p {
            margin: 0;
            color: var(--muted);
            line-height: 1.55;
            font-size: 12px;
        }

        .side-stack {
            display: grid;
            gap: 14px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(2, minmax(0, 1fr));
            gap: 10px;
        }

        .stat-card {
            padding: 14px;
            position: relative;
            overflow: hidden;
        }

        .stat-card::after {
            content: "";
            position: absolute;
            inset: auto 10px -30px auto;
            width: 80px;
            height: 80px;
            border-radius: 999px;
            background: rgba(167,255,61,0.13);
            filter: blur(12px);
        }

        .stat-value {
            position: relative;
            margin-top: 8px;
            font-size: 25px;
            font-weight: 900;
            color: var(--text);
        }

        .stat-trend {
            position: relative;
            margin-top: 8px;
            color: var(--neon);
            font-size: 12px;
            font-weight: 700;
        }

        .panel {
            padding: 14px;
            min-height: 210px;
        }

        .panel-title {
            display: flex;
            justify-content: space-between;
            align-items: center;
            gap: 10px;
            margin-bottom: 12px;
        }

        .panel-title h3 {
            margin: 0;
            font-size: 14px;
        }

        .chart-box {
            height: 205px;
            position: relative;
        }

        .lower-grid {
            display: grid;
            grid-template-columns: 1.2fr 0.8fr 0.9fr;
            gap: 14px;
            margin-top: 14px;
        }

        .province-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 12px;
        }

        .province-table th,
        .province-table td {
            padding: 9px 8px;
            border-bottom: 1px solid rgba(255,255,255,0.06);
            text-align: left;
        }

        .province-table th {
            color: var(--muted);
            font-size: 10px;
            text-transform: uppercase;
        }

        .journey {
            display: grid;
            grid-template-columns: repeat(5, 1fr);
            align-items: center;
            gap: 8px;
            min-height: 150px;
        }

        .journey-step {
            min-height: 88px;
            display: grid;
            place-items: center;
            padding: 10px 6px;
            border: 1px solid rgba(167,255,61,0.22);
            border-radius: 8px;
            background: rgba(167,255,61,0.06);
            text-align: center;
            color: var(--muted);
            font-size: 11px;
        }

        .journey-step b {
            display: block;
            color: var(--neon);
            font-size: 24px;
            line-height: 1;
            margin-bottom: 8px;
        }

        .mapboxgl-popup-content {
            color: var(--text);
            background: rgba(4, 8, 6, 0.92);
            border: 1px solid var(--stroke-strong);
            border-radius: 8px;
            box-shadow: var(--shadow);
        }

        .mapboxgl-popup-tip {
            border-top-color: rgba(4, 8, 6, 0.92) !important;
        }

        .centre-marker {
            width: 22px;
            height: 22px;
            border: 2px solid #071007;
            border-radius: 999px;
            background: var(--neon);
            box-shadow: 0 0 0 0 rgba(167,255,61,0.8), 0 0 20px rgba(167,255,61,0.9);
            animation: markerPulse 1.8s infinite;
            cursor: pointer;
        }

        .error-banner {
            display: none;
            margin-top: 14px;
            padding: 12px 14px;
            border: 1px solid rgba(255, 92, 122, 0.42);
            border-radius: 8px;
            color: #ffdbe3;
            background: rgba(255, 92, 122, 0.14);
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.45; transform: scale(1.45); }
        }

        @keyframes markerPulse {
            0% { box-shadow: 0 0 0 0 rgba(167,255,61,0.78), 0 0 20px rgba(167,255,61,0.8); }
            70% { box-shadow: 0 0 0 18px rgba(167,255,61,0), 0 0 20px rgba(167,255,61,0.8); }
            100% { box-shadow: 0 0 0 0 rgba(167,255,61,0), 0 0 20px rgba(167,255,61,0.8); }
        }

        @media (max-width: 1180px) {
            .shell { grid-template-columns: 1fr; }
            .sidebar {
                position: relative;
                height: auto;
                display: grid;
                grid-template-columns: 1fr;
            }
            .grid,
            .lower-grid { grid-template-columns: 1fr; }
            .map-panel { min-height: 560px; }
        }

        @media (max-width: 720px) {
            .main { padding: 10px; }
            .topbar { align-items: flex-start; flex-direction: column; }
            .stats-grid,
            .map-hud { grid-template-columns: 1fr; }
            .map-panel { min-height: 680px; }
            .journey { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
<div class="shell">
    <aside class="sidebar">
        <div class="brand">
            <div class="brand-mark">R</div>
            <div>
                <h1>Recycle Ekhaya</h1>
                <span>Smart City GIS Console</span>
            </div>
        </div>

        <div class="user-chip">
            <small>Operator</small>
            <strong><%= firstName %></strong>
        </div>

        <span class="section-label">Main</span>
        <a class="nav-link" href="household_user_dashboard.jsp">Dashboard</a>
        <a class="nav-link active" href="AIDashboardServlet.do">Interactive Map</a>
        <a class="nav-link" href="schedule_pickup.jsp">Pickup Request</a>
        <a class="nav-link" href="wallet.jsp">Wallet</a>

        <span class="section-label">Data Layers</span>
        <label class="filter-row">Household Heatmap <input id="toggleHeatmap" type="checkbox" checked></label>
        <label class="filter-row">Household Clusters <input id="toggleHouseholds" type="checkbox" checked></label>
        <label class="filter-row">Recycle Centres <input id="toggleCentres" type="checkbox" checked></label>
        <label class="filter-row">Province Density <input id="toggleProvinces" type="checkbox" checked></label>

        <span class="section-label">Smart Filter</span>
        <select id="provinceFilter" class="province-filter">
            <option value="all">All provinces</option>
        </select>

        <span class="section-label">Session</span>
        <a class="nav-link" href="LogoutServlet.do">Sign Out</a>
    </aside>

    <main class="main">
        <header class="topbar">
            <div>
                <h2>Good afternoon, <%= firstName %></h2>
                <div class="subline">Live recycling intelligence for South Africa</div>
            </div>
            <div class="status-strip">
                <span class="live-dot"></span>
                <span>Live MySQL feed</span>
                <span id="lastUpdated">Waiting for sync...</span>
            </div>
        </header>

        <div id="errorBanner" class="error-banner"></div>

        <section class="grid">
            <div class="map-panel">
                <div id="map"></div>
                <div class="map-vignette"></div>
                <div class="floating-card">
                    <span class="stat-label">Interactive national layer</span>
                    <h3>South Africa Recycling Network</h3>
                    <p>Heat intensity reflects household pickup activity. Centre beacons pulse as live operational nodes.</p>
                </div>
                <div class="map-hud">
                    <div class="hud-card"><span>Active centres</span><strong id="hudCentres">0</strong></div>
                    <div class="hud-card"><span>Household nodes</span><strong id="hudHouseholds">0</strong></div>
                    <div class="hud-card"><span>Completed pickups</span><strong id="hudCompleted">0</strong></div>
                </div>
            </div>

            <div class="side-stack">
                <div class="stats-grid">
                    <div class="stat-card">
                        <span class="stat-label">Households</span>
                        <div class="stat-value" id="statHouseholds">0</div>
                        <div class="stat-trend">Cluster-ready network</div>
                    </div>
                    <div class="stat-card">
                        <span class="stat-label">Requests</span>
                        <div class="stat-value" id="statRequests">0</div>
                        <div class="stat-trend"><span id="statPending">0</span> pending</div>
                    </div>
                    <div class="stat-card">
                        <span class="stat-label">Recovered weight</span>
                        <div class="stat-value" id="statWeight">0 kg</div>
                        <div class="stat-trend">Diverted from landfill</div>
                    </div>
                    <div class="stat-card">
                        <span class="stat-label">Rewards paid</span>
                        <div class="stat-value" id="statRewards">R0</div>
                        <div class="stat-trend">Household circular value</div>
                    </div>
                </div>

                <div class="panel">
                    <div class="panel-title">
                        <h3>Recycling Efficiency by Province</h3>
                        <span>Live ranking</span>
                    </div>
                    <div class="chart-box"><canvas id="provinceChart"></canvas></div>
                </div>

                <div class="panel">
                    <div class="panel-title">
                        <h3>Environmental Impact</h3>
                        <span>Estimated</span>
                    </div>
                    <div class="stats-grid">
                        <div class="stat-card">
                            <span class="stat-label">CO2 reduced</span>
                            <div class="stat-value" id="impactCo2">0 kg</div>
                        </div>
                        <div class="stat-card">
                            <span class="stat-label">Water saved</span>
                            <div class="stat-value" id="impactWater">0 L</div>
                        </div>
                        <div class="stat-card">
                            <span class="stat-label">Energy saved</span>
                            <div class="stat-value" id="impactEnergy">0 kWh</div>
                        </div>
                        <div class="stat-card">
                            <span class="stat-label">Landfill diverted</span>
                            <div class="stat-value" id="impactLandfill">0 kg</div>
                        </div>
                    </div>
                </div>
            </div>
        </section>

        <section class="lower-grid">
            <div class="panel">
                <div class="panel-title">
                    <h3>Historical Recycling Trend</h3>
                    <span>12 months</span>
                </div>
                <div class="chart-box"><canvas id="trendChart"></canvas></div>
            </div>

            <div class="panel">
                <div class="panel-title">
                    <h3>Material Composition</h3>
                    <span>Pickup mix</span>
                </div>
                <div class="chart-box"><canvas id="materialChart"></canvas></div>
            </div>

            <div class="panel">
                <div class="panel-title">
                    <h3>Journey of Reused Material</h3>
                    <span>Lifecycle</span>
                </div>
                <div class="journey">
                    <div class="journey-step"><b>01</b>Collected</div>
                    <div class="journey-step"><b>02</b>Sorted</div>
                    <div class="journey-step"><b>03</b>Processed</div>
                    <div class="journey-step"><b>04</b>Recovered</div>
                    <div class="journey-step"><b>05</b>Reused</div>
                </div>
            </div>
        </section>

        <section class="lower-grid">
            <div class="panel">
                <div class="panel-title">
                    <h3>Province Analytics</h3>
                    <span>Hover map nodes for popups</span>
                </div>
                <table class="province-table">
                    <thead>
                    <tr>
                        <th>Province</th>
                        <th>Households</th>
                        <th>Centres</th>
                        <th>Requests</th>
                        <th>Weight</th>
                    </tr>
                    </thead>
                    <tbody id="provinceRows"></tbody>
                </table>
            </div>

            <div class="panel">
                <div class="panel-title">
                    <h3>Material Operations</h3>
                    <span>Top streams</span>
                </div>
                <table class="province-table">
                    <thead>
                    <tr>
                        <th>Material</th>
                        <th>Items</th>
                        <th>Weight</th>
                    </tr>
                    </thead>
                    <tbody id="materialRows"></tbody>
                </table>
            </div>

            <div class="panel">
                <div class="panel-title">
                    <h3>Active Recycling Centres</h3>
                    <span>Map beacons</span>
                </div>
                <table class="province-table">
                    <thead>
                    <tr>
                        <th>Centre</th>
                        <th>Province</th>
                        <th>Pickups</th>
                    </tr>
                    </thead>
                    <tbody id="centreRows"></tbody>
                </table>
            </div>
        </section>
    </main>
</div>

<script>
    const API_URL = '<%= request.getContextPath() %>/api/ai-analytics';
    const MAPBOX_TOKEN = '<%= mapboxToken %>';
    const neon = '#a7ff3d';
    const cyan = '#4be7ff';
    let dashboardData = null;
    let map = null;
    let mapReady = false;
    let centreMarkers = [];
    let provinceChart = null;
    let trendChart = null;
    let materialChart = null;
    let provinceFilter = 'all';

    Chart.defaults.color = '#93a994';
    Chart.defaults.borderColor = 'rgba(167,255,61,0.14)';
    Chart.defaults.font.family = 'Inter';

    document.addEventListener('DOMContentLoaded', function () {
        initCharts();
        initMap();
        bindControls();
        refreshDashboard();
        setInterval(refreshDashboard, 30000);
    });

    function initMap() {
        if (!MAPBOX_TOKEN) {
            showError('Mapbox token is missing in web.xml.');
            return;
        }

        mapboxgl.accessToken = MAPBOX_TOKEN;
        map = new mapboxgl.Map({
            container: 'map',
            style: 'mapbox://styles/mapbox/dark-v11',
            center: [24.4, -29.1],
            zoom: 4.55,
            pitch: 47,
            bearing: -12,
            attributionControl: false
        });

        map.addControl(new mapboxgl.NavigationControl({ visualizePitch: true }), 'top-right');

        map.on('load', function () {
            mapReady = true;
            addMapSourcesAndLayers();
            if (dashboardData) {
                renderMap(dashboardData);
            }
        });
    }

    function addMapSourcesAndLayers() {
        map.addSource('householdHeat', { type: 'geojson', data: emptyFeatureCollection() });
        map.addLayer({
            id: 'household-heatmap',
            type: 'heatmap',
            source: 'householdHeat',
            paint: {
                'heatmap-weight': ['interpolate', ['linear'], ['get', 'intensity'], 0, 0, 8, 1],
                'heatmap-intensity': ['interpolate', ['linear'], ['zoom'], 4, 1.2, 8, 2.8],
                'heatmap-color': [
                    'interpolate', ['linear'], ['heatmap-density'],
                    0, 'rgba(0,0,0,0)',
                    0.18, 'rgba(70,255,160,0.18)',
                    0.45, 'rgba(167,255,61,0.56)',
                    0.75, 'rgba(255,209,102,0.82)',
                    1, 'rgba(255,92,122,0.95)'
                ],
                'heatmap-radius': ['interpolate', ['linear'], ['zoom'], 4, 24, 8, 46],
                'heatmap-opacity': 0.72
            }
        });

        map.addSource('households', {
            type: 'geojson',
            data: emptyFeatureCollection(),
            cluster: true,
            clusterMaxZoom: 10,
            clusterRadius: 46
        });
        map.addLayer({
            id: 'household-clusters',
            type: 'circle',
            source: 'households',
            filter: ['has', 'point_count'],
            paint: {
                'circle-color': ['step', ['get', 'point_count'], '#73ff66', 15, '#a7ff3d', 45, '#ffd166'],
                'circle-radius': ['step', ['get', 'point_count'], 17, 15, 23, 45, 31],
                'circle-opacity': 0.86,
                'circle-stroke-color': '#071007',
                'circle-stroke-width': 2
            }
        });
        map.addLayer({
            id: 'household-cluster-count',
            type: 'symbol',
            source: 'households',
            filter: ['has', 'point_count'],
            layout: { 'text-field': ['get', 'point_count_abbreviated'], 'text-size': 12 },
            paint: { 'text-color': '#071007' }
        });
        map.addLayer({
            id: 'household-points',
            type: 'circle',
            source: 'households',
            filter: ['!', ['has', 'point_count']],
            paint: {
                'circle-color': cyan,
                'circle-radius': 5,
                'circle-opacity': 0.82,
                'circle-stroke-color': neon,
                'circle-stroke-width': 1
            }
        });

        map.addSource('provinces', { type: 'geojson', data: emptyFeatureCollection() });
        map.addLayer({
            id: 'province-density',
            type: 'circle',
            source: 'provinces',
            paint: {
                'circle-color': neon,
                'circle-radius': ['interpolate', ['linear'], ['get', 'requests'], 0, 18, 100, 52],
                'circle-opacity': 0.18,
                'circle-stroke-color': neon,
                'circle-stroke-opacity': 0.48,
                'circle-stroke-width': 1.5
            }
        });

        const popup = new mapboxgl.Popup({ closeButton: false, closeOnClick: false });
        map.on('mouseenter', 'province-density', function (e) {
            map.getCanvas().style.cursor = 'pointer';
            const p = e.features[0].properties;
            popup.setLngLat(e.features[0].geometry.coordinates)
                .setHTML('<strong>' + p.province + '</strong><br>Households: ' + p.households + '<br>Centres: ' + p.centres + '<br>Requests: ' + p.requests + '<br>Weight: ' + formatKg(p.weightKg))
                .addTo(map);
        });
        map.on('mouseleave', 'province-density', function () {
            map.getCanvas().style.cursor = '';
            popup.remove();
        });
    }

    function initCharts() {
        provinceChart = new Chart(document.getElementById('provinceChart'), {
            type: 'bar',
            data: { labels: [], datasets: [{ label: 'Requests', data: [], backgroundColor: gradientFill() }] },
            options: chartOptions(false)
        });

        trendChart = new Chart(document.getElementById('trendChart'), {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Pickups',
                    data: [],
                    borderColor: neon,
                    backgroundColor: 'rgba(167,255,61,0.18)',
                    fill: true,
                    tension: 0.42,
                    pointBackgroundColor: neon,
                    pointBorderColor: '#071007'
                }]
            },
            options: chartOptions(true)
        });

        materialChart = new Chart(document.getElementById('materialChart'), {
            type: 'doughnut',
            data: { labels: [], datasets: [{ data: [], backgroundColor: [neon, cyan, '#ffd166', '#ff5c7a', '#b8f7ff', '#74d83c', '#d7ff8a'] }] },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: { position: 'right', labels: { boxWidth: 10, color: '#d8ead6' } }
                },
                cutout: '62%'
            }
        });
    }

    function chartOptions(fillArea) {
        return {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { display: false } },
            scales: {
                x: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#93a994' } },
                y: { beginAtZero: true, grid: { color: 'rgba(167,255,61,0.12)' }, ticks: { color: '#93a994' } }
            },
            elements: { line: { fill: fillArea } }
        };
    }

    function gradientFill() {
        return 'rgba(167,255,61,0.82)';
    }

    function bindControls() {
        document.getElementById('toggleHeatmap').addEventListener('change', function () {
            setLayerVisibility('household-heatmap', this.checked);
        });
        document.getElementById('toggleHouseholds').addEventListener('change', function () {
            setLayerVisibility('household-clusters', this.checked);
            setLayerVisibility('household-cluster-count', this.checked);
            setLayerVisibility('household-points', this.checked);
        });
        document.getElementById('toggleCentres').addEventListener('change', function () {
            centreMarkers.forEach(function (marker) {
                marker.getElement().style.display = document.getElementById('toggleCentres').checked ? 'block' : 'none';
            });
        });
        document.getElementById('toggleProvinces').addEventListener('change', function () {
            setLayerVisibility('province-density', this.checked);
        });
        document.getElementById('provinceFilter').addEventListener('change', function () {
            provinceFilter = this.value;
            if (dashboardData) {
                renderDashboard(dashboardData);
            }
        });
    }

    async function refreshDashboard() {
        try {
            const response = await fetch(API_URL, { cache: 'no-store' });
            if (!response.ok) {
                throw new Error('Analytics API returned ' + response.status);
            }
            dashboardData = await response.json();
            hideError();
            renderDashboard(dashboardData);
        } catch (error) {
            showError(error.message);
        }
    }

    function renderDashboard(data) {
        const filtered = filterData(data);
        renderStats(filtered);
        renderCharts(filtered);
        renderTables(filtered);
        populateProvinceFilter(data.provinces || []);
        if (mapReady) {
            renderMap(filtered);
        }
        document.getElementById('lastUpdated').textContent = 'Updated ' + new Date(data.generatedAt || Date.now()).toLocaleTimeString();
    }

    function filterData(data) {
        if (provinceFilter === 'all') {
            return data;
        }
        const copy = JSON.parse(JSON.stringify(data));
        copy.provinces = (copy.provinces || []).filter(function (p) { return p.province === provinceFilter; });
        copy.households = (copy.households || []).filter(function (p) { return p.province === provinceFilter; });
        copy.centres = (copy.centres || []).filter(function (p) { return p.province === provinceFilter; });
        return copy;
    }

    function renderStats(data) {
        const summary = data.summary || {};
        const impact = data.impact || {};
        setText('statHouseholds', formatNumber(summary.households));
        setText('statRequests', formatNumber(summary.requests));
        setText('statPending', formatNumber(summary.pendingPickups));
        setText('statWeight', formatKg(summary.totalWeightKg));
        setText('statRewards', 'R' + formatNumber(summary.walletRewards));
        setText('hudCentres', formatNumber((data.centres || []).length || summary.centres));
        setText('hudHouseholds', formatNumber((data.households || []).length || summary.households));
        setText('hudCompleted', formatNumber(summary.completedPickups));
        setText('impactCo2', formatKg(impact.co2ReducedKg));
        setText('impactWater', formatNumber(impact.waterSavedLitres) + ' L');
        setText('impactEnergy', formatNumber(impact.energySavedKwh) + ' kWh');
        setText('impactLandfill', formatKg(impact.landfillDivertedKg));
    }

    function renderCharts(data) {
        const provinces = (data.provinces || []).slice().sort(function (a, b) { return b.requests - a.requests; }).slice(0, 6);
        provinceChart.data.labels = provinces.map(function (p) { return p.province; });
        provinceChart.data.datasets[0].data = provinces.map(function (p) { return p.requests; });
        provinceChart.update();

        const trend = data.trend || [];
        trendChart.data.labels = trend.map(function (p) { return p.month; });
        trendChart.data.datasets[0].data = trend.map(function (p) { return p.pickups; });
        trendChart.update();

        const materials = data.materials || [];
        materialChart.data.labels = materials.map(function (m) { return m.material; });
        materialChart.data.datasets[0].data = materials.map(function (m) { return m.pickups; });
        materialChart.update();
    }

    function renderTables(data) {
        const provinces = (data.provinces || []).slice().sort(function (a, b) { return b.requests - a.requests; });
        document.getElementById('provinceRows').innerHTML = provinces.map(function (p) {
            return '<tr><td>' + p.province + '</td><td>' + p.households + '</td><td>' + p.centres + '</td><td>' + p.requests + '</td><td>' + formatKg(p.weightKg) + '</td></tr>';
        }).join('') || '<tr><td colspan="5">No province data available.</td></tr>';

        const materials = data.materials || [];
        document.getElementById('materialRows').innerHTML = materials.map(function (m) {
            return '<tr><td>' + m.material + '</td><td>' + m.pickups + '</td><td>' + formatKg(m.weightKg) + '</td></tr>';
        }).join('') || '<tr><td colspan="3">No material data available.</td></tr>';

        const centres = (data.centres || []).slice(0, 8);
        document.getElementById('centreRows').innerHTML = centres.map(function (c) {
            return '<tr><td>' + c.name + '</td><td>' + c.province + '</td><td>' + c.completedPickups + '</td></tr>';
        }).join('') || '<tr><td colspan="3">No centre coordinates available.</td></tr>';
    }

    function renderMap(data) {
        const households = pointsToFeatures(data.households || []);
        const centres = data.centres || [];
        const provinces = provinceToFeatures(data.provinces || []);

        updateSource('householdHeat', households);
        updateSource('households', households);
        updateSource('provinces', provinces);
        renderCentreMarkers(centres);
    }

    function renderCentreMarkers(centres) {
        centreMarkers.forEach(function (marker) { marker.remove(); });
        centreMarkers = [];

        centres.forEach(function (centre) {
            const el = document.createElement('div');
            el.className = 'centre-marker';
            const popup = new mapboxgl.Popup({ offset: 18 }).setHTML(
                '<strong>' + centre.name + '</strong><br>' +
                centre.address + '<br>' +
                'Completed pickups: ' + centre.completedPickups
            );
            const marker = new mapboxgl.Marker(el)
                .setLngLat([centre.longitude, centre.latitude])
                .setPopup(popup)
                .addTo(map);
            marker.getElement().style.display = document.getElementById('toggleCentres').checked ? 'block' : 'none';
            centreMarkers.push(marker);
        });
    }

    function pointsToFeatures(points) {
        return {
            type: 'FeatureCollection',
            features: points.map(function (point) {
                return {
                    type: 'Feature',
                    geometry: { type: 'Point', coordinates: [point.longitude, point.latitude] },
                    properties: point
                };
            })
        };
    }

    function provinceToFeatures(provinces) {
        return {
            type: 'FeatureCollection',
            features: provinces.map(function (province) {
                return {
                    type: 'Feature',
                    geometry: { type: 'Point', coordinates: [province.longitude, province.latitude] },
                    properties: province
                };
            })
        };
    }

    function populateProvinceFilter(provinces) {
        const select = document.getElementById('provinceFilter');
        const current = select.value;
        const options = ['<option value="all">All provinces</option>'].concat(provinces.map(function (province) {
            return '<option value="' + province.province + '">' + province.province + '</option>';
        }));
        select.innerHTML = options.join('');
        select.value = current || 'all';
    }

    function updateSource(id, data) {
        const source = map.getSource(id);
        if (source) {
            source.setData(data);
        }
    }

    function setLayerVisibility(id, visible) {
        if (map && map.getLayer(id)) {
            map.setLayoutProperty(id, 'visibility', visible ? 'visible' : 'none');
        }
    }

    function emptyFeatureCollection() {
        return { type: 'FeatureCollection', features: [] };
    }

    function setText(id, value) {
        document.getElementById(id).textContent = value;
    }

    function formatNumber(value) {
        const number = Number(value || 0);
        return number.toLocaleString('en-ZA', { maximumFractionDigits: number >= 100 ? 0 : 1 });
    }

    function formatKg(value) {
        return formatNumber(value) + ' kg';
    }

    function showError(message) {
        const banner = document.getElementById('errorBanner');
        banner.textContent = message;
        banner.style.display = 'block';
    }

    function hideError() {
        document.getElementById('errorBanner').style.display = 'none';
    }
</script>
</body>
</html>
