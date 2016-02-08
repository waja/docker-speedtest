uilds a docker image with the [speedtest-cli](speedtest-cli) ready to run.

Pulled from https://github.com/tianon/dockerfiles/tree/master/speedtest

Ever wanted to speedtest a server, but didn't want to do funky tunnelling so you could hit up good ol' speedtest.net?  WORRY NO MORE.

Running
-------

- run the docker container with:

```
docker run --rm --net=host waja/speedtest -h
```

We don't actually _require_ `--net=host`, but if we're wanting to test native performance (or use `--source some-specific-host-IP`) then we want direct access to the relevant connections without any overhead.

Building
--------

```
make build
```

Get a shell in a running container
----------------------------------

```
make shell
```
