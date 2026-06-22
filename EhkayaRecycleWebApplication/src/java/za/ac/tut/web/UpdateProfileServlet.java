package za.ac.tut.web;

import java.io.IOException;
import java.sql.*;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

public class UpdateProfileServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        HttpSession session = request.getSession(false);
        Integer userId = (Integer) session.getAttribute("userId");
        String userRole = (String) session.getAttribute("userRole");
        
        if (userId == null) {
            response.sendRedirect("login.html");
            return;
        }
        
        // Get form parameters
        String firstName = request.getParameter("firstName");
        String lastName = request.getParameter("lastName");
        String phone = request.getParameter("phone");
        String street = request.getParameter("street");
        String city = request.getParameter("city");
        String province = request.getParameter("province");
        String postal = request.getParameter("postal");
        
        Connection conn = null;
        PreparedStatement ps = null;
        
        try {
            conn = DBManager.getConnection();
            
            if ("household_user".equalsIgnoreCase(userRole)) {
                // Update household user
                String sql = "UPDATE HOUSEHOLD_USER SET first_name = ?, last_name = ?, phone_number = ?, "
                           + "street_address = ?, city = ?, province = ?, postal_code = ? "
                           + "WHERE user_id = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, firstName);
                ps.setString(2, lastName);
                ps.setString(3, phone);
                ps.setString(4, street);
                ps.setString(5, city);
                ps.setString(6, province);
                ps.setString(7, postal);
                ps.setInt(8, userId);
                ps.executeUpdate();
                
            } else if ("recycle_center".equalsIgnoreCase(userRole) || "recycle_centre".equalsIgnoreCase(userRole)) {
                // Update recycle centre
                String sql = "UPDATE RECYCLE_CENTRE SET centre_name = ?, phone_number = ?, "
                           + "street_address = ?, city = ?, province = ?, postal_code = ? "
                           + "WHERE user_id = ?";
                ps = conn.prepareStatement(sql);
                ps.setString(1, firstName);
                ps.setString(2, phone);
                ps.setString(3, street);
                ps.setString(4, city);
                ps.setString(5, province);
                ps.setString(6, postal);
                ps.setInt(7, userId);
                ps.executeUpdate();
            }
            
            // Update session name
            session.setAttribute("userName", firstName);
            
            response.sendRedirect("profile.jsp?success=true");
            
        } catch (Exception e) {
            e.printStackTrace();
            response.sendRedirect("profile.jsp?error=" + e.getMessage());
        } finally {
            try { if (ps != null) ps.close(); } catch (SQLException e) {}
            try { if (conn != null) conn.close(); } catch (SQLException e) {}
        }
    }
}
