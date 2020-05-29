#!/bin/sh
set +e

#####################################################################################
#
# Build environment
#
####################################################################################
PYBIN=/usr/local/bin/python3
CV_VERSION=${1:-3.4.2}
echo 'PWD  : '$PWD
echo 'PYBIN: '$PYBIN
echo 'Target openCV version:' $CV_VERSION
echo 'Install build dependencies'
apk add --no-cache --virtual .build-deps \
  build-base \
  clang \
  clang-dev \
  cmake \
  git \
  wget \
  unzip

echo 'Install opencv dependencies'
apk add --no-cache \
  jasper-dev \
  libavc1394-dev  \
  libdc1394-dev \
  libjpeg-turbo-dev \
  libpng-dev \
  libtbb \
  libtbb-dev \
  libwebp-dev \
  linux-headers \
  openblas-dev \
  tiff-dev \
  python3-dev

echo 'Install ffmpeg dependencies'
apk add --no-cache \
   libva \
   v4l-utils-dev \
   ffmpeg-libs \
   ffmpeg-dev \
   ffmpeg \

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
wget https://github.com/opencv/opencv/archive/$CV_VERSION.zip
unzip $CV_VERSION.zip
mv opencv-$CV_VERSION opencv
rm $CV_VERSION.zip

#echo 'Download opencv contrib...'
wget https://github.com/opencv/opencv_contrib/archive/$CV_VERSION.zip
unzip $CV_VERSION.zip
mv opencv_contrib-$CV_VERSION opencv_contrib
rm $CV_VERSION.zip

#####################################################################################
#
# Build opencv 
#
####################################################################################
echo 'Begin build opencv...'
pip3 install numpy
ln -s $PYBIN /usr/bin/python

# Begin build
echo 'Begin build'
cd /opencv/opencv
mkdir build

echo 'Config for Py3'
cmake -H"." -B"build" -DCMAKE_BUILD_TYPE=Release -DBUILD_opencv_python2=OFF -DBUILD_opencv_java=OFF -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_TESTS=OFF -DBUILD_PERF_TESTS=OFF -DWITH_IPP=OFF \
  -DPYTHON3INTERP_FOUND=ON -DPYTHON3LIBS_FOUND=ON \
  -DPYTHON3_EXECUTABLE=$PYBIN \
  -DPYTHON3_VERSION_STRING=$($PYBIN -c "from platform import python_version; print(python_version())") \
  -DPYTHON3_INCLUDE_PATH=$($PYBIN -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
  -DPYTHON3_PACKAGES_PATH=$($PYBIN -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
  -DPYTHON3_NUMPY_INCLUDE_DIRS=$($PYBIN -c "import os; os.environ['DISTUTILS_USE_SDK']='1'; import numpy.distutils; print(os.pathsep.join(numpy.distutils.misc_util.get_numpy_include_dirs()))") \
  -DPYTHON3_NUMPY_VERSION=$($PYBIN -c "import numpy; print(numpy.version.version)") \
  -DOPENCV_EXTRA_MODULES_PATH="../opencv_contrib/modules"

echo 'Build for Py3'
(cd build; make -j5 opencv_python3)

# Moving back to opencv-python
cd ..

echo 'Copying *.so for Py3'
cp opencv/build/lib/python3/cv2.cpython-36m-x86_64-linux-gnu.so /usr/local/lib/python3.6/site-packages/cv2.so

# Cleanup
echo 'Cleanup'
rm -fr /opencv
cd
apk del --purge .build-deps
