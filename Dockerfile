FROM payara/micro:6.2024.6-jdk17

# Set deployment directory
ENV DEPLOY_DIR=/opt/payara/deployments

# Copy WAR from local build
COPY EhkayaRecycleWebApplication/dist/*.war $DEPLOY_DIR/

# Expose the port
EXPOSE 8080

# Start Payara Micro
CMD ["java", "-jar", "/opt/payara/payara-micro.jar", "--deploydir", "/opt/payara/deployments"]