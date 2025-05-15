# checkov:skip=CKV_DOCKER_2: no healthcheck (yet)
# checkov:skip=CKV_DOCKER_3: no user (yet)
FROM alpine:3.21.3@sha256:a8560b36e8b8210634f77d9f7f9efd7ffa463e380b75e2e74aff4511df3ef88c

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_URL
ARG VCS_REF
ARG VCS_BRANCH
ARG SPEEDTEST_CLI_PACKAGE_VERSION=2.1.3-r7

# See http://label-schema.org/rc1/ and https://microbadger.com/labels
LABEL maintainer="Jan Wagner <waja@cyconet.org>" \
    org.label-schema.name="speedtest-cli - command line interface for testing internet bandwidth using speedtest.net" \
    org.label-schema.description="Command line interface for testing internet bandwidth on Alpine Linux based container" \
    org.label-schema.vendor="Cyconet" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE:-unknown}" \
    org.label-schema.version="${BUILD_VERSION:-unknown}" \
    org.label-schema.vcs-url="${VCS_URL:-unknown}" \
    org.label-schema.vcs-ref="${VCS_REF:-unknown}" \
    org.label-schema.vcs-branch="${VCS_BRANCH:-unknown}" \
    org.opencontainers.image.source="https://github.com/waja/docker-speedtest"

# hadolint ignore=DL3017,DL3018
RUN --mount=type=cache,target=/var/log \
    --mount=type=cache,target=/var/cache \
    --mount=type=tmpfs,target=/tmp \
    <<EOF
    apk --no-cache update && apk --no-cache upgrade
    # Install needed packages
    apk add --update --no-cache \
        speedtest-cli=$SPEEDTEST_CLI_PACKAGE_VERSION
EOF

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["speedtest-cli"]
