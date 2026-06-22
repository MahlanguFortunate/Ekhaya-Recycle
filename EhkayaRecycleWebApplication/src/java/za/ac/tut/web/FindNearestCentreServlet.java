package za.ac.tut.web;

import za.ac.tut.db.DBManager;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/FindNearestCentreServlet")
public class FindNearestCentreServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        Integer userId = (Integer) session.getAttribute("userId");

        if (userId == null) {
            response.sendRedirect("login.html");
            return;
        }

        try {
            Connection conn = DBManager.getConnection();

            // ========== 1. Get User's Street Address & Coords ==========
            String userSql = "SELECT first_name, street_address, city, province, " +
                             "postal_code, latitude, longitude " +
                             "FROM HOUSEHOLD_USER WHERE user_id = ?";
            PreparedStatement ps = conn.prepareStatement(userSql);
            ps.setInt(1, userId);
            ResultSet rs = ps.executeQuery();

            String userName      = "";
            String streetAddress = "";
            String userCity      = "";
            String userProvince  = "";
            String postalCode    = "";
            double userLat       = 0;
            double userLon       = 0;
            boolean hasCoordinates = false;

            if (rs.next()) {
                userName      = rs.getString("first_name");
                streetAddress = rs.getString("street_address");
                userCity      = rs.getString("city");
                userProvince  = rs.getString("province");
                postalCode    = rs.getString("postal_code");
                userLat       = rs.getDouble("latitude");
                userLon       = rs.getDouble("longitude");
                hasCoordinates = !rs.wasNull() && (userLat != 0 || userLon != 0);
            }
            rs.close();
            ps.close();

            // ========== 2. Geocode Street Address if Coords Missing/Zero ==========
            if (!hasCoordinates && streetAddress != null && !streetAddress.isEmpty()) {
                try {
                    System.out.println("No DB coords — geocoding: " + streetAddress);
                    double[] coords = MapboxGeocodingService.addressToLatLon(
                        streetAddress, userCity, userProvince, postalCode
                    );
                    if (coords != null) {
                        userLat = coords[0];
                        userLon = coords[1];
                        hasCoordinates = true;
                        System.out.println("Geocoded to: " + userLat + ", " + userLon);

                        // Persist back to DB
                        String updateSql = "UPDATE HOUSEHOLD_USER " +
                                           "SET latitude = ?, longitude = ? " +
                                           "WHERE user_id = ?";
                        PreparedStatement updatePs = conn.prepareStatement(updateSql);
                        updatePs.setDouble(1, userLat);
                        updatePs.setDouble(2, userLon);
                        updatePs.setInt(3, userId);
                        updatePs.executeUpdate();
                        updatePs.close();
                        System.out.println("Saved street coords to DB for user " + userId);
                    }
                } catch (Exception geoEx) {
                    System.err.println("Geocoding failed: " + geoEx.getMessage());
                }
            }

            if (!hasCoordinates) {
                request.setAttribute("errorMessage",
                    "Your street address could not be located. " +
                    "Please update your address in your profile.");
                request.getRequestDispatcher("nearestCentre.jsp").forward(request, response);
                return;
            }

            // ========== 3. Get All Centres with Coordinates ==========
            String centreSql = "SELECT user_id, centre_name, street_address, city, province, " +
                               "postal_code, latitude, longitude " +
                               "FROM RECYCLE_CENTRE " +
                               "WHERE latitude IS NOT NULL AND longitude IS NOT NULL";
            ps = conn.prepareStatement(centreSql);
            rs = ps.executeQuery();

            List<CentreWithDistance> centres = new ArrayList<>();

            while (rs.next()) {
                CentreWithDistance centre = new CentreWithDistance();
                centre.id         = rs.getInt("user_id");
                centre.name       = rs.getString("centre_name");
                centre.address    = rs.getString("street_address");
                centre.city       = rs.getString("city");
                centre.province   = rs.getString("province");
                centre.postalCode = rs.getString("postal_code");
                centre.latitude   = rs.getDouble("latitude");
                centre.longitude  = rs.getDouble("longitude");

                // Distance from user's street address coords
                centre.distance = HaversineDistanceService.calculateDistance(
                    userLat, userLon, centre.latitude, centre.longitude
                );

                centres.add(centre);
            }
            rs.close();
            ps.close();
            conn.close();

            // ========== 4. Sort by Distance ==========
            centres.sort((a, b) -> Double.compare(a.distance, b.distance));

            // ========== 5. AI Recommendation ==========
            WekaAIService aiService = new WekaAIService();
            String aiRecommendation = "";
            if (!centres.isEmpty()) {
                aiRecommendation = aiService.recommendCentre(
                    centres.get(0).distance, userCity
                );
            }

            // ========== 6. Set Attributes for JSP ==========
            request.setAttribute("userName",         userName);
            request.setAttribute("userLat",          userLat);
            request.setAttribute("userLon",          userLon);
            request.setAttribute("centres",          centres);
            request.setAttribute("aiRecommendation", aiRecommendation);
            request.setAttribute("totalCentres",     centres.size());

            request.getRequestDispatcher("nearestCentre.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("errorMessage", "Error finding centres: " + e.getMessage());
            request.getRequestDispatcher("nearestCentre.jsp").forward(request, response);
        }
    }

    public static class CentreWithDistance {
        public int    id;
        public String name;
        public String address;
        public String city;
        public String province;
        public String postalCode;
        public double latitude;
        public double longitude;
        public double distance;
    }
}
