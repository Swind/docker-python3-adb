#!/bin/sh
set +e

#####################################################################################
#
# Build environment
#
####################################################################################

echo '> Add edge repository and update apk'
echo http://dl-cdn.alpinelinux.org/alpine/edge/testing >> /etc/apk/repositories
echo http://dl-cdn.alpinelinux.org/alpine/edge/community >> /etc/apk/repositories
apk update
# fix apk-tools is old
apk add--upgrade apk-tools@edge
apk upgrade

echo 'Install build dependencies'
apk add --no-cache --virtual .build-deps \
  build-base \
  clang \
  clang-dev \
  cmake \
  git \
  wget \
  unzip

apk add --update --no-cache \
  linux-headers \
  libstdc++ \
  jasper-dev \
  libavc1394-dev  \
  libdc1394-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libtbb \
  libtbb-dev \
  libwebp-dev \
  openblas-dev \
  tiff-dev \
  python3-dev
# fix for numpy compilation
ln -s /usr/include/locale.h /usr/include/xlocale.h

#####################################################################################
#
# Download opencv source code 
#
####################################################################################

#echo 'Download opencv ...'
mkdir -p /opencv
cd /opencv
wget https://github.com/opencv/opencv/archive/3.2.0.zip
unzip 3.2.0.zip
mv opencv-3.2.0 opencv
rm 3.2.0.zip

#echo 'Download opencv contrib...'
wget https://github.com/opencv/opencv_contrib/archive/3.2.0.zip
unzip 3.2.0.zip
mv opencv_contrib-3.2.0 opencv_contrib
rm 3.2.0.zip

#####################################################################################
#
# Build opencv 
#
####################################################################################
echo 'Begin build opencv...'
pip3 install numpy==1.12.0 
ln -s /usr/bin/python3 /usr/bin/python

# Begin build
echo 'Begin build'
cd /opencv/opencv
mkdir build

echo 'Config for Py3'
cmake -H"." -B"build" -DCMAKE_BUILD_TYPE=Release -DBUILD_opencv_python2=OFF -DBUILD_opencv_java=OFF -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DWITH_IPP=OFF \
  -DPYTHON3INTERP_FOUND=ON -DPYTHON3LIBS_FOUND=ON \
  -DPYTHON3_EXECUTABLE=$PYBIN \
  -DPYTHON3_VERSION_STRING=$($PYBIN -c "from platform import python_version; print python_version()") \
  -DPYTHON3_INCLUDE_PATH=$($PYBIN -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
  -DPYTHON3_PACKAGES_PATH=$($PYBIN -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
  -DPYTHON3_NUMPY_INCLUDE_DIRS=$($PYBIN -c "import os; os.environ['DISTUTILS_USE_SDK']='1'; import numpy.distutils; print(os.pathsep.join(numpy.distutils.misc_util.get_numpy_include_dirs()))") \
  -DPYTHON3_NUMPY_VERSION=$($PYBIN -c "import numpy; print(numpy.version.version)") \
  -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"

echo 'Build for Py3'
(cd build; make -j5 opencv_python3)

# Moving back to opencv-python
cd ..

#echo 'Copying *.so for Py3'
cp opencv/build/lib/python3/cv2.cpython-35m-x86_64-linux-gnu.so /usr/lib/python3.5/site-packages/cv2.so

# Cleanup
#echo 'Cleanup'
rm -fr /opencv
cd
apk del --purge .build-deps
