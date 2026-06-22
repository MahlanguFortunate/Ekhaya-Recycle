package za.ac.tut.web;

public class HaversineDistanceService {
    
    private static final double EARTH_RADIUS_KM = 6371;
    
    public static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
        double[] start = normalizeSouthAfricanCoordinates(lat1, lon1);
        double[] end = normalizeSouthAfricanCoordinates(lat2, lon2);

        double dLat = Math.toRadians(end[0] - start[0]);
        double dLon = Math.toRadians(end[1] - start[1]);
        
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                   Math.cos(Math.toRadians(start[0])) * Math.cos(Math.toRadians(end[0])) *
                   Math.sin(dLon / 2) * Math.sin(dLon / 2);
        
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        
        return EARTH_RADIUS_KM * c;
    }

    private static double[] normalizeSouthAfricanCoordinates(double latitude, double longitude) {
        if (isWithinSouthAfrica(latitude, longitude)) {
            return new double[]{latitude, longitude};
        }

        if (isWithinSouthAfrica(longitude, latitude)) {
            return new double[]{longitude, latitude};
        }

        return new double[]{latitude, longitude};
    }

    private static boolean isWithinSouthAfrica(double latitude, double longitude) {
        return latitude >= -35 && latitude <= -22 && longitude >= 16 && longitude <= 33;
    }
}
