package za.ac.tut.web;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import javax.servlet.http.Part;

@MultipartConfig(maxFileSize = 5 * 1024 * 1024, maxRequestSize = 6 * 1024 * 1024)
public class WasteScanServlet extends HttpServlet {

    public static final String SESSION_SCAN_RESULT = "latestScanResult";
    public static final String SESSION_SCANNED_ITEMS = "scannedItems";
    private final WasteAnalysisService service = new WasteAnalysisService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.sendRedirect("scan_item.jsp");
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            response.sendRedirect("login.html");
            return;
        }

        Part filePart;
        try {
            filePart = request.getPart("wasteImage");
        } catch (Exception e) {
            forwardWithError(request, response, "Could not read the uploaded image.");
            return;
        }

        if (filePart == null || filePart.getSize() == 0) {
            forwardWithError(request, response, "Please choose an image to scan.");
            return;
        }

        String mimeType = filePart.getContentType();
        if (mimeType == null || !mimeType.startsWith("image/")) {
            forwardWithError(request, response, "The selected file is not a valid image.");
            return;
        }

        if (!"image/jpeg".equals(mimeType) && !"image/png".equals(mimeType)) {
            mimeType = "image/jpeg";
        }

        byte[] imageBytes = readBytes(filePart);
        String base64Image = Base64.getEncoder().encodeToString(imageBytes);
        WasteAnalysisResult result = service.analyzeWasteImage(base64Image, mimeType);

        session.setAttribute(SESSION_SCAN_RESULT, result);
        if (result.isError()) {
            request.setAttribute("scanError", "The scanner could not identify the item. Try a clearer photo with one item centered, or select the material manually in the pickup request.");
            request.getRequestDispatcher("scan_item.jsp").forward(request, response);
            return;
        }

        addScannedItem(session, result);
        response.sendRedirect("scan_item.jsp?scan=success");
    }

    private byte[] readBytes(Part part) throws IOException {
        try (InputStream is = part.getInputStream();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            int n;
            while ((n = is.read(buffer)) != -1) {
                baos.write(buffer, 0, n);
            }
            return baos.toByteArray();
        }
    }

    private void forwardWithError(HttpServletRequest request, HttpServletResponse response, String message)
            throws ServletException, IOException {
        request.setAttribute("scanError", message);
        request.getRequestDispatcher("scan_item.jsp").forward(request, response);
    }

    @SuppressWarnings("unchecked")
    private void addScannedItem(HttpSession session, WasteAnalysisResult result) {
        List<WasteAnalysisResult> scannedItems = (List<WasteAnalysisResult>) session.getAttribute(SESSION_SCANNED_ITEMS);
        if (scannedItems == null) {
            scannedItems = new ArrayList<>();
        }
        scannedItems.add(result);
        session.setAttribute(SESSION_SCANNED_ITEMS, scannedItems);
    }
}
