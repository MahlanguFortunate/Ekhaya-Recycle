// File: src/java/za/ac/tut/web/LoginServlet.java
package za.ac.tut.web;

import java.io.IOException;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.LoginDAO;

public class LoginServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = request.getParameter("email");
        String password = request.getParameter("password");
        
        String url = "login.html";
        
        try {
            LoginDAO dao = new LoginDAO();
            String[] authResults = dao.authenticate(email, password);

            if (authResults != null) {
                String userIdStr = authResults[0];
                String role = authResults[1];
                int userId = Integer.parseInt(userIdStr);
                
                String userName = dao.fetchNameByRole(userId, role);
                if (userName == null || userName.trim().isEmpty()) {
                    userName = "admin".equalsIgnoreCase(role) ? "Admin User" : email;
                }
                
                HttpSession session = request.getSession(true);
                session.setAttribute("userId", userId);
                session.setAttribute("userEmail", email);
                session.setAttribute("userRole", role);
                session.setAttribute("userName", userName);
                
                // Store first name separately for display
                String firstName = userName;
                if (userName != null && userName.contains(" ")) {
                    firstName = userName.substring(0, userName.indexOf(" "));
                }
                session.setAttribute("firstName", firstName);
                
                System.out.println("=== LOGIN SUCCESSFUL ===");
                System.out.println("User ID: " + userId);
                System.out.println("Email: " + email);
                System.out.println("Role: " + role);
                System.out.println("Name: " + userName);
                
                if (role.equalsIgnoreCase("household_user")) {
                    url = "household_user_dashboard.jsp";
                } else if (role.equalsIgnoreCase("recycle_center") || role.equalsIgnoreCase("recycle_center")) {
                    url = "recycle_center_dashboard.jsp";
                } else if (role.equalsIgnoreCase("admin")) {
                    url = "admin_dashboard.jsp";
                } else {
                    session.setAttribute("errorMessage", "Unknown role: " + role);
                    url = "login.html";
                }
            } else {
                HttpSession session = request.getSession(true);
                session.setAttribute("errorMessage", "Invalid email or password. Please try again.");
                url = "login.html";
                System.out.println("Login failed for email: " + email);
            }
        } catch (Exception e) {
            System.err.println("Login error: " + e.getMessage());
            e.printStackTrace();
            HttpSession session = request.getSession(true);
            session.setAttribute("errorMessage", "An error occurred during login. Please try again.");
            url = "login.html";
        }
        
        RequestDispatcher rd = request.getRequestDispatcher(url);
        rd.forward(request, response);
    }
}
