FROM payara/micro:6.2024.6-jdk17

# The default DEPLOY_DIR is already set, but we'll be explicit
ENV DEPLOY_DIR=/opt/payara/deployments

# Copy your WAR file
COPY EhkayaRecycleWebApplication/dist/*.war $DEPLOY_DIR/

# Expose the port
EXPOSE 8080

# 🔑 KEY FIX: Do NOT specify CMD - let the image use its default
# The Payara Micro image auto-deploys everything in DEPLOY_DIR