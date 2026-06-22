package za.ac.tut.db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBManager 
{   
    // Clever Cloud MySQL Database Configuration
    private static final String DB_IP = "bjdjal9nknkxxzjy9utc-mysql.services.clever-cloud.com";
    private static final String DB_PORT = "3306";
    private static final String DB_NAME = "bjdjal9nknkxxzjy9utc";
    private static final String USER = "ugtyek4gezopdorz";
    private static final String PASS = "kSxwmOueUTMKSTcLZl69";
    
    // JDBC URL with SSL disabled (or enabled - see notes below)
    private static final String URL = "jdbc:mysql://" + DB_IP + ":" + DB_PORT + "/" + DB_NAME + 
                                       "?useSSL=false" +
                                       "&allowPublicKeyRetrieval=true" +
                                       "&serverTimezone=UTC" +
                                       "&connectTimeout=10000";
    
    static 
    {
        try 
        {
            System.out.println("Loading MySQL driver...");
            Class.forName("com.mysql.cj.jdbc.Driver");
            System.out.println("MySQL driver loaded successfully!");
        } 
        catch (ClassNotFoundException e) 
        {
            System.err.println("ERROR: MySQL JDBC Driver not found!");
            System.err.println("Please add mysql-connector-java-8.0.17.jar to WEB-INF/lib");
            System.err.println("Current classpath: " + System.getProperty("java.class.path"));
            e.printStackTrace();
        }
    }
    
    public static Connection getConnection() throws SQLException 
    {
        try 
        {
            System.out.println("Attempting connection to Clever Cloud MySQL...");
            System.out.println("URL: " + URL);
            System.out.println("User: " + USER);
            System.out.println("Database: " + DB_NAME);
            
            Connection conn = DriverManager.getConnection(URL, USER, PASS);
            System.out.println("✅ Database connected successfully!");
            System.out.println("Connected to: " + conn.getMetaData().getURL());
            System.out.println("MySQL Version: " + conn.getMetaData().getDatabaseProductVersion());
            return conn;
        } 
        catch (SQLException e) 
        {
            System.err.println("❌ ERROR: Failed to connect to database!");
            System.err.println("Error Code: " + e.getErrorCode());
            System.err.println("Error Message: " + e.getMessage());
            System.err.println("SQL State: " + e.getSQLState());
            System.err.println("Host: " + DB_IP);
            System.err.println("Database: " + DB_NAME);
            System.err.println("User: " + USER);
            throw e;
        }
    }
    
    // Optional: Method to test connection
    public static void main(String[] args) 
    {
        try 
        {
            Connection conn = getConnection();
            System.out.println("✅ Connection test successful!");
            conn.close();
            System.out.println("Connection closed.");
        } 
        catch (SQLException e) 
        {
            System.err.println("❌ Connection test failed!");
            e.printStackTrace();
        }
    }
}