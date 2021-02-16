#!/bin/bash

set -ex
SOURCE_PATH="$(cd "$(dirname "$0")/../../.." && pwd)"
UTILS_PATH="$(cd "$(dirname "$0")" && pwd)"

BUILD_SDK_PATH="$SOURCE_PATH/build-sdk"
LIBXML2_PATH="$BUILD_SDK_PATH/libxml2"

case $(uname -s) in
  Darwin)
    OS_SUFFIX=macos_$(uname -m)
    HOST_PRESET=webassembly-host-install
    HOST_SUFFIX=macosx-$(uname -m)
  ;;
  Linux)
    if [ "$(grep RELEASE /etc/lsb-release)" == "DISTRIB_RELEASE=18.04" ]; then
      OS_SUFFIX=ubuntu18.04_$(uname -m)
    elif [ "$(grep RELEASE /etc/lsb-release)" == "DISTRIB_RELEASE=20.04" ]; then
      OS_SUFFIX=ubuntu20.04_$(uname -m)
    elif [[ "$(grep PRETTY_NAME /etc/os-release)" == 'PRETTY_NAME="Amazon Linux 2"' ]]; then
      OS_SUFFIX=amazonlinux2_$(uname -m)
    else
      echo "Unknown Ubuntu version"
      exit 1
    fi
    HOST_PRESET=webassembly-linux-host-install
    HOST_SUFFIX=linux-$(uname -m)
  ;;
  *)
    echo "Unrecognised platform $(uname -s)"
    exit 1
  ;;
esac

BUILD_HOST_TOOLCHAIN=1

while [ $# -ne 0 ]; do
  case "$1" in
    --skip-build-host-toolchain)
    BUILD_HOST_TOOLCHAIN=0
  ;;
  *)
    echo "Unrecognised argument \"$1\""
    exit 1
  ;;
  esac
  shift
done

YEAR=$(date +"%Y")
MONTH=$(date +"%m")
DAY=$(date +"%d")
TOOLCHAIN_NAME="swift-wasm-DEVELOPMENT-SNAPSHOT-${YEAR}-${MONTH}-${DAY}-a"

PACKAGE_ARTIFACT="$SOURCE_PATH/swift-wasm-DEVELOPMENT-SNAPSHOT-${OS_SUFFIX}.tar.gz"

HOST_TOOLCHAIN_DESTDIR=$SOURCE_PATH/host-toolchain-sdk
DIST_TOOLCHAIN_DESTDIR=$SOURCE_PATH/dist-toolchain-sdk
DIST_TOOLCHAIN_SDK=$DIST_TOOLCHAIN_DESTDIR/$TOOLCHAIN_NAME


HOST_BUILD_ROOT=$SOURCE_PATH/host-build
TARGET_BUILD_ROOT=$SOURCE_PATH/target-build
HOST_BUILD_DIR=$HOST_BUILD_ROOT/Ninja-Release

DIST_WASI_SDK="$TARGET_BUILD_ROOT/WASI.sdk"

build_host_toolchain() {
  # Build the host toolchain and SDK first.
  env SWIFT_BUILD_ROOT="$HOST_BUILD_ROOT" \
    "$SOURCE_PATH/swift/utils/build-script" \
    --preset-file="$UTILS_PATH/build-presets.ini" \
    --preset=$HOST_PRESET \
    --build-dir="$HOST_BUILD_DIR" \
    HOST_ARCHITECTURE="$(uname -m)" \
    INSTALL_DESTDIR="$HOST_TOOLCHAIN_DESTDIR" \
    TOOLCHAIN_NAME="$TOOLCHAIN_NAME"
}

COMMON_BUILD_ARGS="
 -D CMAKE_BUILD_TYPE=Release \
 -D CMAKE_C_COMPILER_LAUNCHER=$(which sccache) \
 -D CMAKE_CXX_COMPILER_LAUNCHER=$(which sccache)"

build_toolchain() {
  COMPILER_RT_BUILD_DIR="$TARGET_BUILD_ROOT/compiler-rt-unknown-wasm32"
  cmake -B "$COMPILER_RT_BUILD_DIR" \
    -C "$SOURCE_PATH/swift/utils/webassembly/cmake/cache/compiler-rt-unknown-wasm32.cmake" \
    -D CMAKE_TOOLCHAIN_FILE="$SOURCE_PATH/swift/utils/webassembly/cmake/toolchains/wasi.toolchain.cmake" \
    -D LLVM_BIN="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin" \
    -D CMAKE_INSTALL_PREFIX="$DIST_TOOLCHAIN_SDK/usr/lib/clang/10.0.0/" \
    -D CMAKE_SYSROOT="$BUILD_SDK_PATH/wasi-libc" \
    "$COMMON_BUILD_ARGS" \
    -G Ninja \
    -S "$SOURCE_PATH/llvm-project/compiler-rt"
  ninja install -C "$COMPILER_RT_BUILD_DIR"

  # Link compiler-rt libs in swift_static resource dir
  # These compiler builtin headers need to be in toolchain (not in sdk)
  # But host platform (like Darwin) doesn't always support static stdlib,
  # so we need to create it manually.
  ln -fs ../clang/10.0.0/ $DIST_TOOLCHAIN_SDK/usr/lib/swift_static/clang
}

build_wasi_sdk() {
  # Create a WASI.sdk directory
  rm -rf "$DIST_WASI_SDK"
  mkdir -p "$DIST_WASI_SDK"
  # Create symlinks to be able to pass both WASI.sdk and WASI.sdk/usr as sysroot
  (cd "$DIST_WASI_SDK" && \
    ln -s usr/include include && \
    ln -s usr/lib lib)

  # Install wasi-libc with extra headers
  cp -r "$BUILD_SDK_PATH/wasi-libc" "$DIST_WASI_SDK/usr"
  cp "$(find $SOURCE_PATH/swift/utils/webassembly/libc-support/include/ -type f)" $DIST_WASI_SDK/usr/include/

  # Build and install libcxx
  LIBCXX_BUILD_DIR="$TARGET_BUILD_ROOT/libcxx-wasi-wasm32"
  cmake -B "$LIBCXX_BUILD_DIR" \
    -D CMAKE_TOOLCHAIN_FILE="$SOURCE_PATH/swift/utils/webassembly/cmake/toolchains/wasi.toolchain.cmake" \
    -C "$SOURCE_PATH/swift/utils/webassembly/cmake/cache/libcxx-unknown-wasm32.cmake" \
    -D CMAKE_STAGING_PREFIX="$DIST_WASI_SDK/usr" \
    -D CMAKE_BUILD_TYPE=Release \
    -D LIBCXX_CXX_ABI_INCLUDE_PATHS="$SOURCE_PATH/llvm-project/libcxxabi/include" \
    -D CMAKE_SYSROOT="$DIST_WASI_SDK/usr" \
    -D LLVM_BIN="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin" \
    -D LIBCXX_LIBDIR_SUFFIX=/wasm32-wasi \
    "$COMMON_BUILD_ARGS" \
    -G Ninja \
    -S "$SOURCE_PATH/llvm-project/libcxx"
  ninja install -C "$LIBCXX_BUILD_DIR"

  # Build and install libcxxabi
  LIBCXXABI_BUILD_DIR="$TARGET_BUILD_ROOT/libcxxabi-wasi-wasm32"
  cmake -B "$LIBCXXABI_BUILD_DIR" \
    -C "$SOURCE_PATH/swift/utils/webassembly/cmake/cache/libcxxabi-unknown-wasm32.cmake" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_STAGING_PREFIX="$DIST_WASI_SDK/usr" \
    -D CMAKE_SYSROOT="$DIST_WASI_SDK/usr" \
    -D CMAKE_TOOLCHAIN_FILE="$SOURCE_PATH/swift/utils/webassembly/cmake/toolchains/wasi.toolchain.cmake" \
    -D LIBCXXABI_LIBCXX_INCLUDES="$DIST_WASI_SDK/usr/include/c++/v1" \
    -D LIBCXXABI_LIBCXX_PATH="$SOURCE_PATH/llvm-project/libcxx" \
    -D LIBCXXABI_LIBDIR_SUFFIX=/wasm32-wasi \
    -D LLVM_BIN="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin" \
    "$COMMON_BUILD_ARGS" \
    -G Ninja \
    -S "$SOURCE_PATH/llvm-project/libcxxabi"
   ninja install -C "$LIBCXXABI_BUILD_DIR"

  # Build and install Swift standard library
  # Note: Swift stdlib build system is not seprated for host and target well,
  # so don't use CMAKE_TOOLCHAIN_FILE.
  SWIFT_STDLIB_BUILD_DIR="$TARGET_BUILD_ROOT/swift-stdlib-wasi-wasm32"
  cmake -B "$SWIFT_STDLIB_BUILD_DIR" \
    -C "$SOURCE_PATH/swift/cmake/caches/Runtime-WASI-wasm32.cmake" \
    -D CMAKE_AR="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin/llvm-ar" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_CXX_COMPILER="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin/clang++" \
    -D CMAKE_CXX_COMPILER_LAUNCHER="$(which sccache)" \
    -D CMAKE_C_COMPILER="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin/clang" \
    -D CMAKE_C_COMPILER_LAUNCHER="$(which sccache)" \
    -D CMAKE_STAGING_PREFIX="$DIST_WASI_SDK/usr" \
    -D CMAKE_RANLIB="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin/llvm-ranlib" \
    -D LLVM_DIR="$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/lib/cmake/llvm/" \
    -D SWIFT_NATIVE_SWIFT_TOOLS_PATH="$HOST_BUILD_DIR/swift-$HOST_SUFFIX/bin" \
    -D SWIFT_WASI_SYSROOT_PATH="$DIST_WASI_SDK" \
    -D SWIFT_WASI_wasm32_ICU_DATA="$BUILD_SDK_PATH/icu/lib/libicudata.a" \
    -D SWIFT_WASI_wasm32_ICU_I18N="$BUILD_SDK_PATH/icu/lib/libicui18n.a" \
    -D SWIFT_WASI_wasm32_ICU_I18N_INCLUDE="$BUILD_SDK_PATH/icu/include" \
    -D SWIFT_WASI_wasm32_ICU_UC="$BUILD_SDK_PATH/icu/lib/libicuuc.a" \
    -D SWIFT_WASI_wasm32_ICU_UC_INCLUDE="$BUILD_SDK_PATH/icu/include" \
    "$COMMON_BUILD_ARGS" \
    -G Ninja \
    -S "$SOURCE_PATH/swift"
  ninja install -C "$SWIFT_STDLIB_BUILD_DIR"

  # Replace absolute sysroot path with relative path
  sed -i.bak -e "s@\".*/include@\"../../../../include@g" "$DIST_WASI_SDK/usr/lib/swift/wasi/wasm32/wasi.modulemap"
  rm "$DIST_WASI_SDK/usr/lib/swift/wasi/wasm32/wasi.modulemap.bak"
  sed -i.bak -e "s@\".*/include@\"../../../../include@g" "$DIST_WASI_SDK/usr/lib/swift_static/wasi/wasm32/wasi.modulemap"
  rm "$DIST_WASI_SDK/usr/lib/swift_static/wasi/wasm32/wasi.modulemap.bak"

  # Copy tool binaries in target build dir to test stdlib
  rsync -a "$HOST_BUILD_DIR/llvm-$HOST_SUFFIX/bin/" "$SWIFT_STDLIB_BUILD_DIR/bin/"
  rsync -a "$HOST_BUILD_DIR/swift-$HOST_SUFFIX/bin/" "$SWIFT_STDLIB_BUILD_DIR/bin/"

  # Link compiler-rt libs to stdlib build dir for testing
  mkdir -p "$SWIFT_STDLIB_BUILD_DIR/lib/clang/10.0.0/"
  ln -fs "$COMPILER_RT_BUILD_DIR/lib" "$SWIFT_STDLIB_BUILD_DIR/lib/clang/10.0.0/lib"

  # Build and install Foundation
  FOUNDATION_BUILD_DIR="$SOURCE_PATH/target-build/foundation-wasi-wasm32"
  cmake -B "$FOUNDATION_BUILD_DIR" \
    -C "$SOURCE_PATH/swift/utils/webassembly/cmake/cache/foundation-wasi-wasm32.cmake" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_STAGING_PREFIX="$DIST_WASI_SDK/usr" \
    -D CMAKE_SYSROOT="$DIST_WASI_SDK/usr" \
    -D CMAKE_TOOLCHAIN_FILE="$SOURCE_PATH/swift/utils/webassembly/cmake/toolchains/wasi.toolchain.cmake" \
    -D ICU_ROOT="$BUILD_SDK_PATH/icu" \
    -D LIBXML2_INCLUDE_DIR="$LIBXML2_PATH/include/libxml2" \
    -D LIBXML2_LIBRARY="$LIBXML2_PATH/lib" \
    -D LLVM_BIN="$DIST_TOOLCHAIN_SDK/usr/bin" \
    -D SWIFT_BIN="$DIST_TOOLCHAIN_SDK/usr/bin" \
    -D CMAKE_Swift_FLAGS="-sdk $DIST_WASI_SDK" \
    "$COMMON_BUILD_ARGS" \
    -G Ninja \
    "$SOURCE_PATH/swift-corelibs-foundation"
  ninja install -C "$FOUNDATION_BUILD_DIR"

  # Build and install XCTest
  XCTEST_BUILD_DIR="$SOURCE_PATH/target-build/xctest-wasi-wasm32"
  cmake -B "$XCTEST_BUILD_DIR" \
    -C "$SOURCE_PATH/swift/utils/webassembly/cmake/cache/xctest-wasi-wasm32.cmake" \
    -D CMAKE_BUILD_TYPE=Release \
    -D CMAKE_STAGING_PREFIX="$DIST_WASI_SDK/usr" \
    -D CMAKE_SYSROOT="$DIST_WASI_SDK/usr" \
    -D CMAKE_TOOLCHAIN_FILE="$SOURCE_PATH/swift/utils/webassembly/cmake/toolchains/wasi.toolchain.cmake" \
    -D LLVM_BIN="$DIST_TOOLCHAIN_SDK/usr/bin" \
    -D SWIFT_BIN="$DIST_TOOLCHAIN_SDK/usr/bin" \
    -D SWIFT_FOUNDATION_PATH="$DIST_WASI_SDK/usr/lib/swift_static/wasi/wasm32" \
    -D CMAKE_Swift_FLAGS="-sdk $DIST_WASI_SDK" \
    "$COMMON_BUILD_ARGS" \
    -G Ninja \
    "${SOURCE_PATH}/swift-corelibs-xctest"
  ninja install -C "$XCTEST_BUILD_DIR"
}

embed_sdks() {
  TOOLCHAIN_SDKS_PATH="$DIST_TOOLCHAIN_SDK/SDKs"
  rm -rf "$TOOLCHAIN_SDKS_PATH"
  mkdir -p "$TOOLCHAIN_SDKS_PATH"
  cp -r "$DIST_WASI_SDK" "$TOOLCHAIN_SDKS_PATH/WASI.sdk"
}

create_darwin_info_plist() {
  echo "-- Create Info.plist --"
  PLISTBUDDY_BIN="/usr/libexec/PlistBuddy"

  DARWIN_TOOLCHAIN_VERSION="5.3.${YEAR}${MONTH}${DAY}"
  BUNDLE_PREFIX="org.swiftwasm"
  DARWIN_TOOLCHAIN_BUNDLE_IDENTIFIER="${BUNDLE_PREFIX}.${YEAR}${MONTH}${DAY}"
  DARWIN_TOOLCHAIN_DISPLAY_NAME_SHORT="Swift for WebAssembly Snapshot"
  DARWIN_TOOLCHAIN_DISPLAY_NAME="${DARWIN_TOOLCHAIN_DISPLAY_NAME_SHORT} ${YEAR}-${MONTH}-${DAY}"
  DARWIN_TOOLCHAIN_ALIAS="swiftwasm"

  DARWIN_TOOLCHAIN_INFO_PLIST="${DIST_TOOLCHAIN_SDK}/Info.plist"
  DARWIN_TOOLCHAIN_REPORT_URL="https://github.com/swiftwasm/swift/issues"
  COMPATIBILITY_VERSION=2
  COMPATIBILITY_VERSION_DISPLAY_STRING="Xcode 8.0"
  DARWIN_TOOLCHAIN_CREATED_DATE="$(date -u +'%a %b %d %T GMT %Y')"
  SWIFT_USE_DEVELOPMENT_TOOLCHAIN_RUNTIME="YES"

  rm -f "${DARWIN_TOOLCHAIN_INFO_PLIST}"

  ${PLISTBUDDY_BIN} -c "Add DisplayName string '${DARWIN_TOOLCHAIN_DISPLAY_NAME}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add ShortDisplayName string '${DARWIN_TOOLCHAIN_DISPLAY_NAME_SHORT}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add CreatedDate date '${DARWIN_TOOLCHAIN_CREATED_DATE}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add CompatibilityVersion integer ${COMPATIBILITY_VERSION}" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add CompatibilityVersionDisplayString string ${COMPATIBILITY_VERSION_DISPLAY_STRING}" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add Version string '${DARWIN_TOOLCHAIN_VERSION}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add CFBundleIdentifier string '${DARWIN_TOOLCHAIN_BUNDLE_IDENTIFIER}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add ReportProblemURL string '${DARWIN_TOOLCHAIN_REPORT_URL}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add Aliases array" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add Aliases:0 string '${DARWIN_TOOLCHAIN_ALIAS}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add OverrideBuildSettings dict" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add OverrideBuildSettings:ENABLE_BITCODE string 'NO'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add OverrideBuildSettings:SWIFT_DISABLE_REQUIRED_ARCLITE string 'YES'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add OverrideBuildSettings:SWIFT_LINK_OBJC_RUNTIME string 'YES'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add OverrideBuildSettings:SWIFT_DEVELOPMENT_TOOLCHAIN string 'YES'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"
  ${PLISTBUDDY_BIN} -c "Add OverrideBuildSettings:SWIFT_USE_DEVELOPMENT_TOOLCHAIN_RUNTIME string '${SWIFT_USE_DEVELOPMENT_TOOLCHAIN_RUNTIME}'" "${DARWIN_TOOLCHAIN_INFO_PLIST}"

  chmod a+r "${DARWIN_TOOLCHAIN_INFO_PLIST}"
}

if [ ${BUILD_HOST_TOOLCHAIN} -eq 1 ]; then
  build_host_toolchain
  rm -rf "$DIST_TOOLCHAIN_DESTDIR"
  rsync -a "$HOST_TOOLCHAIN_DESTDIR/" "$DIST_TOOLCHAIN_DESTDIR"
fi

build_toolchain
build_wasi_sdk
embed_sdks

if [[ "$(uname)" == "Darwin" ]]; then
  create_darwin_info_plist
fi

cd "$DIST_TOOLCHAIN_DESTDIR"
tar cfz "$PACKAGE_ARTIFACT" "$TOOLCHAIN_NAME"
echo "Toolchain archive created successfully!"
