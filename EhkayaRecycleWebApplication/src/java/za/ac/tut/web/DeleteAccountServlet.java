package za.ac.tut.web;

import java.io.IOException;
import java.net.URLEncoder;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

public class DeleteAccountServlet extends HttpServlet {

    private static final long CODE_EXPIRY_MILLIS = 10 * 60 * 1000;
    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.html");
            return;
        }

        String action = trim(request.getParameter("action"));
        if ("sendCode".equals(action)) {
            sendDeletionCode(request, response, session);
            return;
        }
        if ("verifyCode".equals(action)) {
            verifyAndDeleteAccount(request, response, session);
            return;
        }

        redirectWithDeleteError(response, "Invalid account deletion request.");
    }

    private void sendDeletionCode(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws IOException {

        Integer userId = (Integer) session.getAttribute("userId");
        String userRole = trim((String) session.getAttribute("userRole"));

        if (!"household_user".equalsIgnoreCase(userRole)) {
            redirectWithDeleteError(response, "Only household users can delete their own account from this page.");
            return;
        }

        try (Connection conn = DBManager.getConnection()) {
            String currentEmail = findHouseholdEmail(conn, userId);
            if (currentEmail == null) {
                redirectWithDeleteError(response, "Your household account could not be found.");
                return;
            }

            String email = currentEmail;
            String code = generateVerificationCode();
            session.setAttribute("deleteAccountUserId", userId);
            session.setAttribute("deleteAccountEmail", email);
            session.setAttribute("deleteAccountCode", code);
            session.setAttribute("deleteAccountCodeExpiresAt", System.currentTimeMillis() + CODE_EXPIRY_MILLIS);
            session.setAttribute("deleteAccountAttempts", 0);

            EmailService.sendAccountDeletionCode(email, code);
            response.sendRedirect("profile.jsp?deleteSent=true");
        } catch (Exception e) {
            e.printStackTrace();
            redirectWithDeleteError(response, "Could not send the OTP. Please try again.");
        }
    }

    private void verifyAndDeleteAccount(HttpServletRequest request, HttpServletResponse response, HttpSession session)
            throws IOException {

        Integer signedInUserId = (Integer) session.getAttribute("userId");
        String userRole = trim((String) session.getAttribute("userRole"));
        Integer deleteUserId = (Integer) session.getAttribute("deleteAccountUserId");
        String expectedCode = trim((String) session.getAttribute("deleteAccountCode"));
        Long expiresAt = (Long) session.getAttribute("deleteAccountCodeExpiresAt");
        Integer attempts = (Integer) session.getAttribute("deleteAccountAttempts");
        attempts = attempts == null ? 0 : attempts;

        if (!"household_user".equalsIgnoreCase(userRole)) {
            redirectWithDeleteError(response, "Only household users can delete their own account from this page.");
            return;
        }
        if (deleteUserId == null || !deleteUserId.equals(signedInUserId) || expectedCode.isEmpty()) {
            redirectWithDeleteError(response, "Please request a deletion OTP first.");
            return;
        }
        if (expiresAt == null || System.currentTimeMillis() > expiresAt) {
            clearDeleteSession(session);
            redirectWithDeleteError(response, "Your deletion OTP expired. Please request a new one.");
            return;
        }
        if (attempts >= 5) {
            clearDeleteSession(session);
            redirectWithDeleteError(response, "Too many incorrect OTP attempts. Please request a new one.");
            return;
        }

        String otp = trim(request.getParameter("otp"));
        if (!otp.equals(expectedCode)) {
            session.setAttribute("deleteAccountAttempts", attempts + 1);
            redirectWithDeleteError(response, "Invalid OTP.");
            return;
        }

        try (Connection conn = DBManager.getConnection()) {
            conn.setAutoCommit(false);
            try {
                deleteHouseholdAccount(conn, signedInUserId);
                conn.commit();
                session.invalidate();
                response.sendRedirect("login.html?accountDeleted=true");
            } catch (Exception e) {
                conn.rollback();
                throw e;
            } finally {
                conn.setAutoCommit(true);
            }
        } catch (Exception e) {
            e.printStackTrace();
            redirectWithDeleteError(response, "Could not delete your account right now. Please try again later.");
        }
    }

    private String findHouseholdEmail(Connection conn, int userId) throws Exception {
        String sql = "SELECT email_address FROM USERS WHERE user_id = ? AND role = 'household_user'";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getString("email_address");
                }
            }
        }
        return null;
    }

    private void deleteHouseholdAccount(Connection conn, int userId) throws Exception {
        deleteWithUserId(conn, "DELETE wt FROM WALLET_TRANSACTION wt JOIN WALLET w ON wt.wallet_id = w.wallet_id WHERE w.household_user_id = ?", userId);
        deleteWithUserId(conn, "DELETE FROM WALLET WHERE household_user_id = ?", userId);
        deleteWithUserId(conn, "DELETE cr FROM COLLECTION_RECORD cr JOIN PICKUP_REQUEST pr ON cr.request_id = pr.request_id WHERE pr.household_user_id = ?", userId);
        deleteWithUserId(conn, "DELETE pi FROM PICKUP_ITEM pi JOIN PICKUP_REQUEST pr ON pi.request_id = pr.request_id WHERE pr.household_user_id = ?", userId);
        deleteWithUserId(conn, "DELETE FROM PICKUP_REQUEST WHERE household_user_id = ?", userId);
        deleteWithUserId(conn, "DELETE FROM HOUSEHOLD_USER WHERE user_id = ?", userId);
        deleteWithUserId(conn, "DELETE FROM USERS WHERE user_id = ?", userId);
    }

    private void deleteWithUserId(Connection conn, String sql, int userId) throws Exception {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.executeUpdate();
        }
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private String generateVerificationCode() {
        return String.format("%06d", RANDOM.nextInt(1000000));
    }

    private void clearDeleteSession(HttpSession session) {
        session.removeAttribute("deleteAccountUserId");
        session.removeAttribute("deleteAccountEmail");
        session.removeAttribute("deleteAccountCode");
        session.removeAttribute("deleteAccountCodeExpiresAt");
        session.removeAttribute("deleteAccountAttempts");
    }

    private void writeJson(HttpServletResponse response, boolean success, String message) throws IOException {
        response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + escapeJson(message) + "\"}");
    }

    private void redirectWithDeleteError(HttpServletResponse response, String message) throws IOException {
        response.sendRedirect("profile.jsp?deleteError=" + URLEncoder.encode(message, "UTF-8"));
    }

    private String escapeJson(String value) {
        return value == null ? "" : value.replace("\\", "\\\\").replace("\"", "\\\"");
    }
}
