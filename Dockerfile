FROM i386/golang:1.10-stretch as gobuild

WORKDIR /go/src/app
RUN cd $WORKDIR && go get github.com/grafana/grafana; exit 0
RUN cd $WORKDIR/github.com/grafana/grafana && go run build.go setup && go run build.go build

FROM i386/node:9-stretch as nodebuild

COPY --from=gobuild /go/src/app/src/github.com/grafana/grafana /tmp/grafana

RUN cd /tmp/grafana && npm install -g yarn
RUN cd /tmp/grafana && yarn install --pure-lockfile
RUN cd /tmp/grafana && npm run watch
