package za.ac.tut.web;

import za.ac.tut.db.DBManager;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/GeocodeAllCentresServlet")
public class GeocodeAllCentresServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println("<html><head><title>Geocoding All Centres</title>");
        out.println("<style>");
        out.println("body { font-family: monospace; background: #111; color: #0f0; padding: 20px; }");
        out.println(".success { color: #0f0; }");
        out.println(".error { color: #f00; }");
        out.println(".info { color: #ff0; }");
        out.println(".skip { color: #888; }");
        out.println("pre { background: #222; padding: 10px; overflow-x: auto; }");
        out.println("</style></head>");
        out.println("<body><h1>Geocoding All Centres</h1><pre>");

        try {
            Connection conn = DBManager.getConnection();

            // Check and add latitude/longitude columns if they don't exist
            checkAndAddColumns(conn, out);

            // Fetch ALL centres regardless of existing coords
            String selectSql = "SELECT user_id, centre_name, street_address, " +
                               "city, province, postal_code, latitude, longitude " +
                               "FROM RECYCLE_CENTRE";
            PreparedStatement ps = conn.prepareStatement(selectSql);
            ResultSet rs = ps.executeQuery();

            int updated = 0;
            int failed = 0;
            int skipped = 0;

            out.println("<span class='info'>=== Starting Centre Geocoding ===</span>\n");

            while (rs.next()) {
                int centreId = rs.getInt("user_id");
                String centreName = rs.getString("centre_name");
                String streetAddress = rs.getString("street_address");
                String city = rs.getString("city");
                String province = rs.getString("province");
                String postalCode = rs.getString("postal_code");
                double existingLat = rs.getDouble("latitude");
                double existingLon = rs.getDouble("longitude");

                // Skip if coordinates are already set and not default
                if (existingLat != 0 && existingLon != 0) {
                    out.println("<span class='skip'>SKIP (already has coordinates):</span> " + 
                                centreName + " → " + existingLat + ", " + existingLon);
                    skipped++;
                    continue;
                }

                out.println("<span class='info'>Geocoding:</span> " + centreName);
                out.println("  Address: " + streetAddress + ", " + city + ", " + province);
                out.flush();

                try {
                    // Use Mapbox geocoding with street-first lookup
                    double[] coords = MapboxGeocodingService.addressToLatLon(
                        streetAddress, city, province, postalCode
                    );

                    if (coords != null) {
                        String updateSql = "UPDATE RECYCLE_CENTRE " +
                                           "SET latitude = ?, longitude = ? " +
                                           "WHERE user_id = ?";
                        PreparedStatement updatePs = conn.prepareStatement(updateSql);
                        updatePs.setDouble(1, coords[0]);
                        updatePs.setDouble(2, coords[1]);
                        updatePs.setInt(3, centreId);
                        int rowsUpdated = updatePs.executeUpdate();
                        updatePs.close();

                        if (rowsUpdated > 0) {
                            out.println("  <span class='success'>✅ Updated → " + 
                                        coords[0] + ", " + coords[1] + "</span>");
                            updated++;
                        } else {
                            out.println("  <span class='error'>❌ Update failed - no rows affected</span>");
                            failed++;
                        }
                    } else {
                        // Try to get just city coordinates as final fallback
                        out.println("  <span class='info'>Street-level failed, trying city coordinates...</span>");
                        double[] cityCoords = MapboxGeocodingService.getCityCoordinates(city, province);
                        
                        if (cityCoords != null) {
                            String updateSql = "UPDATE RECYCLE_CENTRE " +
                                               "SET latitude = ?, longitude = ? " +
                                               "WHERE user_id = ?";
                            PreparedStatement updatePs = conn.prepareStatement(updateSql);
                            updatePs.setDouble(1, cityCoords[0]);
                            updatePs.setDouble(2, cityCoords[1]);
                            updatePs.setInt(3, centreId);
                            updatePs.executeUpdate();
                            updatePs.close();
                            
                            out.println("  <span class='success'>✅ Updated with city coordinates → " + 
                                        cityCoords[0] + ", " + cityCoords[1] + "</span>");
                            updated++;
                        } else {
                            out.println("  <span class='error'>❌ Failed — no coordinates found</span>");
                            failed++;
                        }
                    }
                } catch (Exception e) {
                    out.println("  <span class='error'>❌ Error: " + e.getMessage() + "</span>");
                    failed++;
                }
                
                // Small delay to respect rate limiting
                Thread.sleep(500);
            }
            rs.close();
            ps.close();

            // Also update current logged-in user if needed
            Integer userId = (Integer) request.getSession().getAttribute("userId");
            if (userId != null) {
                out.println("\n<span class='info'>=== Updating Current User ===</span>");
                updateUserCoordinates(conn, userId, out);
            }

            conn.close();
            
            out.println("\n<span class='info'>=============================</span>");
            out.println("<span class='success'>✅ Geocoding Complete!</span>");
            out.println("  Updated: " + updated);
            out.println("  Failed: " + failed);
            out.println("  Skipped: " + skipped);

        } catch (Exception e) {
            out.println("<span class='error'>FATAL ERROR: " + e.getMessage() + "</span>");
            e.printStackTrace(out);
        }

        out.println("</pre></body></html>");
    }

    private void checkAndAddColumns(Connection conn, PrintWriter out) {
        try {
            // Check if latitude column exists in RECYCLE_CENTRE
            String checkColSql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                                 "WHERE TABLE_NAME = 'RECYCLE_CENTRE' AND COLUMN_NAME = 'latitude'";
            PreparedStatement ps = conn.prepareStatement(checkColSql);
            ResultSet rs = ps.executeQuery();
            rs.next();
            int colExists = rs.getInt(1);
            rs.close();
            ps.close();

            if (colExists == 0) {
                out.println("<span class='info'>Adding latitude/longitude columns to RECYCLE_CENTRE...</span>");
                String alterSql = "ALTER TABLE RECYCLE_CENTRE ADD COLUMN latitude DECIMAL(10,8), " +
                                 "ADD COLUMN longitude DECIMAL(11,8)";
                conn.createStatement().executeUpdate(alterSql);
                out.println("<span class='success'>✅ Columns added to RECYCLE_CENTRE</span>");
            }

            // Check for HOUSEHOLD_USER table
            checkColSql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS " +
                         "WHERE TABLE_NAME = 'HOUSEHOLD_USER' AND COLUMN_NAME = 'latitude'";
            ps = conn.prepareStatement(checkColSql);
            rs = ps.executeQuery();
            rs.next();
            colExists = rs.getInt(1);
            rs.close();
            ps.close();

            if (colExists == 0) {
                out.println("<span class='info'>Adding latitude/longitude columns to HOUSEHOLD_USER...</span>");
                String alterSql = "ALTER TABLE HOUSEHOLD_USER ADD COLUMN latitude DECIMAL(10,8), " +
                                 "ADD COLUMN longitude DECIMAL(11,8)";
                conn.createStatement().executeUpdate(alterSql);
                out.println("<span class='success'>✅ Columns added to HOUSEHOLD_USER</span>");
            }
        } catch (Exception e) {
            out.println("<span class='error'>Error checking/adding columns: " + e.getMessage() + "</span>");
        }
    }

    private void updateUserCoordinates(Connection conn, int userId, PrintWriter out) {
        try {
            String userSql = "SELECT street_address, city, province, postal_code, " +
                             "latitude, longitude FROM HOUSEHOLD_USER WHERE user_id = ?";
            PreparedStatement ups = conn.prepareStatement(userSql);
            ups.setInt(1, userId);
            ResultSet urs = ups.executeQuery();

            if (urs.next()) {
                double uLat = urs.getDouble("latitude");
                double uLon = urs.getDouble("longitude");
                String uStreet = urs.getString("street_address");
                String uCity = urs.getString("city");
                String uProvince = urs.getString("province");
                String uPostal = urs.getString("postal_code");

                if (uLat == 0 && uLon == 0) {
                    out.println("Geocoding user address: " + uStreet + ", " + uCity);
                    
                    // Try to get precise coordinates first
                    double[] coords = MapboxGeocodingService.addressToLatLon(
                        uStreet, uCity, uProvince, uPostal
                    );
                    
                    if (coords != null) {
                        String updateSql = "UPDATE HOUSEHOLD_USER " +
                                           "SET latitude = ?, longitude = ? " +
                                           "WHERE user_id = ?";
                        PreparedStatement uup = conn.prepareStatement(updateSql);
                        uup.setDouble(1, coords[0]);
                        uup.setDouble(2, coords[1]);
                        uup.setInt(3, userId);
                        uup.executeUpdate();
                        uup.close();
                        out.println("  <span class='success'>✅ User updated → " + 
                                    coords[0] + ", " + coords[1] + "</span>");
                    } else {
                        // Fallback to city coordinates
                        double[] cityCoords = MapboxGeocodingService.getCityCoordinates(uCity, uProvince);
                        if (cityCoords != null) {
                            String updateSql = "UPDATE HOUSEHOLD_USER " +
                                               "SET latitude = ?, longitude = ? " +
                                               "WHERE user_id = ?";
                            PreparedStatement uup = conn.prepareStatement(updateSql);
                            uup.setDouble(1, cityCoords[0]);
                            uup.setDouble(2, cityCoords[1]);
                            uup.setInt(3, userId);
                            uup.executeUpdate();
                            uup.close();
                            out.println("  <span class='success'>✅ User updated with city coordinates → " + 
                                        cityCoords[0] + ", " + cityCoords[1] + "</span>");
                        } else {
                            out.println("  <span class='error'>❌ User geocoding failed</span>");
                        }
                    }
                } else {
                    out.println("User already has coordinates: " + uLat + ", " + uLon);
                }
            }
            urs.close();
            ups.close();
        } catch (Exception e) {
            out.println("<span class='error'>Error updating user coordinates: " + e.getMessage() + "</span>");
        }
    }
}
