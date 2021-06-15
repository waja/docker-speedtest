<!-- markdownlint-disable MD045 -->
# Docker-Speedtest

[![](https://images.microbadger.com/badges/version/waja/speedtest.svg)](https://hub.docker.com/r/waja/speedtest/)
[![](https://images.microbadger.com/badges/image/waja/speedtest.svg)](https://hub.docker.com/r/waja/speedtest/)
[![Build Status](https://travis-ci.org/Cyconet/docker-speedtest.svg?branch=development)](https://travis-ci.org/Cyconet/docker-speedtest)
[![Docker Build Status](https://img.shields.io/docker/build/waja/speedtest.svg)](https://hub.docker.com/r/waja/speedtest/)
[![GitHub tag](https://img.shields.io/github/tag/Cyconet/docker-speedtest.svg)](https://github.com/Cyconet/docker-speedtest/tags)
[![](https://img.shields.io/docker/pulls/waja/speedtest.svg)](https://hub.docker.com/r/waja/speedtest/)
[![](https://img.shields.io/docker/stars/waja/speedtest.svg)](https://hub.docker.com/r/waja/speedtest/)
[![](https://img.shields.io/docker/automated/waja/speedtest.svg)](https://hub.docker.com/r/waja/speedtest/)

Builds a docker image with the [speedtest-cli](https://github.com/sivel/speedtest-cli) ready to run.

Pulled from [https://github.com/tianon/dockerfiles/tree/master/speedtest](https://github.com/tianon/dockerfiles/tree/master/speedtest)

Ever wanted to speedtest a server, but didn't want to do funky tunnelling so you could hit up good ol' speedtest.net?  WORRY NO MORE.

# Running

- run the docker container with:

```bash
docker run --rm --net=host waja/speedtest -h
```

We don't actually _require_ `--net=host`, but if we're wanting to test native performance (or use `--source some-specific-host-IP`) then we want direct access to the relevant connections without any overhead.

# Building

```bash
make build
```

# Get a shell in a running container

```bash
make shell
```
