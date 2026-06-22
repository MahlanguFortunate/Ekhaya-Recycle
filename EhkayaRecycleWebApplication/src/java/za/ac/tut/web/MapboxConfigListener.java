package za.ac.tut.web;

import javax.servlet.ServletContextEvent;
import javax.servlet.ServletContextListener;

public class MapboxConfigListener implements ServletContextListener {

    @Override
    public void contextInitialized(ServletContextEvent event) {
        String token = event.getServletContext().getInitParameter("mapbox.access.token");
        MapboxGeocodingService.setAccessToken(token);
    }

    @Override
    public void contextDestroyed(ServletContextEvent event) {
    }
}
