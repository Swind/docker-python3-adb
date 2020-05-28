FROM alpine:3.7
ARG OPENCV_VER=3.4.1

# Set up insecure default key
RUN mkdir -m 0750 /root/.android
ADD files/insecure_shared_adbkey /root/.android/adbkey
ADD files/insecure_shared_adbkey.pub /root/.android/adbkey.pub
ADD files/update-platform-tools.sh /usr/local/bin/update-platform-tools.sh
ADD scripts/build-opencv.sh /root

RUN echo '> Add edge repository and update apk' && \
    echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories && \
    echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories && \
    apk update && \
    apk upgrade

# Install android platform tools 
RUN set -xeo pipefail && \
    apk update && \
    apk add wget ca-certificates tini && \
    wget -O "/etc/apk/keys/sgerrand.rsa.pub" \
      "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" && \
    wget -O "/tmp/glibc.apk" \
      "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-2.23-r3.apk" && \
    wget -O "/tmp/glibc-bin.apk" \
      "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3/glibc-bin-2.23-r3.apk" && \
    apk add "/tmp/glibc.apk" "/tmp/glibc-bin.apk" && \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    rm "/root/.wget-hsts" && \
    rm "/tmp/glibc.apk" "/tmp/glibc-bin.apk" && \
    rm -r /var/cache/apk/APKINDEX.* && \
    /usr/local/bin/update-platform-tools.sh

# Set up PATH
ENV PATH $PATH:/opt/platform-tools

# Install packages for cffi
RUN apk add --no-cache libffi-dev && \
    apk add --no-cache openssl-dev && \
    apk add --no-cache python3-dev && \
    apk add --no-cache musl-dev

# Install python3 with lxml
RUN apk add --no-cache python3 && \
    python3 -m ensurepip && \
    apk add --no-cache py3-lxml && \
    apk add --no-cache py3-paramiko && \
    apk add --no-cache py3-gevent && \
    apk add --no-cache py3-scipy && \
    apk add --no-cache py-numpy-dev && \
    apk add --no-cache linux-headers && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -r /root/.cache

RUN /root/build-opencv.sh ${OPENCV_VER}
RUN ln /dev/null /dev/raw1394

ONBUILD RUN mkdir -p /code
ONBUILD WORKDIR /code

# Hook up tini as the default init system for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

