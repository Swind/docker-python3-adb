FROM alpine:3.6

# Set up insecure default key
RUN mkdir -m 0750 /root/.android
ADD files/insecure_shared_adbkey /root/.android/adbkey
ADD files/insecure_shared_adbkey.pub /root/.android/adbkey.pub
ADD files/update-platform-tools.sh /usr/local/bin/update-platform-tools.sh

RUN set -xeo pipefail && \
    apk update && \
    apk add wget ca-certificates tini && \
    wget -O "/etc/apk/keys/sgerrand.rsa.pub" \
      "https://raw.githubusercontent.com/andyshinn/alpine-pkg-glibc/master/sgerrand.rsa.pub" && \
    wget -O "/tmp/glibc.apk" \
      "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-2.25-r0.apk" && \
    wget -O "/tmp/glibc-bin.apk" \
      "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.25-r0/glibc-bin-2.25-r0.apk" && \
    apk add "/tmp/glibc.apk" "/tmp/glibc-bin.apk" && \
    rm "/etc/apk/keys/sgerrand.rsa.pub" && \
    rm "/root/.wget-hsts" && \
    rm "/tmp/glibc.apk" "/tmp/glibc-bin.apk" && \
    rm -r /var/cache/apk/APKINDEX.* && \
    /usr/local/bin/update-platform-tools.sh

# Set up PATH
ENV PATH $PATH:/opt/platform-tools

# Install python3 with lxml
RUN apk add --no-cache python3 && \
    apk add --no-cache py3-lxml && \
    apk add --no-cache py3-paramiko && \
    apk add --no-cache py3-pillow && \
    apk add --no-cache py3-gevent && \
    apk add --no-cache py3-numpy && \
    python3 -m ensurepip && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -r /root/.cache

RUN apk add --no-cache py3-lxml 

ONBUILD RUN mkdir -p /code
ONBUILD WORKDIR /code

ONBUILD COPY requirements.txt /code
ONBUILD RUN pip3 install --no-cache-dir -r requirements.txt

# Hook up tini as the default init system for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

