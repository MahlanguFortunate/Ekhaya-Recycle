package za.ac.tut.web;

import java.io.IOException;
import java.security.SecureRandom;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import org.mindrot.jbcrypt.BCrypt;
import za.ac.tut.db.DBManager;

public class ResetPasswordServlet extends HttpServlet {

    private static final long CODE_EXPIRY_MILLIS = 10 * 60 * 1000;
    private static final SecureRandom RANDOM = new SecureRandom();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String action = trim(request.getParameter("action"));
        if ("sendCode".equals(action)) {
            sendVerificationCode(request, response);
            return;
        }
        if ("resetPassword".equals(action)) {
            resetPassword(request, response);
            return;
        }

        forwardWithError(request, response, "Invalid password reset request.");
    }

    private void sendVerificationCode(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String email = trim(request.getParameter("email"));

        if (email.isEmpty()) {
            forwardWithError(request, response, "Email address is required.");
            return;
        }

        try (Connection conn = DBManager.getConnection()) {
            Integer userId = findUserIdByEmail(conn, email);
            if (userId == null) {
                forwardWithError(request, response, "No account found with that email address.");
                return;
            }

            String code = generateVerificationCode();
            HttpSession session = request.getSession(true);
            session.setAttribute("resetEmail", email);
            session.setAttribute("resetUserId", userId);
            session.setAttribute("resetCode", code);
            session.setAttribute("resetCodeExpiresAt", System.currentTimeMillis() + CODE_EXPIRY_MILLIS);
            session.setAttribute("resetAttempts", 0);

            EmailService.sendPasswordResetCode(email, code);

            request.setAttribute("verificationSent", true);
            request.setAttribute("resetEmail", email);
            request.setAttribute("success", "A verification code has been sent to your email address.");
            request.getRequestDispatcher("forgot_password.jsp").forward(request, response);
        } catch (Exception e) {
            e.printStackTrace();
            forwardWithError(request, response, "Could not send the verification email. Please check SMTP settings and try again.");
        }
    }

    private void resetPassword(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        String email = trim(request.getParameter("email"));
        String verificationCode = trim(request.getParameter("verificationCode"));
        String newPassword = request.getParameter("newPassword");
        String confirmPassword = request.getParameter("confirmPassword");

        if (session == null || session.getAttribute("resetCode") == null) {
            forwardWithError(request, response, "Please request a verification code first.");
            return;
        }

        String sessionEmail = trim((String) session.getAttribute("resetEmail"));
        Integer userId = (Integer) session.getAttribute("resetUserId");
        String expectedCode = trim((String) session.getAttribute("resetCode"));
        Long expiresAt = (Long) session.getAttribute("resetCodeExpiresAt");
        Integer attempts = (Integer) session.getAttribute("resetAttempts");
        attempts = attempts == null ? 0 : attempts;

        if (email.isEmpty() || !email.equalsIgnoreCase(sessionEmail) || userId == null) {
            forwardForVerification(request, response, sessionEmail, "This reset session does not match the email address. Please request a new code.");
            return;
        }
        if (expiresAt == null || System.currentTimeMillis() > expiresAt) {
            clearResetSession(session);
            forwardWithError(request, response, "Your verification code expired. Please request a new one.");
            return;
        }
        if (attempts >= 5) {
            clearResetSession(session);
            forwardWithError(request, response, "Too many incorrect verification attempts. Please request a new code.");
            return;
        }
        if (verificationCode.isEmpty()) {
            forwardForVerification(request, response, sessionEmail, "Verification code is required.");
            return;
        }
        if (!verificationCode.equals(expectedCode)) {
            session.setAttribute("resetAttempts", attempts + 1);
            forwardForVerification(request, response, sessionEmail, "Invalid verification code.");
            return;
        }
        if (newPassword == null || newPassword.trim().isEmpty()) {
            forwardForVerification(request, response, sessionEmail, "New password is required.");
            return;
        }
        if (newPassword.length() < 6) {
            forwardForVerification(request, response, sessionEmail, "Password must be at least 6 characters.");
            return;
        }
        if (!newPassword.equals(confirmPassword)) {
            forwardForVerification(request, response, sessionEmail, "Passwords do not match.");
            return;
        }

        try (Connection conn = DBManager.getConnection()) {
            String hashedPassword = BCrypt.hashpw(newPassword, BCrypt.gensalt(12));
            String updateSql = "UPDATE USERS SET user_password = ? WHERE user_id = ?";

            try (PreparedStatement ps = conn.prepareStatement(updateSql)) {
                ps.setString(1, hashedPassword);
                ps.setInt(2, userId);

                int rows = ps.executeUpdate();
                if (rows > 0) {
                    clearResetSession(session);
                    request.setAttribute("success", "Password updated successfully. You can now log in with your new password.");
                    request.getRequestDispatcher("forgot_password.jsp").forward(request, response);
                } else {
                    forwardForVerification(request, response, sessionEmail, "Failed to update password. Please try again.");
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
            forwardForVerification(request, response, sessionEmail, "Could not reset password right now. Please try again later.");
        }
    }

    private Integer findUserIdByEmail(Connection conn, String email) throws Exception {
        String checkSql = "SELECT user_id FROM USERS WHERE LOWER(email_address) = LOWER(?)";
        try (PreparedStatement ps = conn.prepareStatement(checkSql)) {
            ps.setString(1, email);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt("user_id");
                }
            }
        }
        return null;
    }

    private String trim(String value) {
        return value == null ? "" : value.trim();
    }

    private String generateVerificationCode() {
        return String.format("%06d", RANDOM.nextInt(1000000));
    }

    private void clearResetSession(HttpSession session) {
        session.removeAttribute("resetEmail");
        session.removeAttribute("resetUserId");
        session.removeAttribute("resetCode");
        session.removeAttribute("resetCodeExpiresAt");
        session.removeAttribute("resetAttempts");
    }

    private void forwardWithError(HttpServletRequest request, HttpServletResponse response, String error)
            throws ServletException, IOException {
        request.setAttribute("error", error);
        request.getRequestDispatcher("forgot_password.jsp").forward(request, response);
    }

    private void forwardForVerification(HttpServletRequest request, HttpServletResponse response, String email, String error)
            throws ServletException, IOException {
        request.setAttribute("verificationSent", true);
        request.setAttribute("resetEmail", email);
        request.setAttribute("error", error);
        request.getRequestDispatcher("forgot_password.jsp").forward(request, response);
    }
}
