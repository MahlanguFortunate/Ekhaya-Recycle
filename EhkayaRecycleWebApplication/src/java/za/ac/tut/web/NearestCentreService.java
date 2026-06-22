package za.ac.tut.web;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class NearestCentreService {

    public AssignedCentre findNearestCentre(Connection conn, double pickupLat, double pickupLon)
            throws SQLException {
        String sql = "SELECT user_id, centre_name, street_address, city, province, postal_code, latitude, longitude "
                + "FROM RECYCLE_CENTRE";

        AssignedCentre nearest = null;

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                int centreId = rs.getInt("user_id");
                String streetAddress = rs.getString("street_address");
                String city = rs.getString("city");
                String province = rs.getString("province");
                String postalCode = rs.getString("postal_code");
                double[] centreCoords = resolveCentreStreetCoordinates(
                        conn, centreId, streetAddress, city, province, postalCode);

                if (centreCoords == null) {
                    System.out.println("Skipping centre without street-level coordinates: " + rs.getString("centre_name"));
                    continue;
                }

                double centreLat = centreCoords[0];
                double centreLon = centreCoords[1];
                double distance = HaversineDistanceService.calculateDistance(
                        pickupLat, pickupLon, centreLat, centreLon);
                System.out.println("Distance check: pickup(" + pickupLat + ", " + pickupLon + ") -> "
                        + rs.getString("centre_name") + "(" + centreLat + ", " + centreLon + ") = "
                        + distance + " km");

                if (nearest == null || distance < nearest.distanceKm) {
                    nearest = new AssignedCentre();
                    nearest.centreId = centreId;
                    nearest.name = rs.getString("centre_name");
                    nearest.streetAddress = streetAddress;
                    nearest.city = city;
                    nearest.province = province;
                    nearest.postalCode = postalCode;
                    nearest.latitude = centreLat;
                    nearest.longitude = centreLon;
                    nearest.pickupLatitude = pickupLat;
                    nearest.pickupLongitude = pickupLon;
                    nearest.distanceKm = distance;
                }
            }
        }

        return nearest;
    }

    public double[] resolvePickupCoordinates(Connection conn, int householdUserId, String streetAddress,
                                             String city, String province, String postalCode,
                                             boolean useHouseholdAddress) throws Exception {
        double[] coords = MapboxGeocodingService.addressToStreetLatLon(streetAddress, city, province, postalCode);
        if (coords != null && useHouseholdAddress) {
            updateHouseholdCoordinates(conn, householdUserId, coords[0], coords[1]);
        }
        return coords;
    }

    private double[] resolveCentreStreetCoordinates(Connection conn, int centreId, String streetAddress,
                                                    String city, String province, String postalCode) {
        try {
            double[] coords = MapboxGeocodingService.addressToStreetLatLon(streetAddress, city, province, postalCode);
            if (coords != null) {
                updateCentreCoordinates(conn, centreId, coords[0], coords[1]);
            }
            return coords;
        } catch (Exception e) {
            System.err.println("Street geocoding failed for centre " + centreId + ": " + e.getMessage());
            return null;
        }
    }

    private void updateHouseholdCoordinates(Connection conn, int householdUserId, double latitude, double longitude)
            throws SQLException {
        String sql = "UPDATE HOUSEHOLD_USER SET latitude = ?, longitude = ? WHERE user_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, latitude);
            ps.setDouble(2, longitude);
            ps.setInt(3, householdUserId);
            ps.executeUpdate();
        }
    }

    private void updateCentreCoordinates(Connection conn, int centreId, double latitude, double longitude)
            throws SQLException {
        String sql = "UPDATE RECYCLE_CENTRE SET latitude = ?, longitude = ? WHERE user_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDouble(1, latitude);
            ps.setDouble(2, longitude);
            ps.setInt(3, centreId);
            ps.executeUpdate();
        }
    }

    public static class AssignedCentre {
        public int centreId;
        public String name;
        public String streetAddress;
        public String city;
        public String province;
        public String postalCode;
        public double latitude;
        public double longitude;
        public double pickupLatitude;
        public double pickupLongitude;
        public double distanceKm;

        public String getFormattedDistance() {
            if (distanceKm < 1) {
                return String.format("%.0f m", distanceKm * 1000);
            }
            return String.format("%.2f km", distanceKm);
        }

        public String getDisplayAddress() {
            StringBuilder address = new StringBuilder();
            append(address, streetAddress);
            append(address, city);
            append(address, province);
            append(address, postalCode);
            return address.toString();
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
    }
}
