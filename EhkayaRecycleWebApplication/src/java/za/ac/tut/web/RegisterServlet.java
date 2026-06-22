package za.ac.tut.web;

import java.io.IOException;
import javax.servlet.RequestDispatcher;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import za.ac.tut.db.CenterDAO;
import za.ac.tut.db.HouseholdDAO;
import za.ac.tut.object.address.Address;
import za.ac.tut.object.personalinfo.PersonalInfo;
import za.ac.tut.object.credentials.Credentials;

public class RegisterServlet extends HttpServlet {

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        HttpSession session = request.getSession();
        String step = request.getParameter("step");
        String url = "signup_household1.jsp";

        try {
            switch (step) {
                case "credentials":
                    url = handleCredentials(request, session);
                    break;
                case "personalInfo":
                    url = handlePersonalInfo(request, session);
                    break;
                case "centerInfo":
                    url = handleCenterInfo(request, session);
                    break;
                case "address":
                    url = handleAddress(request, session);
                    break;
                case "confirm":
                    url = handleConfirm(request, session);
                    break;
                default:
                    session.setAttribute("errorMessage", "Invalid step: " + step);
                    url = "signup_household1.jsp";
            }
        } catch (Exception e) {
            System.err.println("Servlet Error: " + e.getMessage());
            e.printStackTrace();
            session.setAttribute("errorMessage", "An error occurred: " + e.getMessage());
            url = "signup_household1.jsp";
        }

        RequestDispatcher rd = request.getRequestDispatcher(url);
        rd.forward(request, response);
    }

    private String handleCredentials(HttpServletRequest request, HttpSession session) {
        String role = request.getParameter("role");
        String email = request.getParameter("email");
        String password = request.getParameter("password");
        String passwordConfirm = request.getParameter("passwordConfirm");

        if (email == null || email.trim().isEmpty() || !email.contains("@")) {
            session.setAttribute("errorMessage", "Please enter a valid email address!");
            return "signup_household1.jsp";
        }

        if (password == null || !password.equals(passwordConfirm)) {
            session.setAttribute("errorMessage", "Passwords do not match!");
            return "signup_household1.jsp";
        }

        if (password.length() < 6) {
            session.setAttribute("errorMessage", "Password must be at least 6 characters!");
            return "signup_household1.jsp";
        }

        Credentials cred = storeCredentials(role, email, password);
        session.setAttribute("credentials", cred);
        session.removeAttribute("errorMessage");

        if (role.equalsIgnoreCase("household_user")) {
            return "signup_household2.jsp";
        } else if (role.equalsIgnoreCase("recycle_center")) {
            return "signup_centre2.jsp";
        } else {
            session.setAttribute("errorMessage", "Invalid role selected");
            return "signup_household1.jsp";
        }
    }

    private String handlePersonalInfo(HttpServletRequest request, HttpSession session) {
        String name = request.getParameter("firstname");
        String surname = request.getParameter("lastname");
        String phoneNumber = request.getParameter("phone");

        if (name == null || name.trim().isEmpty() || 
            surname == null || surname.trim().isEmpty() || 
            phoneNumber == null || phoneNumber.trim().isEmpty()) {
            session.setAttribute("errorMessage", "All personal information fields are required!");
            return "signup_household2.jsp";
        }

        if (!phoneNumber.matches("\\d{10}")) {
            session.setAttribute("errorMessage", "Phone number must be 10 digits!");
            return "signup_household2.jsp";
        }

        PersonalInfo info = storePersonalInfo(name, surname, phoneNumber);
        session.setAttribute("personalInfo", info);
        session.removeAttribute("errorMessage");

        return "signup_household3.jsp";
    }

    private String handleCenterInfo(HttpServletRequest request, HttpSession session) {
        String centerName = request.getParameter("centre_name");
        String centerNumber = request.getParameter("centre_number");

        if (centerName == null || centerName.trim().isEmpty()) {
            session.setAttribute("errorMessage", "Centre name is required!");
            return "signup_centre2.jsp";
        }

        if (centerNumber == null || centerNumber.trim().isEmpty()) {
            session.setAttribute("errorMessage", "Phone number is required!");
            return "signup_centre2.jsp";
        }

        if (!centerNumber.matches("\\d{10}")) {
            session.setAttribute("errorMessage", "Phone number must be 10 digits!");
            return "signup_centre2.jsp";
        }

        session.setAttribute("centerName", centerName);
        session.setAttribute("centerNumber", centerNumber);
        session.removeAttribute("errorMessage");

        return "signup_centre3.jsp";
    }

    private String handleAddress(HttpServletRequest request, HttpSession session) {
        String streetAddress = request.getParameter("street");
        String city = request.getParameter("city");
        String province = request.getParameter("province");
        String postalCode = request.getParameter("postal");

        System.out.println("\n========== ADDRESS RECEIVED ==========");
        System.out.println("Street: " + streetAddress);
        System.out.println("City: " + city);
        System.out.println("Province: " + province);
        System.out.println("Postal Code: " + postalCode);
        System.out.println("=======================================\n");

        if (streetAddress == null || streetAddress.trim().isEmpty() ||
            city == null || city.trim().isEmpty() ||
            province == null || province.trim().isEmpty() ||
            postalCode == null || postalCode.trim().isEmpty()) {
            session.setAttribute("errorMessage", "All address fields are required!");
            
            Credentials creds = (Credentials) session.getAttribute("credentials");
            if (creds != null && creds.getRole().equalsIgnoreCase("household_user")) {
                return "signup_household3.jsp";
            } else {
                return "signup_centre3.jsp";
            }
        }

        if (!postalCode.matches("\\d{4}")) {
            session.setAttribute("errorMessage", "Postal code must be 4 digits!");
            
            Credentials creds = (Credentials) session.getAttribute("credentials");
            if (creds != null && creds.getRole().equalsIgnoreCase("household_user")) {
                return "signup_household3.jsp";
            } else {
                return "signup_centre3.jsp";
            }
        }

        Address address = storeAddress(streetAddress, city, province, postalCode);
        
        Double latitude = null;
        Double longitude = null;
        boolean geocodingFailed = false;
        String geocodingErrorMessage = null;
        
        try {
            double[] coords = MapboxGeocodingService.addressToLatLon(streetAddress, city, province, postalCode);
            if (coords == null) {
                geocodingFailed = true;
                geocodingErrorMessage = "Address could not be located.";
                System.err.println("Geocoding returned no coordinates for: " + streetAddress + ", " + city);
            } else {
                latitude = coords[0];
                longitude = coords[1];
            }
            System.out.println("✅ Geocoding SUCCESS for: " + streetAddress + ", " + city);
            System.out.println("   → Latitude: " + latitude + ", Longitude: " + longitude);
        } catch (Exception e) {
            geocodingFailed = true;
            geocodingErrorMessage = e.getMessage();
            System.err.println("❌ Geocoding FAILED for: " + streetAddress + ", " + city);
            System.err.println("   Error: " + geocodingErrorMessage);
        }
        
        session.setAttribute("address", address);
        session.setAttribute("latitude", latitude);
        session.setAttribute("longitude", longitude);
        session.setAttribute("geocodingFailed", geocodingFailed);
        session.setAttribute("geocodingError", geocodingErrorMessage);
        session.removeAttribute("errorMessage");

        Credentials creds = (Credentials) session.getAttribute("credentials");
        if (creds == null) {
            session.setAttribute("errorMessage", "Session expired. Please start over.");
            return "signup_household1.jsp";
        }

        if (creds.getRole().equalsIgnoreCase("household_user")) {
            return "signup_household4.jsp";
        } else {
            return "signup_centre4.jsp";
        }
    }

    private String handleConfirm(HttpServletRequest request, HttpSession session) {
        Credentials credentials = (Credentials) session.getAttribute("credentials");
        Address address = (Address) session.getAttribute("address");
        
        Double latitude = (Double) session.getAttribute("latitude");
        Double longitude = (Double) session.getAttribute("longitude");
        Boolean geocodingFailed = (Boolean) session.getAttribute("geocodingFailed");
        String geocodingError = (String) session.getAttribute("geocodingError");
        
        if (geocodingFailed == null) {
            geocodingFailed = false;
        }

        if (credentials == null) {
            session.setAttribute("errorMessage", "Session expired. Please start over.");
            return "signup_household1.jsp";
        }

        if (address == null) {
            session.setAttribute("errorMessage", "Missing address information. Please start over.");
            return "signup_household1.jsp";
        }

        System.out.println("\n========== REGISTRATION CONFIRMATION ==========");
        System.out.println("Email: " + credentials.getEmail());
        System.out.println("Role: " + credentials.getRole());
        System.out.println("Coordinates: " + (latitude != null ? latitude + ", " + longitude : "NULL (geocoding failed)"));
        System.out.println("================================================\n");

        boolean isRegistered = false;
        String role = credentials.getRole();

        try {
            if (role.equalsIgnoreCase("household_user")) {
                PersonalInfo persInfo = (PersonalInfo) session.getAttribute("personalInfo");
                if (persInfo == null) {
                    session.setAttribute("errorMessage", "Missing personal information. Please start over.");
                    return "signup_household1.jsp";
                }
                
                HouseholdDAO user = new HouseholdDAO();
                isRegistered = user.registerHousehold(credentials, persInfo, address, latitude, longitude);
                
            } else if (role.equalsIgnoreCase("recycle_center")) {
                String centerName = (String) session.getAttribute("centerName");
                String centerNumber = (String) session.getAttribute("centerNumber");
                
                if (centerName == null || centerNumber == null) {
                    session.setAttribute("errorMessage", "Missing center information. Please start over.");
                    return "signup_centre2.jsp";
                }
                
                CenterDAO user = new CenterDAO();
                isRegistered = user.registerCenter(credentials, centerName, centerNumber, address, latitude, longitude);
                
            } else {
                session.setAttribute("errorMessage", "Invalid role: " + role);
                return "signup_household1.jsp";
            }
            
        } catch (Exception e) {
            System.err.println("Registration exception: " + e.getMessage());
            e.printStackTrace();
            isRegistered = false;
        }

        if (isRegistered) {
            session.removeAttribute("credentials");
            session.removeAttribute("personalInfo");
            session.removeAttribute("address");
            session.removeAttribute("centerName");
            session.removeAttribute("centerNumber");
            session.removeAttribute("latitude");
            session.removeAttribute("longitude");
            session.removeAttribute("geocodingFailed");
            session.removeAttribute("geocodingError");
            
            if (geocodingFailed) {
                if (latitude != null) {
                    session.setAttribute("warningMessage", "Registration successful! Used approximate coordinates for your area.");
                } else {
                    session.setAttribute("warningMessage", "Registration successful! However, address geocoding failed. Please contact support to update your location.");
                }
            } else {
                session.setAttribute("successMessage", "Registration successful! Your location has been mapped.");
            }
            return "signup_success.jsp";
        } else {
            session.setAttribute("errorMessage", "Registration failed. Email may already exist or database error. Please try again with a different email.");
            
            if (role.equalsIgnoreCase("household_user")) {
                return "signup_household4.jsp";
            } else {
                return "signup_centre4.jsp";
            }
        }
    }

    private Credentials storeCredentials(String role, String email, String password) {
        String hashedPassword = org.mindrot.jbcrypt.BCrypt.hashpw(password, org.mindrot.jbcrypt.BCrypt.gensalt(12));
        return new Credentials(role, email, hashedPassword);
    }

    private PersonalInfo storePersonalInfo(String firstname, String lastName, String phoneNumber) {
        return new PersonalInfo(firstname, lastName, phoneNumber);
    }

    private Address storeAddress(String streetAddress, String city, String province, String postalCode) {
        return new Address(streetAddress, city, province, postalCode);
    }
}
