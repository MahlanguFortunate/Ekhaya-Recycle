package za.ac.tut.web;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.security.SecureRandom;
import java.security.cert.X509Certificate;
import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonReader;
import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

public class MapboxGeocodingService {

    private static final String MAPBOX_FORWARD_URL = "https://api.mapbox.com/search/geocode/v6/forward";
    private static String configuredAccessToken;
    private static SSLSocketFactoryHolder sslSocketFactoryHolder;

    public static void setAccessToken(String accessToken) {
        if (accessToken != null && !accessToken.trim().isEmpty()
                && !"PASTE_YOUR_MAPBOX_ACCESS_TOKEN_HERE".equals(accessToken.trim())) {
            configuredAccessToken = accessToken.trim();
        }
    }

    public static double[] addressToLatLon(String street, String city, String province, String postalCode)
            throws Exception {
        double[] streetCoords = addressToStreetLatLon(street, city, province, postalCode);
        if (streetCoords != null) {
            return streetCoords;
        }
        return getCityCoordinates(city, province);
    }

    public static double[] addressToStreetLatLon(String street, String city, String province, String postalCode)
            throws Exception {
        street = clean(street);
        city = clean(city);
        province = clean(province);
        postalCode = clean(postalCode);

        if (street.isEmpty()) {
            return null;
        }

        String url = MAPBOX_FORWARD_URL
                + "?address_line1=" + encode(street)
                + optionalParam("place", city)
                + optionalParam("region", province)
                + optionalParam("postcode", postalCode)
                + "&country=za"
                + "&types=address,street"
                + "&autocomplete=false"
                + "&limit=1"
                + "&access_token=" + encode(getAccessToken());

        return callMapbox(url, true, joinAddress(street, city, province, postalCode));
    }

    public static double[] getCityCoordinates(String city, String province) throws Exception {
        city = clean(city);
        province = clean(province);

        if (city.isEmpty() && province.isEmpty()) {
            return null;
        }

        String query = joinAddress(city, province, "South Africa");
        String url = MAPBOX_FORWARD_URL
                + "?q=" + encode(query)
                + "&country=za"
                + "&types=place,locality"
                + "&autocomplete=false"
                + "&limit=1"
                + "&access_token=" + encode(getAccessToken());

        return callMapbox(url, false, query);
    }

    public static double[] addressToLatLon(String fullAddress) throws Exception {
        fullAddress = clean(fullAddress);
        if (fullAddress.isEmpty()) {
            return null;
        }

        String url = MAPBOX_FORWARD_URL
                + "?q=" + encode(fullAddress)
                + "&country=za"
                + "&types=address,street"
                + "&autocomplete=false"
                + "&limit=1"
                + "&access_token=" + encode(getAccessToken());

        return callMapbox(url, true, fullAddress);
    }

    private static double[] callMapbox(String urlString, boolean requireStreetOrAddress, String originalQuery) throws Exception {
        URL url = new URL(urlString);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        configureHttpsForMapbox(conn);
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);

        int responseCode = conn.getResponseCode();
        if (responseCode != 200) {
            String body = readBody(conn);
            throw new IllegalStateException("Mapbox geocoding returned HTTP " + responseCode + ": " + body);
        }

        try (JsonReader reader = Json.createReader(conn.getInputStream())) {
            JsonObject root = reader.readObject();
            JsonArray features = root.getJsonArray("features");
            if (features == null || features.isEmpty()) {
                return null;
            }

            JsonObject feature = features.getJsonObject(0);
            String featureType = getFeatureType(feature);
            if (requireStreetOrAddress
                    && !"address".equalsIgnoreCase(featureType)
                    && !"street".equalsIgnoreCase(featureType)) {
                return null;
            }

            JsonObject geometry = feature.getJsonObject("geometry");
            if (geometry == null) {
                return null;
            }

            JsonArray coordinates = geometry.getJsonArray("coordinates");
            if (coordinates == null || coordinates.size() < 2) {
                return null;
            }

            double lon = coordinates.getJsonNumber(0).doubleValue();
            double lat = coordinates.getJsonNumber(1).doubleValue();
            if (!isWithinSouthAfrica(lat, lon)) {
                System.out.println("Mapbox result outside South Africa for [" + originalQuery + "]: lat=" + lat + ", lon=" + lon);
                return null;
            }

            String resultName = getResultName(feature);
            System.out.println("Mapbox geocoded [" + originalQuery + "] -> " + resultName
                    + " (" + featureType + ") lat=" + lat + ", lon=" + lon);

            return new double[]{lat, lon};
        } finally {
            conn.disconnect();
        }
    }

    private static String getFeatureType(JsonObject feature) {
        JsonObject properties = feature.getJsonObject("properties");
        if (properties != null && properties.containsKey("feature_type")) {
            return properties.getString("feature_type", "");
        }
        if (feature.containsKey("feature_type")) {
            return feature.getString("feature_type", "");
        }
        return "";
    }

    private static String getResultName(JsonObject feature) {
        JsonObject properties = feature.getJsonObject("properties");
        if (properties != null) {
            if (properties.containsKey("full_address")) {
                return properties.getString("full_address", "");
            }
            if (properties.containsKey("name")) {
                return properties.getString("name", "");
            }
        }
        return "";
    }

    private static void configureHttpsForMapbox(HttpURLConnection conn) throws Exception {
        if (!(conn instanceof HttpsURLConnection)) {
            return;
        }

        HttpsURLConnection https = (HttpsURLConnection) conn;
        https.setSSLSocketFactory(getTrustingSslSocketFactory());
    }

    private static javax.net.ssl.SSLSocketFactory getTrustingSslSocketFactory() throws Exception {
        if (sslSocketFactoryHolder != null) {
            return sslSocketFactoryHolder.socketFactory;
        }

        TrustManager[] trustManagers = new TrustManager[]{
            new X509TrustManager() {
                @Override
                public void checkClientTrusted(X509Certificate[] chain, String authType) {
                }

                @Override
                public void checkServerTrusted(X509Certificate[] chain, String authType) {
                }

                @Override
                public X509Certificate[] getAcceptedIssuers() {
                    return new X509Certificate[0];
                }
            }
        };

        SSLContext context = SSLContext.getInstance("TLS");
        context.init(null, trustManagers, new SecureRandom());
        sslSocketFactoryHolder = new SSLSocketFactoryHolder(context.getSocketFactory());
        return sslSocketFactoryHolder.socketFactory;
    }

    private static class SSLSocketFactoryHolder {
        private final javax.net.ssl.SSLSocketFactory socketFactory;

        private SSLSocketFactoryHolder(javax.net.ssl.SSLSocketFactory socketFactory) {
            this.socketFactory = socketFactory;
        }
    }

    private static String readBody(HttpURLConnection conn) {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getErrorStream(), "UTF-8"))) {
            StringBuilder body = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                body.append(line);
            }
            return body.toString();
        } catch (Exception e) {
            return "";
        }
    }

    private static String getAccessToken() {
        String envToken = System.getenv("MAPBOX_ACCESS_TOKEN");
        if (envToken != null && !envToken.trim().isEmpty()) {
            return envToken.trim();
        }

        String propertyToken = System.getProperty("mapbox.access.token");
        if (propertyToken != null && !propertyToken.trim().isEmpty()) {
            return propertyToken.trim();
        }

        if (configuredAccessToken != null && !configuredAccessToken.trim().isEmpty()) {
            return configuredAccessToken.trim();
        }

        throw new IllegalStateException("Mapbox access token is not configured. Set the mapbox.access.token context-param in web.xml, MAPBOX_ACCESS_TOKEN, or -Dmapbox.access.token.");
    }

    private static String clean(String value) {
        return value == null ? "" : value.trim();
    }

    private static String joinAddress(String... parts) {
        StringBuilder builder = new StringBuilder();
        for (String part : parts) {
            if (part == null || part.trim().isEmpty()) {
                continue;
            }
            if (builder.length() > 0) {
                builder.append(", ");
            }
            builder.append(part.trim());
        }
        return builder.toString();
    }

    private static String encode(String value) throws Exception {
        return URLEncoder.encode(value, "UTF-8");
    }

    private static String optionalParam(String name, String value) throws Exception {
        if (value == null || value.trim().isEmpty()) {
            return "";
        }
        return "&" + name + "=" + encode(value.trim());
    }

    private static boolean isWithinSouthAfrica(double lat, double lon) {
        return lat >= -35 && lat <= -22 && lon >= 16 && lon <= 33;
    }
}