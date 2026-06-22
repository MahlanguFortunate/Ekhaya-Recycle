package za.ac.tut.web.analytics;

import java.sql.Connection;
import java.util.Map;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.EnvironmentalImpact;
import za.ac.tut.web.analytics.AnalyticsDashboardDto.ProvinceMetric;

public class AnalyticsService {

    private final AnalyticsRepository repository = new AnalyticsRepository();

    public AnalyticsDashboardDto buildDashboard(Connection conn) throws Exception {
        AnalyticsDashboardDto dto = new AnalyticsDashboardDto();
        dto.summary = repository.loadSummary(conn);

        Map<String, ProvinceMetric> provinceMetrics = repository.loadProvinceMetrics(conn);
        dto.provinces.addAll(provinceMetrics.values());

        repository.loadHouseholds(conn, dto);
        repository.loadCentres(conn, dto);
        repository.loadMaterials(conn, dto);
        repository.loadMonthlyTrend(conn, dto);

        dto.impact = calculateImpact(dto.summary.totalWeightKg);
        dto.generatedAt = System.currentTimeMillis();
        return dto;
    }

    private EnvironmentalImpact calculateImpact(double totalWeightKg) {
        EnvironmentalImpact impact = new EnvironmentalImpact();
        impact.landfillDivertedKg = round(totalWeightKg);
        impact.co2ReducedKg = round(totalWeightKg * 1.18);
        impact.waterSavedLitres = round(totalWeightKg * 3.7);
        impact.energySavedKwh = round(totalWeightKg * 2.4);
        return impact;
    }

    private double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
