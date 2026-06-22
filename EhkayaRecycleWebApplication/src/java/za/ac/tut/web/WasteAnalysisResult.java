package za.ac.tut.web;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.List;

public class WasteAnalysisResult implements Serializable {

    private String materialType;
    private String category;
    private String itemName;
    private List<String> disposalInstructions;
    private String environmentalImpact;
    private boolean error;

    public WasteAnalysisResult() {
        this.materialType = "Unknown";
        this.category = "landfill";
        this.itemName = "Unknown Item";
        this.disposalInstructions = new ArrayList<>();
        this.disposalInstructions.add("Unable to identify item. Please retake the photo.");
        this.disposalInstructions.add("Use good lighting and make sure the item is clearly visible.");
        this.environmentalImpact = "Unable to determine. Please dispose responsibly.";
        this.error = false;
    }

    public String getPickupMaterial() {
        String material = materialType == null ? "" : materialType.trim().toLowerCase();
        String item = itemName == null ? "" : itemName.trim().toLowerCase();
        String cat = category == null ? "" : category.trim().toLowerCase();

        if (material.contains("plastic") || item.contains("plastic")) return "Plastic";
        if (material.contains("paper") || item.contains("paper")) return "Paper";
        if (material.contains("cardboard") || item.contains("cardboard")) return "Cardboard";
        if (material.contains("glass") || item.contains("glass")) return "Glass";
        if (material.contains("metal") || item.contains("metal") || item.contains("can")) return "Metal";
        if (material.contains("electronic") || item.contains("battery") || item.contains("phone")) return "Electronics";
        if (material.contains("organic") || cat.contains("compost")) return "Organic";
        if (material.contains("mixed")) return "Mixed";
        return "Plastic";
    }

    public String getBinLabel() {
        String cat = category == null ? "" : category.trim().toLowerCase();
        String material = getPickupMaterial();

        if ("compostable".equals(cat) || "Organic".equals(material)) {
            return "Green organic or compost bin";
        }
        if ("special".equals(cat) || "Electronics".equals(material)) {
            return "Special disposal or e-waste bin";
        }
        if ("landfill".equals(cat)) {
            return "General waste bin";
        }
        if ("Glass".equals(material)) {
            return "Glass recycling bin";
        }
        if ("Metal".equals(material)) {
            return "Metal recycling bin";
        }
        if ("Paper".equals(material) || "Cardboard".equals(material)) {
            return "Paper and cardboard recycling bin";
        }
        if ("Plastic".equals(material)) {
            return "Plastic recycling bin";
        }
        return "Mixed recycling bin";
    }

    public String getCategoryLabel() {
        if (category == null) {
            return "General waste";
        }
        String cat = category.trim().toLowerCase();
        if ("recyclable".equals(cat)) return "Recyclable";
        if ("compostable".equals(cat)) return "Compostable";
        if ("special".equals(cat)) return "Special disposal";
        if ("landfill".equals(cat)) return "General waste";
        return category;
    }

    public String getMaterialType() {
        return materialType;
    }

    public void setMaterialType(String materialType) {
        this.materialType = materialType;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getItemName() {
        return itemName;
    }

    public void setItemName(String itemName) {
        this.itemName = itemName;
    }

    public List<String> getDisposalInstructions() {
        return disposalInstructions;
    }

    public void setDisposalInstructions(List<String> disposalInstructions) {
        this.disposalInstructions = disposalInstructions;
    }

    public String getEnvironmentalImpact() {
        return environmentalImpact;
    }

    public void setEnvironmentalImpact(String environmentalImpact) {
        this.environmentalImpact = environmentalImpact;
    }

    public boolean isError() {
        return error;
    }

    public void setError(boolean error) {
        this.error = error;
    }
}
