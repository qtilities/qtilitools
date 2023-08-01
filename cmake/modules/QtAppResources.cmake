#===============================================================================
# BSD 3-Clause License
#
# Copyright (c) 2023, Andrea Zanellato <redtid3@gmail.com>
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=======================================================================================================
# QtAppResources.cmake
#
# Configures and installs:
# - About information markdown file
# - Appstream metainfo
# - Desktop file
# - Icons
# - Translations
#
#   TODO: Windows and macOS
#=======================================================================================================
set(PROJECT_RESOURCES
    resources/about.info.md.in
    resources/resources.qrc
)
include(GNUInstallDirs)
#=======================================================================================================
# Configure files
#=======================================================================================================
# "resources/about.md" is a gitignored file configured by cmake and then added
# to the Qt resource file, so not needed in the build directory.
configure_file("resources/about.info.md.in"
    "${CMAKE_CURRENT_SOURCE_DIR}/resources/about.md" @ONLY
)
if (UNIX AND NOT APPLE)
    # TODO :Create a "description.html" file from PROJECT_DESCRIPTION
    #       And insert its content into "PROJECT_APPDATA_FILE", see
    # (https://freedesktop.org/software/appstream/docs/chap-Metadata.html#tag-description)
    # and a git tags string list from function to PROJECT_RELEASES variable
    # (https://freedesktop.org/software/appstream/docs/chap-Metadata.html#tag-releases)
    set(APPDATA_FILE_IN_ "resources/freedesktop/application.appdata.xml.in")
    set(DESKTOP_FILE_IN_ "resources/freedesktop/application.desktop.in")
    set(ICON_FILE_       "resources/icons/application.icon")

    set(PROJECT_APPDATA_FILE_NAME "${PROJECT_APPSTREAM_ID}.appdata.xml")
    set(DESKTOP_FILE_IN "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_ID}.desktop.in")

    list(APPEND PROJECT_RESOURCES ${APPDATA_FILE_IN_})
    list(APPEND PROJECT_RESOURCES ${DESKTOP_FILE_IN_})

    configure_file(${APPDATA_FILE_IN_} "${PROJECT_APPDATA_FILE_NAME}" @ONLY)
    configure_file(${DESKTOP_FILE_IN_} "${DESKTOP_FILE_IN}" @ONLY)

    unset(${APPDATA_FILE_IN_})
    unset(${DESKTOP_FILE_IN_})

    # Application icon might be optional if using only freedesktop theme icons
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/${ICON_FILE_}")
        list(APPEND PROJECT_RESOURCES ${ICON_FILE_})
        set(PROJECT_ICON_FILE_PATH "${CMAKE_INSTALL_FULL_DATADIR}/icons/hicolor/scalable/apps")
        configure_file(${ICON_FILE_}
            "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_ICON_FILE_NAME}" COPYONLY
        )
    endif()
    unset(ICON_FILE_)
#=======================================================================================================
# Translations
#=======================================================================================================
    include(Translate)
    qtls_translate(PROJECT_QM_FILES
        SOURCES             ${PROJECT_SOURCES} ${PROJECT_UI_FILES}
        TEMPLATE            "${PROJECT_ID}"
        TRANSLATION_DIR     "${PROJECT_TRANSLATIONS_DIR}"
        UPDATE_TRANSLATIONS ${PROJECT_TRANSLATIONS_UPDATE}
        INSTALL_DIR         "${CMAKE_INSTALL_DATADIR}/${PROJECT_ID}/translations"
    )
    qtls_translate_desktop(PROJECT_DESKTOP_FILES
        DESKTOP_FILE_STEM   "${PROJECT_APPSTREAM_ID}"
        SOURCES             "${DESKTOP_FILE_IN}"
        TRANSLATION_DIR     "${PROJECT_TRANSLATIONS_DIR}"
    )
    unset(DESKTOP_FILE_IN)
    file(GLOB PROJECT_TRANSLATION_SOURCES "resources/translations/*")
    source_group("Translation Sources" FILES ${PROJECT_TRANSLATION_SOURCES})
#=======================================================================================================
# Install
#=======================================================================================================
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_APPDATA_FILE_NAME}"
        DESTINATION "${CMAKE_INSTALL_DATADIR}/metainfo"
    )
    install(FILES "${PROJECT_DESKTOP_FILES}"
        DESTINATION "${CMAKE_INSTALL_DATADIR}/applications"
    )
endif()
if(EXISTS "resources/icons/application.icon")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_ICON_FILE_NAME}"
        DESTINATION "${PROJECT_ICON_FILE_PATH}"
    )
endif()

source_group("Resource Files" FILES ${PROJECT_RESOURCES})
