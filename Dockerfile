FROM i386/golang:1.10-stretch as gobuild

WORKDIR /go/src/app
RUN export GOPATH=/go/src/app && \
    go get github.com/grafana/grafana; exit 0
WORKDIR /go/src/app/github.com/grafana/grafana
RUN export GOPATH=/go/src/app && \
    go run build.go setup && \
    go run build.go build

FROM i386/node:9-stretch as nodebuild

COPY --from=gobuild /go/src/app/src/github.com/grafana/grafana /node/grafana

WORKDIR /node/grafana
RUN npm install -g yarn && yarn install --pure-lockfile && npm run watch
