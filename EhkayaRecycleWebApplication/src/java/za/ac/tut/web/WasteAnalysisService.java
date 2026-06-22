package za.ac.tut.web;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.StringReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import javax.json.Json;
import javax.json.JsonArray;
import javax.json.JsonObject;
import javax.json.JsonReader;
import javax.json.JsonString;
import javax.json.JsonValue;

public class WasteAnalysisService {

    private static final String DEFAULT_API_KEY = "AIzaSyC6e89ZZ3qRikkUiQq4tz2rVVQcDkU0Arg";
    private static final String GEMINI_URL =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=";

    public WasteAnalysisResult analyzeWasteImage(String base64Image, String mimeType) {
        try {
            String requestBody = buildRequest(base64Image, mimeType);
            String response = callApi(requestBody);
            return parseResult(response);
        } catch (Exception e) {
            e.printStackTrace();
            WasteAnalysisResult fallback = new WasteAnalysisResult();
            fallback.setError(true);
            fallback.setItemName("Analysis Failed");
            fallback.setMaterialType("Unknown");
            fallback.setCategory("landfill");
            List<String> instructions = new ArrayList<>();
            instructions.add("The scanner could not analyse this image.");
            instructions.add("Please try another photo or select the material manually.");
            fallback.setDisposalInstructions(instructions);
            fallback.setEnvironmentalImpact("Unable to determine. Please dispose responsibly.");
            return fallback;
        }
    }

    private String buildRequest(String base64Image, String mimeType) {
        String prompt =
                "You are a waste management expert for a household recycling pickup system in South Africa. "
                + "Analyze this image and identify the main waste item. Give practical sorting instructions and the correct bin. "
                + "Return ONLY valid JSON in this exact format: "
                + "{\"materialType\":\"Plastic\",\"category\":\"recyclable\",\"itemName\":\"Plastic bottle\","
                + "\"disposalInstructions\":[\"Empty and rinse the bottle\",\"Remove the cap if required locally\",\"Place it in the plastic recycling bin\"],"
                + "\"environmentalImpact\":\"Short impact statement\"}. "
                + "Categories must be one of: recyclable, compostable, special, landfill. "
                + "Materials must be one of: Glass, Metal, Paper, Plastic, Organic, Electronic, Cardboard, Mixed.";

        JsonObject imagePart = Json.createObjectBuilder()
                .add("inlineData", Json.createObjectBuilder()
                        .add("mimeType", mimeType)
                        .add("data", base64Image))
                .build();

        JsonObject content = Json.createObjectBuilder()
                .add("parts", Json.createArrayBuilder()
                        .add(Json.createObjectBuilder().add("text", prompt))
                        .add(imagePart))
                .build();

        JsonObject request = Json.createObjectBuilder()
                .add("contents", Json.createArrayBuilder().add(content))
                .add("generationConfig", Json.createObjectBuilder()
                        .add("temperature", 0.2)
                        .add("maxOutputTokens", 1024))
                .build();

        return request.toString();
    }

    private String callApi(String requestBody) throws IOException {
        String apiKey = getApiKey();
        URL url = new URL(GEMINI_URL + apiKey);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout(30000);
        conn.setReadTimeout(60000);

        try (OutputStream os = conn.getOutputStream()) {
            os.write(requestBody.getBytes(StandardCharsets.UTF_8));
        }

        int responseCode = conn.getResponseCode();
        StringBuilder response = new StringBuilder();
        try (BufferedReader br = new BufferedReader(new InputStreamReader(
                responseCode == 200 ? conn.getInputStream() : conn.getErrorStream(),
                StandardCharsets.UTF_8))) {
            String line;
            while ((line = br.readLine()) != null) {
                response.append(line);
            }
        }

        if (responseCode != 200) {
            throw new IOException("Gemini API returned " + responseCode + ": " + response.toString());
        }

        return response.toString();
    }

    private String getApiKey() {
        String envKey = System.getenv("GEMINI_API_KEY");
        if (envKey != null && !envKey.trim().isEmpty()) {
            return envKey.trim();
        }
        String propertyKey = System.getProperty("gemini.api.key");
        if (propertyKey != null && !propertyKey.trim().isEmpty()) {
            return propertyKey.trim();
        }
        return DEFAULT_API_KEY;
    }

    private WasteAnalysisResult parseResult(String responseBody) {
        JsonObject apiResponse = readObject(responseBody);
        String text = apiResponse.getJsonArray("candidates")
                .getJsonObject(0)
                .getJsonObject("content")
                .getJsonArray("parts")
                .getJsonObject(0)
                .getString("text", "");

        String cleanText = extractJson(text);
        JsonObject result = readObject(cleanText);

        WasteAnalysisResult wasteResult = new WasteAnalysisResult();
        wasteResult.setMaterialType(getString(result, "materialType", "Unknown"));
        wasteResult.setCategory(getString(result, "category", "landfill"));
        wasteResult.setItemName(getString(result, "itemName", "Unknown Item"));
        wasteResult.setEnvironmentalImpact(getString(result, "environmentalImpact", "Please dispose responsibly."));
        wasteResult.setDisposalInstructions(addItemSpecificInstructions(
                getInstructions(result),
                wasteResult.getMaterialType(),
                wasteResult.getItemName()));
        wasteResult.setError(false);
        return wasteResult;
    }

    private JsonObject readObject(String json) {
        try (JsonReader reader = Json.createReader(new StringReader(json))) {
            return reader.readObject();
        }
    }

    private String extractJson(String text) {
        String cleanText = text == null ? "" : text.replace("```json", "").replace("```", "").trim();
        int start = cleanText.indexOf('{');
        int end = cleanText.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return cleanText.substring(start, end + 1);
        }
        return cleanText;
    }

    private String getString(JsonObject obj, String key, String defaultValue) {
        return obj.containsKey(key) && !obj.isNull(key) ? obj.getString(key, defaultValue) : defaultValue;
    }

    private List<String> getInstructions(JsonObject result) {
        List<String> instructions = new ArrayList<>();
        if (result.containsKey("disposalInstructions") && result.get("disposalInstructions").getValueType() == JsonValue.ValueType.ARRAY) {
            JsonArray array = result.getJsonArray("disposalInstructions");
            for (JsonValue value : array) {
                if (value.getValueType() == JsonValue.ValueType.STRING) {
                    instructions.add(((JsonString) value).getString());
                }
            }
        }
        if (instructions.isEmpty()) {
            instructions.add("Prepare the item for recycling pickup.");
            instructions.add("Select the detected material in the pickup request.");
        }
        return instructions;
    }

    private List<String> addItemSpecificInstructions(List<String> instructions, String materialType, String itemName) {
        List<String> updatedInstructions = new ArrayList<>(instructions);
        String material = materialType == null ? "" : materialType.toLowerCase();
        String item = itemName == null ? "" : itemName.toLowerCase();

        if (material.contains("metal") && item.contains("can")) {
            addIfMissing(updatedInstructions, "If the can is still in its normal shape, crush it to save space before recycling.");
        }

        if (material.contains("glass") && item.contains("bottle")) {
            addIfMissing(updatedInstructions, "If the glass bottle is still whole, crush it carefully and handle the pieces safely.");
        }

        return updatedInstructions;
    }

    private void addIfMissing(List<String> instructions, String newInstruction) {
        for (String instruction : instructions) {
            if (instruction != null && instruction.equalsIgnoreCase(newInstruction)) {
                return;
            }
        }
        instructions.add(newInstruction);
    }
}
