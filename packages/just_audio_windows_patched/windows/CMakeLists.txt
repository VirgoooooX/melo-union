cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "just_audio_windows")
project(${PROJECT_NAME} LANGUAGES CXX)
set(CPPWINRT_VERSION 2.0.210806.1)
set(CMAKE_CXX_STANDARD 17)

if (NOT COMMAND apply_standard_settings)
  function(apply_standard_settings TARGET)
    target_compile_features(${TARGET} PRIVATE cxx_std_17)
  endfunction()
endif()

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "just_audio_windows_plugin")

# === Monkey's Audio SDK Static Library ===

set(MONKEYS_AUDIO_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/monkeys_audio")

set(MAC_SHARED_SOURCES
  "${MONKEYS_AUDIO_DIR}/Source/Shared/BufferIO.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/CharacterHelper.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/CircleBuffer.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/CPUFeatures.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/CRC.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/GlobalFunctions.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/MemoryIO.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/Semaphore.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/Thread.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/WholeFileIO.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/Shared/WinFileIO.cpp"
)

set(MAC_LIBRARY_SOURCES
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APECompress.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APECompressCore.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APECompressCreate.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APEDecompress.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APEDecompressCore.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APEHeader.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APEInfo.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APELink.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/APETag.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/BitArray.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/FloatTransform.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/MACLib.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/MACProgressHelper.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/MD5.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/NewPredictor.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/NNFilter.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/NNFilterGeneric.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Prepare.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/UnBitArray.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/UnBitArrayBase.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/WAVInputSource.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/NewPredictorOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/AntiPredictorOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/AntiPredictorExtraHighOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/AntiPredictorFastOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/AntiPredictorHighOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/AntiPredictorNormalOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/APEDecompressCoreOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/APEDecompressOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/UnBitArrayOld.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/Old/UnMACOld.cpp"

  # Intel CPU optimization files:
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/NNFilterAVX2.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/NNFilterAVX512.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/NNFilterSSE2.cpp"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib/NNFilterSSE4.1.cpp"
)

add_library(melo_monkeys_audio STATIC
  ${MAC_SHARED_SOURCES}
  ${MAC_LIBRARY_SOURCES}
)

apply_standard_settings(melo_monkeys_audio)
target_compile_definitions(melo_monkeys_audio PRIVATE PLATFORM_WINDOWS UNICODE _UNICODE)
target_include_directories(melo_monkeys_audio PUBLIC
  "${MONKEYS_AUDIO_DIR}/Source/Shared"
  "${MONKEYS_AUDIO_DIR}/Source/MACLib"
)
set_property(TARGET melo_monkeys_audio PROPERTY MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")

# Main plugin target
add_library(${PLUGIN_NAME} SHARED
  "just_audio_windows_plugin.cpp"
  "player.hpp"
  "ape/ape_decode_session.cpp"
  "ape/ape_media_source.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/native_audio"
  "${CMAKE_CURRENT_SOURCE_DIR}/ape"
  "${MONKEYS_AUDIO_DIR}/Shared"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin melo_monkeys_audio)

# List of absolute paths to libraries that should be bundled with the plugin
set(just_audio_windows_bundled_libraries
  ""
  PARENT_SCOPE
)

# === Tests ===

if (${include_${PROJECT_NAME}_tests})
  set(TEST_RUNNER "${PROJECT_NAME}_test")
  enable_testing()

  # Download googletest. Using the same version as the camera_windows plugin
  # for consistency across Flutter Windows plugins.
  include(FetchContent)
  FetchContent_Declare(
    googletest
    URL https://github.com/google/googletest/archive/release-1.11.0.zip
  )
  # Prevent overriding the parent project's compiler/linker settings.
  set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
  # Disable install commands for gtest so it doesn't end up in the bundle.
  set(INSTALL_GTEST OFF CACHE BOOL "Disable installation of googletest" FORCE)

  FetchContent_MakeAvailable(googletest)

  # uri_utils.hpp is a header-only, WinRT-free helper, so the test binary
  # needs no plugin sources or special Windows libraries.
  add_executable(${TEST_RUNNER}
    test/uri_utils_test.cpp
    test/ape_decode_test.cpp
    ape/ape_decode_session.cpp
  )
  apply_standard_settings(${TEST_RUNNER})
  target_include_directories(${TEST_RUNNER} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${CMAKE_CURRENT_SOURCE_DIR}/ape"
    "${MONKEYS_AUDIO_DIR}/Shared"
  )
  target_link_libraries(${TEST_RUNNER} PRIVATE gtest_main melo_monkeys_audio)

  include(GoogleTest)
  gtest_discover_tests(${TEST_RUNNER})
endif()

