FROM open-liberty as server-setup
COPY /target/mpservice.zip /config/
RUN apt-get update \
    && apt-get install -y --no-install-recommends unzip
RUN unzip /config/mpservice.zip && \
    mv /wlp/usr/servers/mpserviceServer/* /config/ && \
    rm -rf /config/wlp && \
    rm -rf /config/mpservice.zip

FROM open-liberty
LABEL maintainer="Graham Charters" vendor="IBM" github="https://github.com/WASdev/ci.maven"
COPY --from=server-setup /config/ /config/
EXPOSE 9080 9443
