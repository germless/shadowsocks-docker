FROM --platform=$BUILDPLATFORM golang:alpine as builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH
ARG DRONE_TAG
ENV CGO_ENABLED 0
ENV GOOS $TARGETOS
ENV GOARCH $TARGETARCH
RUN echo "I am running on $BUILDPLATFORM, building for $TARGETPLATFORM, GOOS $GOOS, GOARCH $GOARCH"
RUN apk update && apk add --no-cache git build-base make
ENV VERSION $DRONE_TAG
RUN git clone --branch ${VERSION} https://github.com/shadowsocks/go-shadowsocks2.git
WORKDIR /go/go-shadowsocks2

RUN go build -trimpath -ldflags "-s -w" -o bin/go-shadowsocks2 .

# Build v2ray-plugin from source
WORKDIR /go
RUN git clone https://github.com/shadowsocks/v2ray-plugin.git
WORKDIR /go/v2ray-plugin
RUN go build -trimpath -ldflags "-s -w" -o v2ray-plugin

FROM --platform=$TARGETPLATFORM alpine:latest
RUN apk update && apk add --no-cache ca-certificates tzdata iproute2
COPY --from=builder /go/go-shadowsocks2/bin/go-shadowsocks2 /bin/
COPY --from=builder /go/v2ray-plugin/v2ray-plugin /bin/
ENV TZ=Asia/Shanghai
RUN uname -a
ENTRYPOINT ["/bin/go-shadowsocks2"]
