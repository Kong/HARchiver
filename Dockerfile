FROM debian:wheezy
MAINTAINER SGrondin, simon@mashape.com

COPY harchiver.tar.gz /
RUN tar xzvf /harchiver.tar.gz
RUN cd /release
EXPOSE 15000 15001

CMD ["/release/harchiver", "15000"]
