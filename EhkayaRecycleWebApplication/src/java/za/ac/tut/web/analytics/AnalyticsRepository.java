package za.ac.tut.web.analytics;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.CentrePoint;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.MapPoint;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.MaterialMetric;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.ProvinceMetric;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.Summary;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.TrendPoint;

public class AnalyticsRepository {

    private static final String[] PROVINCES = {
        "Gauteng", "Western Cape", "KwaZulu-Natal", "Eastern Cape", "Free State",
        "Limpopo", "Mpumalanga", "North West", "Northern Cape"
    };

    public Summary loadSummary(Connection conn) throws SQLException {
        Summary summary = new Summary();
        summary.households = count(conn, "SELECT COUNT(*) FROM HOUSEHOLD_USER");
        summary.centres = count(conn, "SELECT COUNT(*) FROM RECYCLE_CENTRE");
        summary.requests = count(conn, "SELECT COUNT(*) FROM PICKUP_REQUEST");
        summary.completedPickups = count(conn, "SELECT COUNT(*) FROM PICKUP_REQUEST WHERE request_status = 'completed'");
        summary.pendingPickups = count(conn, "SELECT COUNT(*) FROM PICKUP_REQUEST WHERE request_status = 'pending'");
        summary.totalWeightKg = number(conn, "SELECT COALESCE(SUM(actual_weight), 0) FROM COLLECTION_RECORD");
        summary.walletRewards = number(conn, "SELECT COALESCE(SUM(amount), 0) FROM WALLET_TRANSACTION WHERE transaction_type = 'credit'");
        return summary;
    }

    public Map<String, ProvinceMetric> loadProvinceMetrics(Connection conn) throws SQLException {
        Map<String, ProvinceMetric> provinces = seedProvinces();
        applyProvinceHouseholds(conn, provinces);
        applyProvinceCentres(conn, provinces);
        applyProvinceRequests(conn, provinces);
        return provinces;
    }

    public void loadHouseholds(Connection conn, AnalyticsDashboardDto dto) throws SQLException {
        String sql = "SELECT hu.user_id, hu.first_name, hu.last_name, hu.city, hu.province, "
                + "hu.latitude, hu.longitude, COUNT(pr.request_id) AS pickup_count "
                + "FROM HOUSEHOLD_USER hu "
                + "LEFT JOIN PICKUP_REQUEST pr ON hu.user_id = pr.household_user_id "
                + "WHERE hu.latitude IS NOT NULL AND hu.longitude IS NOT NULL "
                + "GROUP BY hu.user_id, hu.first_name, hu.last_name, hu.city, hu.province, hu.latitude, hu.longitude";

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                MapPoint point = new MapPoint();
                point.id = rs.getInt("user_id");
                point.name = joinName(rs.getString("first_name"), rs.getString("last_name"));
                point.city = rs.getString("city");
                point.province = normalizeProvince(rs.getString("province"));
                point.latitude = rs.getDouble("latitude");
                point.longitude = rs.getDouble("longitude");
                point.intensity = Math.max(1, rs.getInt("pickup_count"));
                if (isSouthAfrica(point.latitude, point.longitude)) {
                    dto.households.add(point);
                }
            }
        }
    }

    public void loadCentres(Connection conn, AnalyticsDashboardDto dto) throws SQLException {
        String sql = "SELECT rc.user_id, rc.centre_name, rc.phone_number, rc.street_address, rc.city, "
                + "rc.province, rc.postal_code, rc.latitude, rc.longitude, COUNT(pr.request_id) AS completed_pickups "
                + "FROM RECYCLE_CENTRE rc "
                + "LEFT JOIN PICKUP_REQUEST pr ON rc.user_id = pr.centre_id AND pr.request_status = 'completed' "
                + "WHERE rc.latitude IS NOT NULL AND rc.longitude IS NOT NULL "
                + "GROUP BY rc.user_id, rc.centre_name, rc.phone_number, rc.street_address, rc.city, "
                + "rc.province, rc.postal_code, rc.latitude, rc.longitude";

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                CentrePoint centre = new CentrePoint();
                centre.id = rs.getInt("user_id");
                centre.name = rs.getString("centre_name");
                centre.phone = rs.getString("phone_number");
                centre.address = joinAddress(rs.getString("street_address"), rs.getString("city"),
                        rs.getString("province"), rs.getString("postal_code"));
                centre.city = rs.getString("city");
                centre.province = normalizeProvince(rs.getString("province"));
                centre.latitude = rs.getDouble("latitude");
                centre.longitude = rs.getDouble("longitude");
                centre.completedPickups = rs.getInt("completed_pickups");
                if (isSouthAfrica(centre.latitude, centre.longitude)) {
                    dto.centres.add(centre);
                }
            }
        }
    }

    public void loadMaterials(Connection conn, AnalyticsDashboardDto dto) throws SQLException {
        String sql = "SELECT rm.material_name, COUNT(*) AS pickups, "
                + "COALESCE(SUM(pi.estimated_weight), 0) AS weight_kg "
                + "FROM PICKUP_ITEM pi "
                + "JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id "
                + "GROUP BY rm.material_name "
                + "ORDER BY pickups DESC, weight_kg DESC "
                + "LIMIT 8";

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                MaterialMetric metric = new MaterialMetric();
                metric.material = rs.getString("material_name");
                metric.pickups = rs.getInt("pickups");
                metric.weightKg = rs.getDouble("weight_kg");
                dto.materials.add(metric);
            }
        }
    }

    public void loadMonthlyTrend(Connection conn, AnalyticsDashboardDto dto) throws SQLException {
        String sql = "SELECT DATE_FORMAT(COALESCE(cr.collection_date, pr.created_date), '%b') AS month_label, "
                + "DATE_FORMAT(COALESCE(cr.collection_date, pr.created_date), '%Y-%m') AS month_key, "
                + "COUNT(DISTINCT pr.request_id) AS pickups, COALESCE(SUM(cr.actual_weight), 0) AS weight_kg "
                + "FROM PICKUP_REQUEST pr "
                + "LEFT JOIN COLLECTION_RECORD cr ON pr.request_id = cr.request_id "
                + "WHERE COALESCE(cr.collection_date, pr.created_date) >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH) "
                + "GROUP BY month_key, month_label "
                + "ORDER BY month_key";

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                TrendPoint point = new TrendPoint();
                point.month = rs.getString("month_label");
                point.pickups = rs.getInt("pickups");
                point.weightKg = rs.getDouble("weight_kg");
                dto.trend.add(point);
            }
        }
    }

    private void applyProvinceHouseholds(Connection conn, Map<String, ProvinceMetric> provinces) throws SQLException {
        String sql = "SELECT province, COUNT(*) AS households FROM HOUSEHOLD_USER GROUP BY province";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ProvinceMetric metric = getProvince(provinces, rs.getString("province"));
                metric.households = rs.getInt("households");
            }
        }
    }

    private void applyProvinceCentres(Connection conn, Map<String, ProvinceMetric> provinces) throws SQLException {
        String sql = "SELECT province, COUNT(*) AS centres FROM RECYCLE_CENTRE GROUP BY province";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ProvinceMetric metric = getProvince(provinces, rs.getString("province"));
                metric.centres = rs.getInt("centres");
            }
        }
    }

    private void applyProvinceRequests(Connection conn, Map<String, ProvinceMetric> provinces) throws SQLException {
        String sql = "SELECT hu.province, COUNT(DISTINCT pr.request_id) AS requests, "
                + "COALESCE(SUM(cr.actual_weight), 0) AS weight_kg "
                + "FROM HOUSEHOLD_USER hu "
                + "LEFT JOIN PICKUP_REQUEST pr ON hu.user_id = pr.household_user_id "
                + "LEFT JOIN COLLECTION_RECORD cr ON pr.request_id = cr.request_id "
                + "GROUP BY hu.province";
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                ProvinceMetric metric = getProvince(provinces, rs.getString("province"));
                metric.requests = rs.getInt("requests");
                metric.weightKg = rs.getDouble("weight_kg");
            }
        }
    }

    private int count(Connection conn, String sql) throws SQLException {
        return (int) number(conn, sql);
    }

    private double number(Connection conn, String sql) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            return rs.next() ? rs.getDouble(1) : 0;
        }
    }

    private Map<String, ProvinceMetric> seedProvinces() {
        Map<String, ProvinceMetric> provinces = new LinkedHashMap<>();
        for (String province : PROVINCES) {
            ProvinceMetric metric = new ProvinceMetric();
            metric.province = province;
            double[] coords = provinceCoordinates(province);
            metric.latitude = coords[0];
            metric.longitude = coords[1];
            provinces.put(province.toLowerCase(), metric);
        }
        return provinces;
    }

    private ProvinceMetric getProvince(Map<String, ProvinceMetric> provinces, String provinceName) {
        String normalized = normalizeProvince(provinceName);
        ProvinceMetric metric = provinces.get(normalized.toLowerCase());
        if (metric == null) {
            metric = new ProvinceMetric();
            metric.province = normalized;
            double[] coords = provinceCoordinates(normalized);
            metric.latitude = coords[0];
            metric.longitude = coords[1];
            provinces.put(normalized.toLowerCase(), metric);
        }
        return metric;
    }

    private String normalizeProvince(String province) {
        if (province == null || province.trim().isEmpty()) {
            return "Unknown";
        }
        String value = province.trim();
        if ("KZN".equalsIgnoreCase(value) || "KwaZulu Natal".equalsIgnoreCase(value)) {
            return "KwaZulu-Natal";
        }
        return value;
    }

    private double[] provinceCoordinates(String province) {
        String value = province == null ? "" : province.toLowerCase();
        if (value.contains("western")) return new double[]{-33.2278, 21.8569};
        if (value.contains("kwazulu")) return new double[]{-28.5306, 30.8958};
        if (value.contains("eastern")) return new double[]{-32.2968, 26.4194};
        if (value.contains("free")) return new double[]{-28.4541, 26.7968};
        if (value.contains("limpopo")) return new double[]{-23.4013, 29.4179};
        if (value.contains("mpumalanga")) return new double[]{-25.5653, 30.5279};
        if (value.contains("north west")) return new double[]{-26.6639, 25.2838};
        if (value.contains("northern")) return new double[]{-29.0467, 21.8569};
        if (value.contains("gauteng")) return new double[]{-26.2708, 28.1123};
        return new double[]{-30.5595, 22.9375};
    }

    private boolean isSouthAfrica(double latitude, double longitude) {
        return latitude >= -35 && latitude <= -22 && longitude >= 16 && longitude <= 33;
    }

    private String joinName(String firstName, String lastName) {
        String name = safe(firstName) + " " + safe(lastName);
        return name.trim();
    }

    private String joinAddress(String street, String city, String province, String postalCode) {
        StringBuilder builder = new StringBuilder();
        append(builder, street);
        append(builder, city);
        append(builder, province);
        append(builder, postalCode);
        return builder.toString();
    }

    private void append(StringBuilder builder, String value) {
        if (value == null || value.trim().isEmpty()) {
            return;
        }
        if (builder.length() > 0) {
            builder.append(", ");
        }
        builder.append(value.trim());
    }

    private String safe(String value) {
        return value == null ? "" : value;
    }
}
