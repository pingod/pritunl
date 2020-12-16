FROM alpine

MAINTAINER red <red.avtovo@gmail.com>

RUN apk add --no-cache go git --virtual .build-deps && \
	apk add --no-cache bash curl ca-certificates iptables ip6tables iproute2 openssl strongswan && \
	export GOPATH=/go && \
	go get github.com/pritunl/pritunl-link && \
	cp /go/bin/* /usr/bin/ && \
	rm -rf /go && \
	apk del .build-deps

ADD rootfs /
ENTRYPOINT ["/init"]
