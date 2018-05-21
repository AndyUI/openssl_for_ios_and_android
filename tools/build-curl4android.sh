#!/bin/bash
#
# Copyright 2016 leenjewel
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -u

source ./_shared.sh cURL

# Setup architectures, library name and other vars + cleanup from previous runs
TOOLS_ROOT=`pwd`
LIB_NAME="curl-7.57.0"
LIB_DEST_DIR=${TOOLS_ROOT}/libs
[ -f ${LIB_NAME}.tar.gz ] || wget https://curl.haxx.se/download/${LIB_NAME}.tar.gz
# Unarchive library, then configure and make for specified architectures
if [ ! -d "${LIB_NAME}" ];then
  tar xfz "${LIB_NAME}.tar.gz"
fi
configure_make() {
  ARCH=$1; ABI=$2;
  #[ -d "${LIB_NAME}" ] && rm -rf "${LIB_NAME}"
  #tar xfz "${LIB_NAME}.tar.gz"
  pushd "${LIB_NAME}";

  configure $*

  export CPPFLAGS="${CPPFLAGS} -I${TOOLS_ROOT}/../output/android/openssl-${ABI}/include/"
  export LDFLAGS="${LDFLAGS} -L${TOOLS_ROOT}/../output/android/openssl-${ABI}/lib/"
  export CFLAGS="${CFLAGS} -UHAVE_GETPWUID_R"
  # fix me
  #cp ${TOOLS_ROOT}/../output/android/openssl-${ABI}/lib/libssl.a ${SYSROOT}/usr/lib
  #cp ${TOOLS_ROOT}/../output/android/openssl-${ABI}/lib/libcrypto.a ${SYSROOT}/usr/lib
  #cp -r ${TOOLS_ROOT}/../output/android/openssl-${ABI}/include/openssl ${SYSROOT}/usr/include

  mkdir -p ${LIB_DEST_DIR}/${ABI}
 # ./configure --prefix=${LIB_DEST_DIR}/${ABI} \
 #             --with-sysroot=${SYSROOT} \
 #             --host=${TOOL} \
 #             #--with-ssl \
 #             --enable-ipv6 \
 #             --enable-static \
 #             --enable-threaded-resolver \
 #             --disable-dict \
 #             --disable-gopher \
 #             --disable-ldap --disable-ldaps \
 #             --disable-manual \
 #             --disable-pop3 --disable-smtp --disable-imap \
 #             --disable-rtsp \
 #             --disable-shared \
 #             --disable-smb \
 #             --disable-telnet \
 #             --disable-verbose
#
  if [ -f lib/curl_config.h ];then
    #getpwuid_r not defined,so undef HAVE_GETPWUID_R
    GETPWUID_R=`grep 'HAVE_GETPWUID_R' lib/curl_config.h`
    sed -i "s/${GETPWUID_R}/#undef HAVE_GETPWUID_R/g" lib/curl_config.h
    grep 'HAVE_GETPWUID_R' lib/curl_config.h
  fi
     
  PATH=$TOOLCHAIN_PATH:$PATH
  make clean
  if make -j4
  then
    make install

    OUTPUT_ROOT=${TOOLS_ROOT}/../output/android/curl-${ABI}
    [ -d ${OUTPUT_ROOT}/include ] || mkdir -p ${OUTPUT_ROOT}/include
    cp -r ${LIB_DEST_DIR}/${ABI}/include/curl ${OUTPUT_ROOT}/include

    [ -d ${OUTPUT_ROOT}/lib ] || mkdir -p ${OUTPUT_ROOT}/lib
    cp ${LIB_DEST_DIR}/${ABI}/lib/libcurl.a ${OUTPUT_ROOT}/lib
  fi;
  popd;
}

for ((i=0; i < ${#ARCHS[@]}; i++))
do
  if [[ $# -eq 0 ]] || [[ "$1" == "${ARCHS[i]}" ]]; then
    [[ ${ANDROID_API} < 16 ]] && ( echo "${ABIS[i]}" | grep 64 > /dev/null ) && continue;
    configure_make "${ARCHS[i]}" "${ABIS[i]}"
  fi
done
