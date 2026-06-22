# Use the official Payara Micro image as the base
FROM payara/micro:6.2024.6-jdk17

# Set environment variables (optional)
ENV DEPLOY_DIR=/opt/payara/deployments

# Copy your WAR file to the deployment directory~
COPY target/*.war $DEPLOY_DIR/

# Expose the port your application will run on
EXPOSE 8080

# Start Payara Micro with your application
# (This is the default command, so it's optional)
# CMD ["java", "-jar", "/opt/payara/payara-micro.jar", "--deploy", "/opt/payara/deployments"]