FROM alpine:3.12

# Dockerfile Maintainer
MAINTAINER Jan Wagner "waja@cyconet.org"

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_URL
ARG VCS_REF
ARG VCS_BRANCH

# See http://label-schema.org/rc1/ and https://microbadger.com/labels
LABEL org.label-schema.name="speedtest-cli - command line interface for testing internet bandwidth using speedtest.net" \
    org.label-schema.description="Command line interface for testing internet bandwidth on Alpine Linux based container" \
    org.label-schema.vendor="Cyconet" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE:-unknown}" \
    org.label-schema.version="${BUILD_VERSION:-unknown}" \
    org.label-schema.vcs-url="${VCS_URL:-unknown}" \
    org.label-schema.vcs-ref="${VCS_REF:-unknown}" \
    org.label-schema.vcs-branch="${VCS_BRANCH:-unknown}"

ENV SPEEDTEST_CLI_VERSION 2.1.2

RUN apk --no-cache update && apk --no-cache upgrade && \
 apk --no-cache add python py-pip && \
 apk --no-cache add --virtual build-dependencies python-dev build-base wget && \
 pip install speedtest-cli==$SPEEDTEST_CLI_VERSION && \
 apk del build-dependencies

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["speedtest-cli"]
