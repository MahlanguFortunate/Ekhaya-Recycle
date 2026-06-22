FROM payara/micro:6.2024.6-jdk17

ENV DEPLOY_DIR=/opt/payara/deployments

COPY EhkayaRecycleWebApplication/dist/*.war $DEPLOY_DIR/

EXPOSE 8080

# ✅ Correct: Payara Micro auto-deploys WARs in the deployments folder
CMD ["payara-micro"]