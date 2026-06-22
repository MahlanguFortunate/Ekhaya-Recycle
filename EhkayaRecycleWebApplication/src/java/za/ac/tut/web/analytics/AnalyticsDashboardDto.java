package za.ac.tut.web.analytics;

import java.util.ArrayList;
import java.util.List;
import javax.json.Json;
import javax.json.JsonArrayBuilder;
import javax.json.JsonObject;
import javax.json.JsonObjectBuilder;

public class AnalyticsDashboardDto {

    public Summary summary = new Summary();
    public EnvironmentalImpact impact = new EnvironmentalImpact();
    public List<ProvinceMetric> provinces = new ArrayList<>();
    public List<MapPoint> households = new ArrayList<>();
    public List<CentrePoint> centres = new ArrayList<>();
    public List<MaterialMetric> materials = new ArrayList<>();
    public List<TrendPoint> trend = new ArrayList<>();
    public long generatedAt;

    public JsonObject toJson() {
        JsonObjectBuilder root = Json.createObjectBuilder();
        root.add("generatedAt", generatedAt);
        root.add("summary", summary.toJson());
        root.add("impact", impact.toJson());
        root.add("provinces", toProvinceArray());
        root.add("households", toHouseholdArray());
        root.add("centres", toCentreArray());
        root.add("materials", toMaterialArray());
        root.add("trend", toTrendArray());
        return root.build();
    }

    private JsonArrayBuilder toProvinceArray() {
        JsonArrayBuilder array = Json.createArrayBuilder();
        for (ProvinceMetric province : provinces) {
            array.add(province.toJson());
        }
        return array;
    }

    private JsonArrayBuilder toHouseholdArray() {
        JsonArrayBuilder array = Json.createArrayBuilder();
        for (MapPoint household : households) {
            array.add(household.toJson());
        }
        return array;
    }

    private JsonArrayBuilder toCentreArray() {
        JsonArrayBuilder array = Json.createArrayBuilder();
        for (CentrePoint centre : centres) {
            array.add(centre.toJson());
        }
        return array;
    }

    private JsonArrayBuilder toMaterialArray() {
        JsonArrayBuilder array = Json.createArrayBuilder();
        for (MaterialMetric material : materials) {
            array.add(material.toJson());
        }
        return array;
    }

    private JsonArrayBuilder toTrendArray() {
        JsonArrayBuilder array = Json.createArrayBuilder();
        for (TrendPoint point : trend) {
            array.add(point.toJson());
        }
        return array;
    }

    static String safe(String value) {
        return value == null ? "" : value;
    }

    public static class Summary {
        public int households;
        public int centres;
        public int requests;
        public int completedPickups;
        public int pendingPickups;
        public double totalWeightKg;
        public double walletRewards;

        public JsonObject toJson() {
            return Json.createObjectBuilder()
                    .add("households", households)
                    .add("centres", centres)
                    .add("requests", requests)
                    .add("completedPickups", completedPickups)
                    .add("pendingPickups", pendingPickups)
                    .add("totalWeightKg", totalWeightKg)
                    .add("walletRewards", walletRewards)
                    .build();
        }
    }

    public static class EnvironmentalImpact {
        public double co2ReducedKg;
        public double waterSavedLitres;
        public double energySavedKwh;
        public double landfillDivertedKg;

        public JsonObject toJson() {
            return Json.createObjectBuilder()
                    .add("co2ReducedKg", co2ReducedKg)
                    .add("waterSavedLitres", waterSavedLitres)
                    .add("energySavedKwh", energySavedKwh)
                    .add("landfillDivertedKg", landfillDivertedKg)
                    .build();
        }
    }

    public static class ProvinceMetric {
        public String province;
        public double latitude;
        public double longitude;
        public int households;
        public int centres;
        public int requests;
        public double weightKg;

        public JsonObject toJson() {
            return Json.createObjectBuilder()
                    .add("province", safe(province))
                    .add("latitude", latitude)
                    .add("longitude", longitude)
                    .add("households", households)
                    .add("centres", centres)
                    .add("requests", requests)
                    .add("weightKg", weightKg)
                    .build();
        }
    }

    public static class MapPoint {
        public int id;
        public String name;
        public String city;
        public String province;
        public double latitude;
        public double longitude;
        public double intensity;

        public JsonObject toJson() {
            return Json.createObjectBuilder()
                    .add("id", id)
                    .add("name", safe(name))
                    .add("city", safe(city))
                    .add("province", safe(province))
                    .add("latitude", latitude)
                    .add("longitude", longitude)
                    .add("intensity", intensity)
                    .build();
        }
    }

    public static class CentrePoint extends MapPoint {
        public String phone;
        public String address;
        public int completedPickups;

        @Override
        public JsonObject toJson() {
            return Json.createObjectBuilder()
                    .add("id", id)
                    .add("name", safe(name))
                    .add("city", safe(city))
                    .add("province", safe(province))
                    .add("phone", safe(phone))
                    .add("address", safe(address))
                    .add("latitude", latitude)
                    .add("longitude", longitude)
                    .add("completedPickups", completedPickups)
                    .build();
        }
    }

    public static class MaterialMetric {
        public String material;
        public int pickups;
        public double weightKg;

        public JsonObject toJson() {
            return Json.createObjectBuilder()
                    .add("material", safe(material))
                    .add("pickups", pickups)
                    .add("weightKg", weightKg)
                    .build();
        }
    }

    public static class TrendPoint {
        public String month;
        public int pickups;
        public double weightKg;

        public JsonObject toJson() {
            return Json.createObjectBuilder()
                    .add("month", safe(month))
                    .add("pickups", pickups)
                    .add("weightKg", weightKg)
                    .build();
        }
    }
}
