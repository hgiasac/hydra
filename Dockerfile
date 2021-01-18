FROM golang:1.14-alpine AS builder

RUN apk -U --no-cache add build-base git gcc bash ca-certificates

# set up nsswitch.conf for Go's "netgo" implementation
# - https://github.com/golang/go/blob/go1.9.1/src/net/conf.go#L194-L275
RUN echo 'hosts: files dns' > /etc/nsswitch.conf

WORKDIR /go/src/github.com/ory/hydra

ADD go.mod go.mod
ADD go.sum go.sum

ENV GO111MODULE on
ENV CGO_ENABLED 1

RUN go mod download

ADD . .

RUN go install github.com/go-bindata/go-bindata/go-bindata github.com/gobuffalo/packr/v2/packr2
RUN make sqlbin && packr2
RUN GO111MODULE=on GOOS=linux GOARCH=amd64 go build -o /usr/bin/hydra

# To compile this image manually run:
#
# $ GO111MODULE=on GOOS=linux GOARCH=amd64 go build && docker build -t oryd/hydra:v1.0.0-rc.7_oryOS.10 . && rm hydra
FROM alpine:3.11

RUN addgroup -S ory; \
    adduser -S ory -G ory -D -H -s /bin/nologin
RUN apk add -U --no-cache ca-certificates

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /etc/nsswitch.conf /etc/nsswitch.conf
# COPY hydra /usr/bin/hydra

COPY --from=builder /usr/bin/hydra /usr/bin/hydra

USER ory

ENTRYPOINT ["hydra"]
CMD ["serve", "all"]
