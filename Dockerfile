FROM gliderlabs/alpine:3.3                                                      
                                                                                
# Dockerfile Maintainer                                                         
MAINTAINER Jan Wagner "waja@cyconet.org"                                        

ENV SPEEDTEST_CLI_VERSION 0.3.4
                                                                                
RUN apk --update add python py-pip && \
 apk --update add --virtual build-dependencies python-dev build-base wget && \
 pip install speedtest-cli==$SPEEDTEST_CLI_VERSION && \
 apk del build-dependencies

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["speedtest-cli"]
