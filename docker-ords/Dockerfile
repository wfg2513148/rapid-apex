# Original source from https://github.com/lucassampsouza/ords_apex
FROM openjdk:8-jre-alpine
LABEL maintainer="Kenny Wang <wfgdlut@gmail.com>"

ENV TZ="Asia/Shanghai" \
  APEX_CONFIG_DIR="/opt" \
  TOMCAT_HOME="/usr/local/tomcat" \
  APEX_PUBLIC_USER_NAME="APEX_PUBLIC_USER" \
  PLSQL_GATEWAY="true" \
  REST_SERVICES_APEX="true" \
  REST_SERVICES_ORDS="true" \
  MIGRATE_APEX_REST="true" \
  ORDS_DIR="/ords"

WORKDIR ${ORDS_DIR}

COPY ["files/ords-*.zip", "files/apache-tomcat*.zip", "scripts/*", "/tmp/"]

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories

RUN apk add --update curl

RUN echo "" && \
  unzip /tmp/ords-*.zip ords.war && \
  rm -rf /tmp/ords-*.zip && \
  chmod +x /tmp/docker-run.sh && \
  /tmp/docker-run.sh

ENTRYPOINT ["/ords/config-run-ords.sh"]

VOLUME ["/ords/apex-images", "/opt/ords"]

EXPOSE 8080

HEALTHCHECK --start-period=60s --interval=10s --retries=3 --timeout=300s CMD curl --fail http://localhost:8080/ords || exit 1

CMD ["run"]


