package za.ac.tut.web.analytics;

import java.io.IOException;
import java.sql.Connection;
import javax.json.Json;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

public class SmartCityAnalyticsApiServlet extends HttpServlet {

    private final AnalyticsService analyticsService = new AnalyticsService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.getWriter().write(Json.createObjectBuilder()
                    .add("error", "Please login first.")
                    .build()
                    .toString());
            return;
        }

        try (Connection conn = DBManager.getConnection()) {
            AnalyticsDashboardDto dashboard = analyticsService.buildDashboard(conn);
            response.getWriter().write(dashboard.toJson().toString());
        } catch (Exception e) {
            e.printStackTrace();
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            response.getWriter().write(Json.createObjectBuilder()
                    .add("error", e.getMessage() == null ? "Analytics data could not be loaded." : e.getMessage())
                    .build()
                    .toString());
        }
    }
}
