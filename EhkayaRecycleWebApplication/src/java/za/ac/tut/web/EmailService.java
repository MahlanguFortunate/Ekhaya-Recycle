package za.ac.tut.web;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import javax.mail.Authenticator;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import javax.servlet.ServletContext;

public class EmailService {

    private static final String APP_NAME = "Recycle Ekhaya";

    public static void notifyCentreOfNewPickup(Connection conn, int requestId) throws Exception {
        PickupEmailData data = loadPickupEmailData(conn, requestId);
        if (data == null) {
            System.err.println("Email skipped: pickup request not found: " + requestId);
            return;
        }

        String subject = "New pickup request #" + data.requestId + " assigned to " + data.centreName;
        String body = buildCentreNotificationBody(data);
        sendEmail(data.centreEmail, subject, body);
    }

    public static void notifyHouseholdPickupAccepted(Connection conn, int requestId) throws Exception {
        PickupEmailData data = loadPickupEmailData(conn, requestId);
        if (data == null) {
            System.err.println("Email skipped: pickup request not found: " + requestId);
            return;
        }

        String subject = "Your pickup request #" + data.requestId + " has been accepted";
        String body = buildHouseholdAcceptedBody(data);
        sendEmail(data.householdEmail, subject, body);
    }

    public static void notifyHouseholdPickupDeclined(Connection conn, int requestId, String preferredPickupDate) throws Exception {
        PickupEmailData data = loadPickupEmailData(conn, requestId);
        if (data == null) {
            System.err.println("Email skipped: pickup request not found: " + requestId);
            return;
        }

        String subject = "Please reschedule pickup request #" + data.requestId;
        String body = buildHouseholdDeclinedBody(data, preferredPickupDate);
        sendEmail(data.householdEmail, subject, body);
    }

    public static void sendPasswordResetCode(String to, String code) throws MessagingException {
        sendPasswordResetCode(to, code, null);
    }

    public static void sendPasswordResetCode(String to, String code, ServletContext servletContext) throws MessagingException {
        String subject = "Recycle Ekhaya password reset verification code";
        String body = "Hello,\n\n"
                + "Use this verification code to reset your Recycle Ekhaya password:\n\n"
                + code + "\n\n"
                + "This code expires in 10 minutes. If you did not request a password reset, please ignore this email.\n\n"
                + APP_NAME;

        if (!sendEmail(to, subject, body, servletContext)) {
            throw new MessagingException("SMTP settings are missing or the recipient email address is invalid.");
        }
    }

    public static void sendAccountDeletionCode(String to, String code) throws MessagingException {
        sendAccountDeletionCode(to, code, null);
    }

    public static void sendAccountDeletionCode(String to, String code, ServletContext servletContext) throws MessagingException {
        String subject = "Recycle Ekhaya account deletion verification code";
        String body = "Hello,\n\n"
                + "Use this verification code to confirm deletion of your Recycle Ekhaya account:\n\n"
                + code + "\n\n"
                + "This code expires in 10 minutes. If you did not request account deletion, please ignore this email and keep your account signed in.\n\n"
                + APP_NAME;

        if (!sendEmail(to, subject, body, servletContext)) {
            throw new MessagingException("SMTP settings are missing or the recipient email address is invalid.");
        }
    }

    private static PickupEmailData loadPickupEmailData(Connection conn, int requestId) throws SQLException {
        String sql = "SELECT pr.request_id, pr.scheduled_date, pr.request_status, "
                + "pr.pickup_street_address, pr.pickup_city, pr.pickup_province, pr.pickup_postal_code, "
                + "hu.first_name, hu.last_name, hu.phone_number AS household_phone, "
                + "hu.street_address AS household_street, hu.city AS household_city, "
                + "hu.province AS household_province, hu.postal_code AS household_postal_code, "
                + "household_user.email_address AS household_email, "
                + "rc.centre_name, rc.phone_number AS centre_phone, "
                + "rc.street_address AS centre_street, rc.city AS centre_city, "
                + "rc.province AS centre_province, rc.postal_code AS centre_postal_code, "
                + "centre_user.email_address AS centre_email "
                + "FROM PICKUP_REQUEST pr "
                + "JOIN HOUSEHOLD_USER hu ON pr.household_user_id = hu.user_id "
                + "JOIN USERS household_user ON hu.user_id = household_user.user_id "
                + "JOIN RECYCLE_CENTRE rc ON pr.centre_id = rc.user_id "
                + "JOIN USERS centre_user ON rc.user_id = centre_user.user_id "
                + "WHERE pr.request_id = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return null;
                }

                PickupEmailData data = new PickupEmailData();
                data.requestId = rs.getInt("request_id");
                data.scheduledDate = rs.getString("scheduled_date");
                data.status = rs.getString("request_status");
                data.pickupAddress = joinAddress(
                        rs.getString("pickup_street_address"),
                        rs.getString("pickup_city"),
                        rs.getString("pickup_province"),
                        rs.getString("pickup_postal_code"));
                data.householdName = joinName(rs.getString("first_name"), rs.getString("last_name"));
                data.householdPhone = rs.getString("household_phone");
                data.householdEmail = rs.getString("household_email");
                data.householdAddress = joinAddress(
                        rs.getString("household_street"),
                        rs.getString("household_city"),
                        rs.getString("household_province"),
                        rs.getString("household_postal_code"));
                data.centreName = rs.getString("centre_name");
                data.centrePhone = rs.getString("centre_phone");
                data.centreEmail = rs.getString("centre_email");
                data.centreAddress = joinAddress(
                        rs.getString("centre_street"),
                        rs.getString("centre_city"),
                        rs.getString("centre_province"),
                        rs.getString("centre_postal_code"));
                data.materials = loadMaterials(conn, requestId);
                return data;
            }
        }
    }

    private static List<PickupMaterial> loadMaterials(Connection conn, int requestId) throws SQLException {
        String sql = "SELECT rm.material_name, pi.estimated_weight "
                + "FROM PICKUP_ITEM pi "
                + "JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id "
                + "WHERE pi.request_id = ?";
        List<PickupMaterial> materials = new ArrayList<>();

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, requestId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    PickupMaterial material = new PickupMaterial();
                    material.name = rs.getString("material_name");
                    material.estimatedWeight = rs.getDouble("estimated_weight");
                    materials.add(material);
                }
            }
        }

        return materials;
    }

    private static String buildCentreNotificationBody(PickupEmailData data) {
        StringBuilder body = new StringBuilder();
        body.append("Hello ").append(nullToText(data.centreName)).append(",\n\n");
        body.append("A new household pickup request has been assigned to your recycle centre.\n\n");
        appendRequestDetails(body, data);
        body.append("\nHousehold details\n");
        body.append("Name: ").append(nullToText(data.householdName)).append("\n");
        body.append("Email: ").append(nullToText(data.householdEmail)).append("\n");
        body.append("Phone: ").append(nullToText(data.householdPhone)).append("\n");
        body.append("Registered address: ").append(nullToText(data.householdAddress)).append("\n\n");
        body.append("Please log in to Recycle Ekhaya to accept or manage this pickup request.\n\n");
        body.append(APP_NAME);
        return body.toString();
    }

    private static String buildHouseholdAcceptedBody(PickupEmailData data) {
        StringBuilder body = new StringBuilder();
        body.append("Hello ").append(nullToText(data.householdName)).append(",\n\n");
        body.append("Your pickup request has been accepted by the assigned recycle centre.\n\n");
        appendRequestDetails(body, data);
        body.append("\nRecycle centre details\n");
        body.append("Centre: ").append(nullToText(data.centreName)).append("\n");
        body.append("Email: ").append(nullToText(data.centreEmail)).append("\n");
        body.append("Phone: ").append(nullToText(data.centrePhone)).append("\n");
        body.append("Address: ").append(nullToText(data.centreAddress)).append("\n\n");
        body.append("Please keep your recyclable materials ready for the scheduled pickup date.\n\n");
        body.append(APP_NAME);
        return body.toString();
    }

    private static String buildHouseholdDeclinedBody(PickupEmailData data, String preferredPickupDate) {
        StringBuilder body = new StringBuilder();
        body.append("Hello ").append(nullToText(data.householdName)).append(",\n\n");
        body.append("The recycle centre was unable to collect your pickup request on your selected date: ")
                .append(nullToText(data.scheduledDate)).append(".\n\n");
        body.append("They suggested this preferred pickup date for your rescheduled request: ")
                .append(nullToText(preferredPickupDate)).append(".\n\n");
        body.append("Please log in to Recycle Ekhaya and schedule the pickup again using that date if it works for you.\n\n");
        appendRequestDetails(body, data);
        body.append("\nRecycle centre details\n");
        body.append("Centre: ").append(nullToText(data.centreName)).append("\n");
        body.append("Email: ").append(nullToText(data.centreEmail)).append("\n");
        body.append("Phone: ").append(nullToText(data.centrePhone)).append("\n\n");
        body.append(APP_NAME);
        return body.toString();
    }

    private static void appendRequestDetails(StringBuilder body, PickupEmailData data) {
        body.append("Pickup request details\n");
        body.append("Request ID: #").append(data.requestId).append("\n");
        body.append("Scheduled date: ").append(nullToText(data.scheduledDate)).append("\n");
        body.append("Status: ").append(nullToText(data.status)).append("\n");
        body.append("Pickup address: ").append(nullToText(data.pickupAddress)).append("\n");
        body.append("Materials: ").append(formatMaterials(data.materials)).append("\n");
        double totalWeight = totalWeight(data.materials);
        if (totalWeight > 0) {
            body.append("Estimated total weight: ").append(String.format("%.1f kg", totalWeight)).append("\n");
        }
    }

    private static boolean sendEmail(String to, String subject, String body) throws MessagingException {
        return sendEmail(to, subject, body, null);
    }

    private static boolean sendEmail(String to, String subject, String body, ServletContext servletContext) throws MessagingException {
        EmailConfig config = EmailConfig.fromSettings(servletContext);
        if (!config.isConfigured() || isBlank(to)) {
            System.err.println("Email skipped: SMTP settings or recipient address are missing. Recipient: " + to);
            return false;
        }

        Properties props = new Properties();
        props.put("mail.smtp.host", config.host);
        props.put("mail.smtp.port", config.port);
        props.put("mail.smtp.auth", String.valueOf(config.authEnabled));
        props.put("mail.smtp.starttls.enable", String.valueOf(config.startTlsEnabled));
        props.put("mail.smtp.starttls.required", String.valueOf(config.startTlsEnabled));

        Session session = config.authEnabled
                ? Session.getInstance(props, new Authenticator() {
                    @Override
                    protected PasswordAuthentication getPasswordAuthentication() {
                        return new PasswordAuthentication(config.username, config.password);
                    }
                })
                : Session.getInstance(props);

        Message message = new MimeMessage(session);
        message.setFrom(new InternetAddress(config.fromAddress));
        message.setRecipients(Message.RecipientType.TO, InternetAddress.parse(to, false));
        message.setSubject(subject);
        message.setText(body);
        Transport.send(message);
        System.out.println("Email sent to " + to + ": " + subject);
        return true;
    }

    private static String formatMaterials(List<PickupMaterial> materials) {
        if (materials == null || materials.isEmpty()) {
            return "Not specified";
        }

        StringBuilder result = new StringBuilder();
        for (PickupMaterial material : materials) {
            if (result.length() > 0) {
                result.append(", ");
            }
            result.append(nullToText(material.name))
                    .append(formatMaterialWeight(material.estimatedWeight));
        }
        return result.toString();
    }

    private static String formatMaterialWeight(double estimatedWeight) {
        if (estimatedWeight <= 0) {
            return "";
        }
        return " (" + String.format("%.1f kg", estimatedWeight) + ")";
    }

    private static double totalWeight(List<PickupMaterial> materials) {
        double total = 0.0;
        if (materials != null) {
            for (PickupMaterial material : materials) {
                total += material.estimatedWeight;
            }
        }
        return total;
    }

    private static String joinName(String firstName, String lastName) {
        StringBuilder result = new StringBuilder();
        appendPart(result, firstName, " ");
        appendPart(result, lastName, " ");
        return result.toString();
    }

    private static String joinAddress(String street, String city, String province, String postalCode) {
        StringBuilder result = new StringBuilder();
        appendPart(result, street, ", ");
        appendPart(result, city, ", ");
        appendPart(result, province, ", ");
        appendPart(result, postalCode, ", ");
        return result.toString();
    }

    private static void appendPart(StringBuilder result, String value, String separator) {
        if (isBlank(value)) {
            return;
        }
        if (result.length() > 0) {
            result.append(separator);
        }
        result.append(value.trim());
    }

    private static String nullToText(String value) {
        return isBlank(value) ? "Not specified" : value.trim();
    }

    private static String getSetting(String systemProperty, String environmentVariable) {
        String value = System.getProperty(systemProperty);
        if (!isBlank(value)) {
            return value;
        }
        return System.getenv(environmentVariable);
    }

    private static String getSetting(ServletContext servletContext, String contextParam, String systemProperty, String environmentVariable) {
        if (servletContext != null) {
            String contextValue = servletContext.getInitParameter(contextParam);
            if (!isBlank(contextValue)) {
                return contextValue;
            }
        }
        return getSetting(systemProperty, environmentVariable);
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }

    private static class PickupEmailData {
        private int requestId;
        private String scheduledDate;
        private String status;
        private String pickupAddress;
        private String householdName;
        private String householdPhone;
        private String householdEmail;
        private String householdAddress;
        private String centreName;
        private String centrePhone;
        private String centreEmail;
        private String centreAddress;
        private List<PickupMaterial> materials;
    }

    private static class PickupMaterial {
        private String name;
        private double estimatedWeight;
    }

    private static class EmailConfig {
        private String host;
        private String port;
        private String username;
        private String password;
        private String fromAddress;
        private boolean authEnabled;
        private boolean startTlsEnabled;

        private static EmailConfig fromSettings(ServletContext servletContext) {
            EmailConfig config = new EmailConfig();
            config.host = firstNonBlank(
                    getSetting(servletContext, "ekhaya.smtp.host", "ekhaya.smtp.host", "EKHAYA_SMTP_HOST"),
                    getSetting(servletContext, "mail.smtp.host", "mail.smtp.host", "SMTP_HOST"));
            config.port = firstNonBlank(
                    getSetting(servletContext, "ekhaya.smtp.port", "ekhaya.smtp.port", "EKHAYA_SMTP_PORT"),
                    getSetting(servletContext, "mail.smtp.port", "mail.smtp.port", "SMTP_PORT"),
                    "587");
            config.username = firstNonBlank(
                    getSetting(servletContext, "ekhaya.smtp.username", "ekhaya.smtp.username", "EKHAYA_SMTP_USERNAME"),
                    getSetting(servletContext, "mail.smtp.user", "mail.smtp.user", "SMTP_USERNAME"));
            config.password = firstNonBlank(
                    getSetting(servletContext, "ekhaya.smtp.password", "ekhaya.smtp.password", "EKHAYA_SMTP_PASSWORD"),
                    getSetting(servletContext, "mail.smtp.password", "mail.smtp.password", "SMTP_PASSWORD"));
            config.fromAddress = firstNonBlank(
                    getSetting(servletContext, "ekhaya.smtp.from", "ekhaya.smtp.from", "EKHAYA_SMTP_FROM"),
                    getSetting(servletContext, "mail.from", "mail.from", "SMTP_FROM"),
                    config.username);
            String startTls = firstNonBlank(
                    getSetting(servletContext, "ekhaya.smtp.starttls", "ekhaya.smtp.starttls", "EKHAYA_SMTP_STARTTLS"),
                    getSetting(servletContext, "mail.smtp.starttls.enable", "mail.smtp.starttls.enable", "SMTP_STARTTLS"),
                    "true");
            config.startTlsEnabled = Boolean.parseBoolean(startTls);
            config.authEnabled = !isBlank(config.username) && !isBlank(config.password);
            return config;
        }

        private boolean isConfigured() {
            return !isBlank(host) && !isBlank(fromAddress);
        }

        private static String firstNonBlank(String... values) {
            if (values == null) {
                return null;
            }
            for (String value : values) {
                if (!isBlank(value)) {
                    return value;
                }
            }
            return null;
        }
    }
}
