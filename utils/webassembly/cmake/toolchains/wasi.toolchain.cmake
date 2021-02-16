set(CMAKE_SYSTEM_NAME WASI)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR wasm32)
set(CMAKE_SIZEOF_VOID_P 4 CACHE STRING "")

set(triple wasm32-unknown-wasi)

set(CMAKE_C_COMPILER "${LLVM_BIN}/clang")
set(CMAKE_CXX_COMPILER "${LLVM_BIN}/clang++")
set(CMAKE_AR "${LLVM_BIN}/llvm-ar" CACHE STRING "LLVM Archiver for wasm32")
set(CMAKE_RANLIB "${LLVM_BIN}/llvm-ranlib" CACHE STRING "LLVM Ranlib for wasm32")

if(NOT "${SWIFT_BIN}" STREQUAL "")
  set(CMAKE_Swift_COMPILER "${SWIFT_BIN}/swiftc")
endif()

set(CMAKE_C_COMPILER_TARGET ${triple} CACHE STRING "")
set(CMAKE_CXX_COMPILER_TARGET ${triple} CACHE STRING "")
set(CMAKE_Swift_COMPILER_TARGET ${triple} CACHE STRING "")
set(CMAKE_ASM_COMPILER_TARGET ${triple} CACHE STRING "")

set(CMAKE_EXE_LINKER_FLAGS "-Wl,--no-threads" CACHE STRING "Single thread options")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -mthread-model single -D_WASI_EMULATED_SIGNAL" CACHE STRING "Single thread options" FORCE)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -D_WASI_EMULATED_SIGNAL" CACHE STRING "" FORCE)
set(CMAKE_Swift_FLAGS "${CMAKE_Swift_FLAGS} -Xcc -D_WASI_EMULATED_SIGNAL" CACHE STRING "" FORCE)

# Don't look in the sysroot for executables to run during the build
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
# Only look in the sysroot (not in the host paths) for the rest
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE NEVER)

# Some other hacks
set(CMAKE_C_COMPILER_WORKS ON)
set(CMAKE_CXX_COMPILER_WORKS ON)
set(CMAKE_Swift_COMPILER_FORCED ON)
