FROM payara/micro:6.2024.6-jdk17

USER root

ENV DEPLOY_DIR=/opt/payara/deployments

COPY EhkayaRecycleWebApplication/dist/EhkayaRecycleWebApplication.war $DEPLOY_DIR/EhkayaRecycleWebApplication.war

RUN ls -la $DEPLOY_DIR

USER payara

EXPOSE 8080