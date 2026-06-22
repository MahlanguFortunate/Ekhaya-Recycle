FROM payara/micro:6.2024.6-jdk17

USER root

ENV DEPLOY_DIR=/opt/payara/deployments

ARG CACHEBUST=4

COPY EhkayaRecycleWebApplication/dist/EhkayaRecycleWebApplication.war $DEPLOY_DIR/ROOT.war

USER payara

EXPOSE 8080

CMD ["--deploy", "/opt/payara/deployments/ROOT.war", "--port", "8080", "--noCluster", "--contextroot", "/"]