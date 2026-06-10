cmake_minimum_required(VERSION 3.16)
project(v2ray_core_bridge VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find NAPI
find_path(NAPI_INCLUDE_DIR napi/native_api.h
  PATHS ${OHOS_SDK_NATIVE}/sysroot/usr/include
  NO_DEFAULT_PATH)

# Import Go V2Ray core as a static library (linked directly into bridge)
set(GO_CORE_A ${CMAKE_CURRENT_SOURCE_DIR}/../../../../v2ray_go/libs/arm64-v8a/libv2ray_core.a)
add_library(v2ray_core STATIC IMPORTED)
set_target_properties(v2ray_core PROPERTIES IMPORTED_LOCATION ${GO_CORE_A})

# Set include path for Go-generated header (libv2ray_core.h)
set(GO_CORE_INCLUDE ${CMAKE_CURRENT_SOURCE_DIR}/../../../../v2ray_go/libs/arm64-v8a)

# Source files
add_library(v2ray_bridge SHARED napi_bridge.cpp)

target_include_directories(v2ray_bridge PRIVATE
  ${NAPI_INCLUDE_DIR}
  ${CMAKE_CURRENT_SOURCE_DIR}
  ${GO_CORE_INCLUDE})

target_link_libraries(v2ray_bridge
  ace_napi.z
  hilog_ndk.z
  dl
  m
  # Static link Go core — whole-archive ensures Go runtime init isn't stripped
  -Wl,--whole-archive v2ray_core -Wl,--no-whole-archive)
