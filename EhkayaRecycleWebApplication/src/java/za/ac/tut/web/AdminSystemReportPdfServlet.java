package za.ac.tut.web;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Date;
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

public class AdminSystemReportPdfServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession(false);
        Integer adminId = session == null ? null : (Integer) session.getAttribute("userId");
        String role = session == null ? null : (String) session.getAttribute("userRole");

        if (adminId == null || role == null) {
            response.sendRedirect("login.html");
            return;
        }

        if (!"admin".equalsIgnoreCase(role)) {
            response.sendRedirect("household_user_dashboard.jsp");
            return;
        }

        LocalDate endDate = parseDate(request.getParameter("endDate"), LocalDate.now());
        LocalDate startDate = parseDate(request.getParameter("startDate"), endDate.withDayOfMonth(1));
        if (startDate.isAfter(endDate)) {
            LocalDate temp = startDate;
            startDate = endDate;
            endDate = temp;
        }

        try (Connection conn = DBManager.getConnection()) {
            SystemReportData report = buildReport(conn, startDate, endDate);
            byte[] pdf = new PdfBuilder().build(report);

            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition",
                    "attachment; filename=\"Recycle_Ekhaya_System_Report_"
                    + startDate + "_to_" + endDate + ".pdf\"");
            response.setContentLength(pdf.length);
            response.getOutputStream().write(pdf);
        } catch (Exception e) {
            throw new ServletException("Could not generate admin system report PDF", e);
        }
    }

    private SystemReportData buildReport(Connection conn, LocalDate startDate, LocalDate endDate)
            throws SQLException {
        SystemReportData report = new SystemReportData();
        report.startDate = startDate;
        report.endDate = endDate;
        report.generatedDate = LocalDate.now();

        loadSummary(conn, report);
        loadGeography(conn, report);
        loadTopHouseholds(conn, report);
        loadTopCentres(conn, report);

        return report;
    }

    private void loadSummary(Connection conn, SystemReportData report) throws SQLException {
        report.totalActiveUsers = singleInt(conn,
                "SELECT COUNT(DISTINCT activity_user_id) AS total_count FROM ("
                + "SELECT household_user_id AS activity_user_id FROM PICKUP_REQUEST "
                + "WHERE DATE(created_date) BETWEEN ? AND ? "
                + "UNION "
                + "SELECT centre_id AS activity_user_id FROM PICKUP_REQUEST "
                + "WHERE centre_id IS NOT NULL AND DATE(COALESCE(scheduled_date, created_date)) BETWEEN ? AND ?"
                + ") active_users",
                report.startDate, report.endDate, report.startDate, report.endDate);

        report.newUsers = singleInt(conn,
                "SELECT COUNT(*) AS total_count FROM USERS WHERE DATE(date_created) BETWEEN ? AND ?",
                report.startDate, report.endDate);

        report.monthlyActiveUsers = report.totalActiveUsers;
    }

    private void loadGeography(Connection conn, SystemReportData report) throws SQLException {
        String sql = "SELECT province, SUM(households) AS households, SUM(centres) AS centres "
                + "FROM ("
                + "SELECT COALESCE(NULLIF(province, ''), 'Unknown') AS province, COUNT(*) AS households, 0 AS centres "
                + "FROM HOUSEHOLD_USER GROUP BY COALESCE(NULLIF(province, ''), 'Unknown') "
                + "UNION ALL "
                + "SELECT COALESCE(NULLIF(province, ''), 'Unknown') AS province, 0 AS households, COUNT(*) AS centres "
                + "FROM RECYCLE_CENTRE GROUP BY COALESCE(NULLIF(province, ''), 'Unknown')"
                + ") geo GROUP BY province ORDER BY province";

        try (PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                report.geography.add(new GeographyRow(
                        valueOrDefault(rs.getString("province"), "Unknown"),
                        rs.getInt("households"),
                        rs.getInt("centres")));
            }
        }
    }

    private void loadTopHouseholds(Connection conn, SystemReportData report) throws SQLException {
        String sql = "SELECT hu.user_id, CONCAT(hu.first_name, ' ', hu.last_name) AS display_name, "
                + "u.email_address, COUNT(pr.request_id) AS request_count "
                + "FROM HOUSEHOLD_USER hu "
                + "JOIN USERS u ON hu.user_id = u.user_id "
                + "JOIN PICKUP_REQUEST pr ON hu.user_id = pr.household_user_id "
                + "WHERE DATE(pr.created_date) BETWEEN ? AND ? "
                + "GROUP BY hu.user_id, hu.first_name, hu.last_name, u.email_address "
                + "ORDER BY request_count DESC, display_name ASC LIMIT 10";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(report.startDate));
            ps.setDate(2, Date.valueOf(report.endDate));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    report.topHouseholds.add(new ActivityRow(
                            rs.getInt("user_id"),
                            valueOrDefault(rs.getString("display_name"), "Household User"),
                            valueOrDefault(rs.getString("email_address"), "N/A"),
                            rs.getInt("request_count")));
                }
            }
        }
    }

    private void loadTopCentres(Connection conn, SystemReportData report) throws SQLException {
        String sql = "SELECT rc.user_id, rc.centre_name AS display_name, u.email_address, "
                + "COUNT(pr.request_id) AS completed_count "
                + "FROM RECYCLE_CENTRE rc "
                + "JOIN USERS u ON rc.user_id = u.user_id "
                + "JOIN PICKUP_REQUEST pr ON rc.user_id = pr.centre_id "
                + "LEFT JOIN COLLECTION_RECORD cr ON pr.request_id = cr.request_id "
                + "WHERE pr.request_status = 'completed' "
                + "AND DATE(COALESCE(cr.collection_date, pr.scheduled_date, pr.created_date)) BETWEEN ? AND ? "
                + "GROUP BY rc.user_id, rc.centre_name, u.email_address "
                + "ORDER BY completed_count DESC, display_name ASC LIMIT 10";

        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setDate(1, Date.valueOf(report.startDate));
            ps.setDate(2, Date.valueOf(report.endDate));
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    report.topCentres.add(new ActivityRow(
                            rs.getInt("user_id"),
                            valueOrDefault(rs.getString("display_name"), "Recycle Centre"),
                            valueOrDefault(rs.getString("email_address"), "N/A"),
                            rs.getInt("completed_count")));
                }
            }
        }
    }

    private int singleInt(Connection conn, String sql, LocalDate... dates) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            for (int i = 0; i < dates.length; i++) {
                ps.setDate(i + 1, Date.valueOf(dates[i]));
            }
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt("total_count") : 0;
            }
        }
    }

    private LocalDate parseDate(String value, LocalDate defaultValue) {
        if (value == null || value.trim().isEmpty()) {
            return defaultValue;
        }
        try {
            return LocalDate.parse(value.trim(), DateTimeFormatter.ISO_LOCAL_DATE);
        } catch (Exception e) {
            return defaultValue;
        }
    }

    private static String valueOrDefault(String value, String defaultValue) {
        return value == null || value.trim().isEmpty() ? defaultValue : value.trim();
    }

    private static class SystemReportData {
        LocalDate startDate;
        LocalDate endDate;
        LocalDate generatedDate;
        int totalActiveUsers;
        int newUsers;
        int monthlyActiveUsers;
        List<GeographyRow> geography = new ArrayList<>();
        List<ActivityRow> topHouseholds = new ArrayList<>();
        List<ActivityRow> topCentres = new ArrayList<>();
    }

    private static class GeographyRow {
        final String province;
        final int households;
        final int centres;

        GeographyRow(String province, int households, int centres) {
            this.province = province;
            this.households = households;
            this.centres = centres;
        }
    }

    private static class ActivityRow {
        final int userId;
        final String name;
        final String email;
        final int count;

        ActivityRow(int userId, String name, String email, int count) {
            this.userId = userId;
            this.name = name;
            this.email = email;
            this.count = count;
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

        byte[] build(SystemReportData report) throws IOException {
            createStyledPageStreams(report);
            return createPdf(pageStreams);
        }

        private void createStyledPageStreams(SystemReportData report) {
            startPage();
            drawCoverHeader(report);
            drawSummaryCards(report);
            drawSectionTitle("User Geography", "Registered households and recycle centres by province.");
            drawGeographyTable(report.geography);
            drawSectionTitle("Top 10 Most Active Household Users",
                    "Measured by pickup requests created in the selected report period.");
            drawActivityTable(report.topHouseholds, "Requests");
            drawSectionTitle("Top 10 Most Active Recycle Users",
                    "Measured by completed pickup requests in the selected report period.");
            drawActivityTable(report.topCentres, "Completed");
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

        private void drawCoverHeader(SystemReportData report) {
            rect(0, PAGE_HEIGHT - 150, PAGE_WIDTH, 150, GREEN_R, GREEN_G, GREEN_B, true);
            text(MARGIN, 780, "Recycle Ekhaya", 13, true, 232, 240, 220);
            text(MARGIN, 752, "System Report", 28, true, 255, 255, 255);
            text(MARGIN, 728, "Report period: " + report.startDate + " to " + report.endDate,
                    12, false, 232, 240, 220);
            text(MARGIN, 709, "Generated: " + report.generatedDate, 11, false, 232, 240, 220);
            y = 660;
        }

        private void drawSummaryCards(SystemReportData report) {
            float gap = 12;
            float cardWidth = (CONTENT_WIDTH - (gap * 2)) / 3;
            drawMetricCard(MARGIN, y, cardWidth, "Total Active Users", report.totalActiveUsers);
            drawMetricCard(MARGIN + cardWidth + gap, y, cardWidth, "New Users", report.newUsers);
            drawMetricCard(MARGIN + ((cardWidth + gap) * 2), y, cardWidth,
                    "Monthly Active Users", report.monthlyActiveUsers);
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

        private void drawGeographyTable(List<GeographyRow> rows) {
            String[] headers = {"Province", "Household Users", "Recycle Centres", "Total"};
            float[] widths = {205, 110, 110, 86};
            List<String[]> tableRows = new ArrayList<>();
            for (GeographyRow row : rows) {
                tableRows.add(new String[]{
                    row.province,
                    String.valueOf(row.households),
                    String.valueOf(row.centres),
                    String.valueOf(row.households + row.centres)
                });
            }
            drawTable(headers, widths, tableRows, "No geography data available.");
        }

        private void drawActivityTable(List<ActivityRow> rows, String countLabel) {
            String[] headers = {"#", "User ID", "Name", "Email", countLabel};
            float[] widths = {32, 60, 154, 205, 60};
            List<String[]> tableRows = new ArrayList<>();
            int rank = 1;
            for (ActivityRow row : rows) {
                tableRows.add(new String[]{
                    String.valueOf(rank++),
                    String.valueOf(row.userId),
                    row.name,
                    row.email,
                    String.valueOf(row.count)
                });
            }
            drawTable(headers, widths, tableRows, "No activity recorded for this period.");
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
            text(MARGIN, y, "System Report - continued", 13, true, 37, 45, 31);
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
            text(MARGIN, 24, "Recycle Ekhaya System Report", 8, false, 100, 111, 91);
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
            String text = valueOrDefault(value, "N/A");
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
