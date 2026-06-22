package za.ac.tut.web;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.DBManager;

public class UserReportPdfServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Integer userId = session == null ? null : (Integer) session.getAttribute("userId");
        String role = session == null ? null : (String) session.getAttribute("userRole");

        if (userId == null || role == null) {
            response.sendRedirect("login.html");
            return;
        }

        try (Connection conn = DBManager.getConnection()) {
            ReportData report = buildReport(conn, userId, role);
            report.name = valueOrDefault((String) session.getAttribute("userName"), report.name);
            report.email = valueOrDefault((String) session.getAttribute("userEmail"), report.email);
            byte[] pdf = new PdfBuilder().build(report);

            String safeName = report.name.replaceAll("[^A-Za-z0-9_-]+", "_");
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"Recycle_Ekhaya_Report_" + safeName + "_" + userId + ".pdf\"");
            response.setContentLength(pdf.length);
            response.getOutputStream().write(pdf);
        } catch (Exception e) {
            throw new ServletException("Could not generate user report PDF", e);
        }
    }

    private ReportData buildReport(Connection conn, int userId, String role) throws SQLException {
        ReportData report = new ReportData();
        report.userId = userId;
        report.role = role;
        report.generatedDate = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);

        loadUserInfo(conn, report);
        loadActivitySummary(conn, report);
        loadStatusCounts(conn, report);
        loadMaterialTotals(conn, report);

        return report;
    }

    private void loadUserInfo(Connection conn, ReportData report) throws SQLException {
        String sql;
        if ("household_user".equalsIgnoreCase(report.role)) {
            sql = "SELECT u.email_address, u.date_created, "
                    + "CONCAT(hu.first_name, ' ', hu.last_name) AS display_name "
                    + "FROM USERS u JOIN HOUSEHOLD_USER hu ON u.user_id = hu.user_id "
                    + "WHERE u.user_id = ?";
        } else if ("recycle_center".equalsIgnoreCase(report.role) || "recycle_centre".equalsIgnoreCase(report.role)) {
            sql = "SELECT u.email_address, u.date_created, rc.centre_name AS display_name "
                    + "FROM USERS u JOIN RECYCLE_CENTRE rc ON u.user_id = rc.user_id "
                    + "WHERE u.user_id = ?";
        } else {
            sql = "SELECT email_address, date_created, 'User' AS display_name FROM USERS WHERE user_id = ?";
        }

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, report.userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    report.email = valueOrEmpty(rs.getString("email_address"));
                    report.name = valueOrDefault(rs.getString("display_name"), "User");
                    report.dateCreated = valueOrEmpty(rs.getString("date_created"));
                }
            }
        }

        String activeSql = "SELECT DATEDIFF(CURDATE(), date_created) AS active_days FROM USERS WHERE user_id = ?";
        try (PreparedStatement ps = conn.prepareStatement(activeSql)) {
            ps.setInt(1, report.userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    report.activeDays = Math.max(0, rs.getInt("active_days"));
                }
            }
        }
    }

    private void loadActivitySummary(Connection conn, ReportData report) throws SQLException {
        String userColumn = isHousehold(report) ? "household_user_id" : "centre_id";
        String sql = "SELECT COUNT(*) AS total_activities, "
                + "MIN(COALESCE(cr.collection_date, pr.created_date, pr.scheduled_date)) AS period_start, "
                + "MAX(COALESCE(cr.collection_date, pr.created_date, pr.scheduled_date)) AS period_end "
                + "FROM PICKUP_REQUEST pr "
                + "LEFT JOIN COLLECTION_RECORD cr ON pr.request_id = cr.request_id "
                + "WHERE pr." + userColumn + " = ?";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, report.userId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    report.totalActivities = rs.getInt("total_activities");
                    report.periodStart = valueOrDefault(rs.getString("period_start"), "No activity yet");
                    report.periodEnd = valueOrDefault(rs.getString("period_end"), "No activity yet");
                }
            }
        }
    }

    private void loadStatusCounts(Connection conn, ReportData report) throws SQLException {
        String userColumn = isHousehold(report) ? "household_user_id" : "centre_id";
        String sql = "SELECT request_status, COUNT(*) AS status_count "
                + "FROM PICKUP_REQUEST WHERE " + userColumn + " = ? GROUP BY request_status";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, report.userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String status = valueOrEmpty(rs.getString("request_status")).toLowerCase();
                    int count = rs.getInt("status_count");
                    if ("completed".equals(status)) {
                        report.completedRequests = count;
                    } else if ("pending".equals(status)) {
                        report.pendingRequests = count;
                    } else if ("cancelled".equals(status)) {
                        report.cancelledRequests = count;
                    } else if ("scheduled".equals(status)) {
                        report.scheduledRequests = count;
                    }
                }
            }
        }
    }

    private void loadMaterialTotals(Connection conn, ReportData report) throws SQLException {
        String userColumn = isHousehold(report) ? "household_user_id" : "centre_id";
        String sql = "SELECT rm.material_name, COALESCE(SUM(pi.estimated_weight), 0) AS total_weight "
                + "FROM PICKUP_REQUEST pr "
                + "JOIN PICKUP_ITEM pi ON pr.request_id = pi.request_id "
                + "JOIN RECYCLE_MATERIAL rm ON pi.material_id = rm.material_id "
                + "WHERE pr." + userColumn + " = ? "
                + "GROUP BY rm.material_name ORDER BY rm.material_name";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, report.userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    report.materialTotals.add(new MaterialTotal(
                            valueOrDefault(rs.getString("material_name"), "Unknown"),
                            rs.getDouble("total_weight")));
                }
            }
        }
    }

    private boolean isHousehold(ReportData report) {
        return "household_user".equalsIgnoreCase(report.role);
    }

    private String valueOrEmpty(String value) {
        return value == null ? "" : value;
    }

    private String valueOrDefault(String value, String defaultValue) {
        return value == null || value.trim().isEmpty() ? defaultValue : value;
    }

    private static class ReportData {
        int userId;
        String role = "";
        String name = "User";
        String email = "";
        String dateCreated = "";
        String generatedDate = "";
        int activeDays;
        int totalActivities;
        String periodStart = "No activity yet";
        String periodEnd = "No activity yet";
        int completedRequests;
        int pendingRequests;
        int cancelledRequests;
        int scheduledRequests;
        List<MaterialTotal> materialTotals = new ArrayList<>();
    }

    private static class MaterialTotal {
        final String material;
        final double weight;

        MaterialTotal(String material, double weight) {
            this.material = material;
            this.weight = weight;
        }
    }

    private static class PdfBuilder {
        private static final int PAGE_WIDTH = 595;
        private static final int PAGE_HEIGHT = 842;
        private static final int MARGIN = 42;
        private static final int BOTTOM_MARGIN = 56;
        private static final int CONTENT_WIDTH = PAGE_WIDTH - (MARGIN * 2);
        private static final int GREEN_R = 75;
        private static final int GREEN_G = 105;
        private static final int GREEN_B = 38;

        private final List<byte[]> pageStreams = new ArrayList<>();
        private StringBuilder content;
        private int pageNumber;
        private float y;

        byte[] build(ReportData report) throws IOException {
            createStyledPageStreams(report);
            return createPdf(pageStreams);
        }

        private void createStyledPageStreams(ReportData report) {
            startPage();
            drawCoverHeader(report);
            drawSummaryCards(report);
            drawSectionTitle("User Information", "Account details for this report.");
            drawInfoTable(report);
            drawSectionTitle("Request Statistics", "Pickup request status totals.");
            drawStatusTable(report);
            drawSectionTitle("Material Weight Totals", "Total recorded recyclable material weight.");
            drawMaterialTable(report.materialTotals);
            finishPage();
        }

        private void startPage() {
            content = new StringBuilder();
            pageNumber++;
            y = PAGE_HEIGHT - MARGIN;
            rect(0, 0, PAGE_WIDTH, PAGE_HEIGHT, 250, 252, 247, true);
            drawFooter();
        }

        private void finishPage() {
            if (content != null) {
                pageStreams.add(content.toString().getBytes(StandardCharsets.US_ASCII));
                content = null;
            }
        }

        private void newPage() {
            finishPage();
            startPage();
        }

        private void drawCoverHeader(ReportData report) {
            String accountType = report.role == null ? "User" : report.role.replace("_", " ");
            rect(0, PAGE_HEIGHT - 150, PAGE_WIDTH, 150, GREEN_R, GREEN_G, GREEN_B, true);
            text(MARGIN, 780, "Recycle Ekhaya", 13, true, 232, 240, 220);
            text(MARGIN, 752, "Individual User Report", 28, true, 255, 255, 255);
            text(MARGIN, 728, truncate(report.name, 68), 12, false, 232, 240, 220);
            text(MARGIN, 709, "Account type: " + accountType + "  |  Generated: " + report.generatedDate,
                    11, false, 232, 240, 220);
            y = 660;
        }

        private void drawSummaryCards(ReportData report) {
            float gap = 12;
            float cardWidth = (CONTENT_WIDTH - (gap * 2)) / 3;
            drawMetricCard(MARGIN, y, cardWidth, "Total Activities", report.totalActivities);
            drawMetricCard(MARGIN + cardWidth + gap, y, cardWidth, "Completed", report.completedRequests);
            drawMetricCard(MARGIN + ((cardWidth + gap) * 2), y, cardWidth, "Active Days", report.activeDays);
            y -= 96;
        }

        private void drawMetricCard(float x, float topY, float width, String label, int value) {
            rect(x, topY - 72, width, 72, 255, 255, 255, true);
            strokeRect(x, topY - 72, width, 72, 218, 226, 209);
            rect(x, topY - 72, 5, 72, GREEN_R, GREEN_G, GREEN_B, true);
            text(x + 16, topY - 24, label, 10, true, 82, 95, 73);
            text(x + 16, topY - 53, String.valueOf(value), 24, true, 37, 45, 31);
        }

        private void drawSectionTitle(String title, String subtitle) {
            ensureSpace(64);
            y -= 8;
            text(MARGIN, y, title, 16, true, 37, 45, 31);
            y -= 17;
            text(MARGIN, y, subtitle, 9, false, 100, 111, 91);
            y -= 16;
        }

        private void drawInfoTable(ReportData report) {
            String accountType = report.role == null ? "User" : report.role.replace("_", " ");
            String[] headers = {"Field", "Value"};
            float[] widths = {170, 341};
            List<String[]> rows = new ArrayList<>();
            rows.add(new String[]{"Name", report.name});
            rows.add(new String[]{"Email", report.email});
            rows.add(new String[]{"User ID", String.valueOf(report.userId)});
            rows.add(new String[]{"Account type", accountType});
            rows.add(new String[]{"Date account was created", report.dateCreated});
            rows.add(new String[]{"Activity period", report.periodStart + " to " + report.periodEnd});
            drawTable(headers, widths, rows, "No account information available.");
        }

        private void drawStatusTable(ReportData report) {
            String[] headers = {"Status", "Requests"};
            float[] widths = {341, 170};
            List<String[]> rows = new ArrayList<>();
            rows.add(new String[]{"Completed", String.valueOf(report.completedRequests)});
            rows.add(new String[]{"Scheduled", String.valueOf(report.scheduledRequests)});
            rows.add(new String[]{"Pending", String.valueOf(report.pendingRequests)});
            rows.add(new String[]{"Cancelled", String.valueOf(report.cancelledRequests)});
            drawTable(headers, widths, rows, "No request activity recorded.");
        }

        private void drawMaterialTable(List<MaterialTotal> totals) {
            String[] headers = {"Material", "Total Weight"};
            float[] widths = {341, 170};
            List<String[]> rows = new ArrayList<>();
            for (MaterialTotal total : totals) {
                rows.add(new String[]{total.material, String.format(Locale.US, "%.1f kg", total.weight)});
            }
            drawTable(headers, widths, rows, "No material activity recorded yet.");
        }

        private void drawTable(String[] headers, float[] widths, List<String[]> rows, String emptyMessage) {
            float rowHeight = 24;
            drawTableHeader(headers, widths);
            if (rows.isEmpty()) {
                ensureSpace(rowHeight);
                rect(MARGIN, y - rowHeight, CONTENT_WIDTH, rowHeight, 255, 255, 255, true);
                strokeRect(MARGIN, y - rowHeight, CONTENT_WIDTH, rowHeight, 218, 226, 209);
                text(MARGIN + 10, y - 16, emptyMessage, 9, false, 100, 111, 91);
                y -= rowHeight + 12;
                return;
            }

            int rowIndex = 0;
            for (String[] row : rows) {
                if (y - rowHeight < BOTTOM_MARGIN) {
                    newPage();
                    drawSectionContinuation();
                    drawTableHeader(headers, widths);
                }
                int fill = rowIndex % 2 == 0 ? 255 : 247;
                rect(MARGIN, y - rowHeight, CONTENT_WIDTH, rowHeight, fill, 249, 244, true);
                strokeRect(MARGIN, y - rowHeight, CONTENT_WIDTH, rowHeight, 218, 226, 209);
                float x = MARGIN;
                for (int i = 0; i < row.length && i < widths.length; i++) {
                    text(x + 6, y - 16, truncate(row[i], maxChars(widths[i], 9)), 9, false, 47, 55, 42);
                    x += widths[i];
                }
                y -= rowHeight;
                rowIndex++;
            }
            y -= 12;
        }

        private void drawTableHeader(String[] headers, float[] widths) {
            ensureSpace(48);
            float headerHeight = 24;
            rect(MARGIN, y - headerHeight, CONTENT_WIDTH, headerHeight, GREEN_R, GREEN_G, GREEN_B, true);
            float x = MARGIN;
            for (int i = 0; i < headers.length; i++) {
                text(x + 6, y - 16, headers[i], 9, true, 255, 255, 255);
                x += widths[i];
            }
            y -= headerHeight;
        }

        private void drawSectionContinuation() {
            y -= 12;
            text(MARGIN, y, "Individual User Report - continued", 13, true, 37, 45, 31);
            y -= 18;
        }

        private void ensureSpace(float requiredHeight) {
            if (y - requiredHeight < BOTTOM_MARGIN) {
                newPage();
                drawSectionContinuation();
            }
        }

        private void drawFooter() {
            line(MARGIN, 38, PAGE_WIDTH - MARGIN, 38, 218, 226, 209);
            text(MARGIN, 24, "Recycle Ekhaya Individual User Report", 8, false, 100, 111, 91);
            text(PAGE_WIDTH - MARGIN - 42, 24, "Page " + pageNumber, 8, false, 100, 111, 91);
        }

        private void rect(float x, float y, float width, float height, int r, int g, int b, boolean fill) {
            content.append(color(r, g, b, fill))
                    .append(format(x)).append(" ").append(format(y)).append(" ")
                    .append(format(width)).append(" ").append(format(height)).append(" re ")
                    .append(fill ? "f\n" : "S\n");
        }

        private void strokeRect(float x, float y, float width, float height, int r, int g, int b) {
            rect(x, y, width, height, r, g, b, false);
        }

        private void line(float x1, float y1, float x2, float y2, int r, int g, int b) {
            content.append(color(r, g, b, false))
                    .append(format(x1)).append(" ").append(format(y1)).append(" m ")
                    .append(format(x2)).append(" ").append(format(y2)).append(" l S\n");
        }

        private void text(float x, float y, String value, int size, boolean bold, int r, int g, int b) {
            content.append(color(r, g, b, true))
                    .append("BT\n/")
                    .append(bold ? "F2" : "F1")
                    .append(" ").append(size).append(" Tf\n")
                    .append(format(x)).append(" ").append(format(y)).append(" Td\n(")
                    .append(escapePdf(value)).append(") Tj\nET\n");
        }

        private String color(int r, int g, int b, boolean fill) {
            return format(r / 255f) + " " + format(g / 255f) + " " + format(b / 255f)
                    + (fill ? " rg\n" : " RG\n");
        }

        private String format(float value) {
            return String.format(Locale.US, "%.2f", value);
        }

        private int maxChars(float width, int fontSize) {
            return Math.max(4, (int) (width / (fontSize * 0.52f)));
        }

        private String truncate(String value, int maxChars) {
            String text = value == null || value.trim().isEmpty() ? "N/A" : value;
            if (text.length() <= maxChars) {
                return text;
            }
            return text.substring(0, Math.max(0, maxChars - 3)) + "...";
        }

        private byte[] createPdf(List<byte[]> pageStreams) throws IOException {
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            List<Integer> objectOffsets = new ArrayList<>();
            int pageCount = pageStreams.size();
            int pagesObjectId = 2;
            int firstPageObjectId = 3;
            int firstStreamObjectId = firstPageObjectId + pageCount;
            int regularFontObjectId = firstStreamObjectId + pageCount;
            int boldFontObjectId = regularFontObjectId + 1;

            write(out, "%PDF-1.4\n");
            writeObject(out, objectOffsets, 1,
                    "<< /Type /Catalog /Pages " + pagesObjectId + " 0 R >>\n");

            StringBuilder kids = new StringBuilder();
            for (int i = 0; i < pageCount; i++) {
                kids.append(firstPageObjectId + i).append(" 0 R ");
            }
            writeObject(out, objectOffsets, pagesObjectId,
                    "<< /Type /Pages /Kids [" + kids + "] /Count " + pageCount + " >>\n");

            for (int i = 0; i < pageCount; i++) {
                int pageObjectId = firstPageObjectId + i;
                int streamObjectId = firstStreamObjectId + i;
                writeObject(out, objectOffsets, pageObjectId,
                        "<< /Type /Page /Parent " + pagesObjectId + " 0 R "
                        + "/MediaBox [0 0 595 842] "
                        + "/Resources << /Font << /F1 " + regularFontObjectId + " 0 R "
                        + "/F2 " + boldFontObjectId + " 0 R >> >> "
                        + "/Contents " + streamObjectId + " 0 R >>\n");
            }

            for (int i = 0; i < pageCount; i++) {
                byte[] stream = pageStreams.get(i);
                objectOffsets.add(out.size());
                write(out, (firstStreamObjectId + i) + " 0 obj\n");
                write(out, "<< /Length " + stream.length + " >>\nstream\n");
                out.write(stream);
                write(out, "\nendstream\n");
                write(out, "endobj\n");
            }

            writeObject(out, objectOffsets, regularFontObjectId,
                    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\n");
            writeObject(out, objectOffsets, boldFontObjectId,
                    "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\n");

            int xrefOffset = out.size();
            write(out, "xref\n0 " + (boldFontObjectId + 1) + "\n");
            write(out, "0000000000 65535 f \n");
            for (Integer offset : objectOffsets) {
                write(out, String.format("%010d 00000 n \n", offset));
            }
            write(out, "trailer\n<< /Size " + (boldFontObjectId + 1) + " /Root 1 0 R >>\n");
            write(out, "startxref\n" + xrefOffset + "\n%%EOF");
            return out.toByteArray();
        }

        private void writeObject(ByteArrayOutputStream out, List<Integer> offsets, int objectId, String body)
                throws IOException {
            offsets.add(out.size());
            write(out, objectId + " 0 obj\n");
            write(out, body);
            write(out, "endobj\n");
        }

        private void write(ByteArrayOutputStream out, String value) throws IOException {
            out.write(value.getBytes(StandardCharsets.US_ASCII));
        }

        private String escapePdf(String value) {
            String ascii = value == null ? "" : value.replaceAll("[^\\x20-\\x7E]", " ");
            return ascii.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)");
        }
    }
}
