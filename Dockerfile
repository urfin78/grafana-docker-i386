FROM i386/golang:1.10-stretch as gobuild

WORKDIR /go/src/app
RUN go get github.com/grafana/grafana; exit 0
WORKDIR github.com/grafana/grafana
RUN go run build.go setup && go run build.go build

FROM i386/node:9-stretch as nodebuild

COPY --from=gobuild /go/src/app/src/github.com/grafana/grafana /tmp/grafana

WORKDIR /tmp/grafana
RUN npm install -g yarn && yarn install --pure-lockfile && npm run watch
