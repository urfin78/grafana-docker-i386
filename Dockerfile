#build upon dockerfile from https://github.com/grafana/grafana-docker
#build grafana server go app
FROM i386/golang:1.10-stretch as gobuild

WORKDIR /go/src/app
RUN export GOPATH=/go/src/app && \
    go get github.com/grafana/grafana; exit 0
WORKDIR /go/src/app/src/github.com/grafana/grafana
RUN export GOPATH=/go/src/app && \
    go run build.go setup && \
    go run build.go build

# build grafana frontend nodejs
FROM i386/node:9-stretch as nodebuild

COPY --from=gobuild /go/src/app/src/github.com/grafana/grafana /node/grafana

WORKDIR /node/grafana
RUN yarn install --pure-lockfile
WORKDIR /node/grafana
RUN yarn run dev

#create grafana docker image
FROM i386/debian:stretch-slim

ARG GF_UID="472"
ARG GF_GID="472"

ENV PATH=/usr/share/grafana/bin/linux-386:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    GF_PATHS_CONFIG="/etc/grafana/grafana.ini" \
    GF_PATHS_DATA="/var/lib/grafana" \
    GF_PATHS_HOME="/usr/share/grafana" \
    GF_PATHS_LOGS="/var/log/grafana" \
    GF_PATHS_PLUGINS="/var/lib/grafana/plugins" \
    GF_PATHS_PROVISIONING="/etc/grafana/provisioning"

COPY --from=nodebuild /node/grafana/bin ${GF_PATHS_HOME}/bin
COPY --from=nodebuild /node/grafana/conf ${GF_PATHS_HOME}/conf
COPY --from=nodebuild /node/grafana/public ${GF_PATHS_HOME}/public
COPY --from=nodebuild /node/grafana/scripts ${GF_PATHS_HOME}/scripts
COPY --from=nodebuild /node/grafana/tools ${GF_PATHS_HOME}/tools
COPY --from=nodebuild /node/grafana/*.md ${GF_PATHS_HOME}/

RUN apt-get update && apt-get install -qq -y libfontconfig ca-certificates && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd -r -g $GF_GID grafana && \
    useradd -r -u $GF_UID -g grafana grafana && \
    mkdir -p "$GF_PATHS_PROVISIONING/datasources" \
             "$GF_PATHS_PROVISIONING/dashboards" \
             "$GF_PATHS_LOGS" \
             "$GF_PATHS_PLUGINS" \
             "$GF_PATHS_HOME/.aws" \
             "$GF_PATHS_DATA" && \
    cp "$GF_PATHS_HOME/conf/sample.ini" "$GF_PATHS_CONFIG" && \
    cp "$GF_PATHS_HOME/conf/ldap.toml" /etc/grafana/ldap.toml && \
    chown -R grafana:grafana "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS" && \
    chmod 777 "$GF_PATHS_DATA" "$GF_PATHS_HOME/.aws" "$GF_PATHS_LOGS" "$GF_PATHS_PLUGINS"

EXPOSE 3000

COPY ./run.sh /run.sh

USER grafana
WORKDIR /
ENTRYPOINT [ "/run.sh" ]
