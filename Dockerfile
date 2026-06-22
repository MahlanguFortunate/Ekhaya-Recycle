FROM payara/micro:6.2024.6-jdk17

ENV DEPLOY_DIR=/opt/payara/deployments

COPY EhkayaRecycleWebApplication/dist/*.war $DEPLOY_DIR/

EXPOSE 8080

# ✅ Correct: This is the proper way to start Payara Micro with your WAR
CMD ["java", "-jar", "/opt/payara/payara-micro.jar", "--deploydir", "/opt/payara/deployments"]