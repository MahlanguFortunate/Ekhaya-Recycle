FROM payara/micro:6.2024.6-jdk17

USER root

ENV DEPLOY_DIR=/opt/payara/deployments

ARG CACHEBUST=3

COPY EhkayaRecycleWebApplication/dist/EhkayaRecycleWebApplication.war $DEPLOY_DIR/EhkayaRecycleWebApplication.war

USER payara

EXPOSE 8080

CMD ["--deploy", "/opt/payara/deployments/EhkayaRecycleWebApplication.war", "--port", "8080", "--noCluster"]