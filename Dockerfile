FROM glassfish:4.1-jdk8

# Add MySQL JDBC driver
COPY mysql-connector-java-8.0.33.jar /glassfish4/glassfish/domains/domain1/lib/

# Copy WAR to autodeploy
COPY EhkayaRecycleWebApplication.war /glassfish4/glassfish/domains/domain1/autodeploy/

# Copy startup script and make executable
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# GlassFish HTTP port
EXPOSE 8080

CMD ["/startup.sh"]
