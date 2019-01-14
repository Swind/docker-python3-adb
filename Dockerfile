FROM node:8.15-alpine as node
FROM alpine:3.5

# This is the commit message #5:
#===============
# Set JAVA_HOME
#===============

ARG  JAVA_HOME="/usr/lib/jvm/java-1.8-openjdk"
ENV  PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin \
     JAVA_HOME=$JAVA_HOME


# Set up insecure default key
RUN mkdir -m 0750 /root/.android
ADD files/insecure_shared_adbkey /root/.android/adbkey
ADD files/insecure_shared_adbkey.pub /root/.android/adbkey.pub
ADD files/update-platform-tools.sh /usr/local/bin/update-platform-tools.sh

RUN set -xeo pipefail && \
    apk update && \
    apk add wget ca-certificates tini && \
    wget -O "/etc/apk/keys/sgerrand.rsa.pub" \
      "https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub" && \
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

# create fake build-tools folder and aapt to pass appium path examination
RUN mkdir -p /opt/build-tools && touch /opt/aapt

# Set up PATH
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH "$PATH:${NPM_CONFIG_PREFIX}:${NPM_CONFIG_PREFIX}/bin:/opt/platform-tools:/opt/build-tools"
ENV ANDROID_HOME '/opt/'
RUN echo $PATH

#====================================
# Set node directory
# Install appium
# need install python2 for appium installation
#====================================
COPY --from=node /usr/local/ /usr/local/
WORKDIR /
ARG APPIUM_VERSION=1.10.0
ENV APPIUM_VERSION=$APPIUM_VERSION
RUN apk update && \
    apk add --no-cache openjdk8 && \
    apk add --no-cache python python3 gcc g++ make && \
    npm install -g appium@${APPIUM_VERSION} --unsafe-perm=true --allow-root --no-cache
 
RUN apk del python

# Set python path
ENV PYBIN=/usr/bin/python3
ENV PYTHON ${PYBIN}
RUN echo 'PYBIN: $PYBIN '

# Install packages for cffi
RUN apk add --no-cache libffi-dev && \
    apk add --no-cache openssl-dev && \
    apk add --no-cache jpeg-dev && \
    apk add --no-cache musl-dev

# Install python3 with lxml
RUN python3 -m ensurepip && \
    apk add --no-cache py3-lxml && \
    apk add --no-cache py3-paramiko && \
    apk add --no-cache py3-gevent && \
    rm -r /usr/lib/python*/ensurepip && \
    pip3 install --upgrade pip setuptools && \
    rm -r /root/.cache

# Install ffmpeg
RUN apk add --no-cache --update \
   ffmpeg-libs \
   ffmpeg
#====================================
# Install opencv
#====================================
ADD scripts/build-opencv.sh /root
RUN /root/build-opencv.sh
RUN ln /dev/null /dev/raw1394

ONBUILD RUN mkdir -p /code
ONBUILD WORKDIR /code

ONBUILD COPY requirements.txt /code
ONBUILD RUN pip3 install --no-cache-dir -r requirements.txt

# Hook up tini as the default init system for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]
