FROM alpine:3.5

#====================================
# Install nodejs, npm, appium
#====================================
ARG APPIUM_VERSION=1.6.5
ENV APPIUM_VERSION=$APPIUM_VERSIONS

RUN apk update && \
    apk add --no-cache nodejs && \
    npm install -g appium@${APPIUM_VERSION} && \
    apk add --no-cache openjdk8-jre

#===============
# Set JAVA_HOME
#===============

ENV JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk/jre/" \
    PATH=$PATH:$JAVA_HOME/bin


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
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -r /root/.cache

#====================================
# Install opencv
#====================================
ADD scripts/build-opencv.sh /root
RUN /root/build-opencv.sh
RUN ln /dev/null /dev/raw1394

ONBUILD RUN mkdir -p /code
ONBUILD WORKDIR /code

ONBUILD COPY requirements.txt /code
ONBUILD RUN pip install --no-cache-dir -r requirements.txt

# Hook up tini as the default init system for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]
