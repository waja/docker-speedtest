FROM alpine:3.7

# Dockerfile Maintainer
MAINTAINER Jan Wagner "waja@cyconet.org"

ENV SPEEDTEST_CLI_VERSION 2.0.0

RUN apk --no-cache add python py-pip && \
 apk --no-cache add --virtual build-dependencies python-dev build-base wget && \
 pip install speedtest-cli==$SPEEDTEST_CLI_VERSION && \
 apk del build-dependencies

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["speedtest-cli"]
