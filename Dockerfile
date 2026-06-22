FROM payara/server-full:5.2022.5

# Add MySQL JDBC driver
COPY mysql-connector-java-8.0.33.jar /opt/payara/appserver/glassfish/domains/production/lib/

# Copy WAR to autodeploy
COPY EhkayaRecycleWebApplication.war /opt/payara/appserver/glassfish/domains/production/autodeploy/

# Copy startup script and make executable
COPY startup.sh /startup.sh
RUN chmod +x /startup.sh

# GlassFish HTTP port
EXPOSE 8080

CMD ["/startup.sh"]