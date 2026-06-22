# Stage 1: Build the WAR file using Ant
FROM openjdk:17-jdk-slim AS build

# Install Ant
RUN apt-get update && \
    apt-get install -y ant && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy the entire NetBeans project
COPY EhkayaRecycleWebApplication/ .

# Build the WAR file using Ant
RUN ant -f nbproject/build-impl.xml dist

# Stage 2: Deploy with Payara Micro
FROM payara/micro:6.2024.6-jdk17

# Set deployment directory
ENV DEPLOY_DIR=/opt/payara/deployments

# Copy WAR from build stage
COPY --from=build /app/dist/*.war $DEPLOY_DIR/

# Expose the port
EXPOSE 8080

# Start Payara Micro
CMD ["java", "-jar", "/opt/payara/payara-micro.jar", "--deploydir", "/opt/payara/deployments"]