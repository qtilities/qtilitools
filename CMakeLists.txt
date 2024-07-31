cmake_minimum_required(VERSION 3.15)
project(Qtilitools
    VERSION 0.1.1
    LANGUAGES NONE
)
string(TOLOWER ${PROJECT_NAME} PROJECT_ID)

set(PROJECT_FILES
    bin/qtls-translate
    cmake/QtilitoolsConfig.cmake.in
    cmake/modules/AppStream.cmake
    cmake/modules/QtAppResources.cmake
    cmake/modules/Translate.cmake
    cmake/modules/TranslateDesktop.pl
    README.md
)
source_group("Files" FILES ${PROJECT_FILES})
add_custom_target(${PROJECT_NAME} SOURCES ${PROJECT_FILES})

if(EXISTS "/etc/os-release")
    file(STRINGS "/etc/os-release" distro_ REGEX "^ID=")
    string(REPLACE "ID=" "" distro_ "${distro_}")
endif()

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

set(QTILITOOLS_CMAKE_PATH "${CMAKE_INSTALL_DATADIR}/cmake/${PROJECT_ID}")
configure_package_config_file("cmake/QtilitoolsConfig.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/QtilitoolsConfig.cmake"
    PATH_VARS QTILITOOLS_CMAKE_PATH
    INSTALL_DESTINATION "${QTILITOOLS_CMAKE_PATH}"
)
write_basic_package_version_file("QtilitoolsConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMinorVersion
    ARCH_INDEPENDENT
)
if(distro_ STREQUAL "arch")
    install(FILES "COPYING"            DESTINATION "${CMAKE_INSTALL_DATADIR}/licenses/${PROJECT_ID}")
endif()
install(PROGRAMS  "bin/qtls-translate" DESTINATION "${CMAKE_INSTALL_BINDIR}")
install(DIRECTORY "cmake/modules"      DESTINATION "${QTILITOOLS_CMAKE_PATH}")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/QtilitoolsConfig.cmake"
              "${CMAKE_CURRENT_BINARY_DIR}/QtilitoolsConfigVersion.cmake"
        DESTINATION "${QTILITOOLS_CMAKE_PATH}"
)
message(STATUS "
Project name:   ${PROJECT_NAME}
Version:        ${PROJECT_VERSION}
System:         ${CMAKE_SYSTEM}
Install prefix: ${CMAKE_INSTALL_PREFIX}
")
