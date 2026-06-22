package za.ac.tut.object.credentials;

public class Credentials {
    
    private String role;
    private String email;
    private String password;

    public Credentials(String role, String email, String password) {
        this.role = role;
        this.email = email;
        this.password = password;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }
    
    
}
