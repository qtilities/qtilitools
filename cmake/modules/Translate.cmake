#=======================================================================================================
# BSD 3-Clause License
#
# Copyright (c) 2014, Luís Pereira <luis.artur.pereira@gmail.com> (as LXQtTranslateTs.cmake.in)
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
#
# function qtls_translate
#
# Output:
#    qmFiles             Compiled ".qm" translation file names list.
#
# Input:
#    SOURCES             Mandatory, the list of source files.
#    TEMPLATE            Optional, translations base name (lower case project name). Default: "${PROJECT_ID}".
#    TRANSLATION_DIR     Optional, ".ts" source directory path, relative to the CMakeList.txt. Default: "translations".
#    UPDATE_TRANSLATIONS Optional, wether if update translations or compile only. Default: OFF.
#    UPDATE_OPTIONS      Optional, options to pass to lupdate. Requires UPDATE_TRANSLATIONS. Default: ""
#    INSTALL_DIR         Optional, ".qm" install directory. If not present no installation is performed.
#=======================================================================================================
find_package(Qt${QT_VERSION_MAJOR}LinguistTools REQUIRED)

# TODO: TEMPLATE as multiValueArgs? Otherwise other translations shouldn't be available as subfolder of others
#       because recursion.
function(qtls_translate qmFiles)
    set(oneValueArgs
        UPDATE_TRANSLATIONS
        TEMPLATE
        TRANSLATION_DIR
        INSTALL_DIR
    )
    set(multiValueArgs SOURCES UPDATE_OPTIONS)
    cmake_parse_arguments(TR "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    if (NOT DEFINED TR_UPDATE_TRANSLATIONS)
        set(TR_UPDATE_TRANSLATIONS OFF)
    endif()

    if (NOT DEFINED TR_UPDATE_OPTIONS)
        set(TR_UPDATE_OPTIONS "")
    endif()

    if(NOT DEFINED TR_TEMPLATE)
        set(TR_TEMPLATE "${PROJECT_ID}")
    endif()

    if (NOT DEFINED TR_TRANSLATION_DIR)
        set(TR_TRANSLATION_DIR "translations")
    endif()
    get_filename_component(TR_TRANSLATION_DIR "${TR_TRANSLATION_DIR}" ABSOLUTE)

    if (EXISTS "${TR_TRANSLATION_DIR}")
        file(GLOB tsFiles "${TR_TRANSLATION_DIR}/${TR_TEMPLATE}_*.ts")
        set(templateFile "${TR_TRANSLATION_DIR}/${TR_TEMPLATE}.ts")
    endif ()

    if (TR_UPDATE_TRANSLATIONS)
        qt_create_translation(QMS
            ${TR_SOURCES}
            ${templateFile}
            OPTIONS ${TR_UPDATE_OPTIONS}
        )
        qt_create_translation(QM
            ${TR_SOURCES}
            ${tsFiles}
            OPTIONS ${TR_UPDATE_OPTIONS}
        )
    endif()
    qt_add_translation(QM ${tsFiles})

    if(DEFINED TR_INSTALL_DIR)
        install(FILES ${QM} DESTINATION "${TR_INSTALL_DIR}")
    endif()

    set(${qmFiles} ${QM} PARENT_SCOPE)
endfunction()
#=======================================================================================================
# Original Author: Alexander Sokolov <sokoloff.a@gmail.com>
#
# function qtls_translate_desktop
#
# Output:
#    _RESULT            The generated .desktop file(s).
#
# Input:
#    SOURCES            `.desktop.in` file(s) to be merged and translated, relative to the CMakeList.txt.
#    DESKTOP_FILE_STEM  Optional, filename, without `.desktop` extension for the output file(s).
#    TRANSLATION_DIR    Optional, path to the directory with the .ts files, relative to the CMakeList.txt.
#                       Default: "translations".
#=======================================================================================================
find_package(Perl REQUIRED)

function(qtls_translate_desktop _RESULT)
    # Parse arguments
    set(oneValueArgs TRANSLATION_DIR DESKTOP_FILE_STEM)
    set(multiValueArgs SOURCES)

    cmake_parse_arguments(_ARGS "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    # Check for unknown arguments
    set(_UNPARSED_ARGS ${_ARGS_UNPARSED_ARGUMENTS})
    if (NOT ${_UNPARSED_ARGS} STREQUAL "")
        message(FATAL_ERROR
            "Unknown arguments '${_UNPARSED_ARGS}'.\n"
            "See qtls_translate_desktop() documentation for more information.\n"
        )
    endif()

    if (NOT DEFINED _ARGS_SOURCES)
        set(${_RESULT} "" PARENT_SCOPE)
        return()
    else()
        set(_sources ${_ARGS_SOURCES})
    endif()

    if (NOT DEFINED _ARGS_TRANSLATION_DIR)
        set(_translationDir "translations")
    else()
        set(_translationDir ${_ARGS_TRANSLATION_DIR})
    endif()

    get_filename_component (_translationDir ${_translationDir} ABSOLUTE)

    foreach (_inFile ${_sources})
        # File in full path string, E.g.: "/path/to/file_stem.desktop.in"
        get_filename_component(_inFile   ${_inFile} ABSOLUTE)

        # File in name without extension, E.g.: "file_stem"
        get_filename_component(_fileName ${_inFile} NAME_WE)

        # File in long extension, e.g.: ".desktop.in"
        get_filename_component(_fileExt  ${_inFile} EXT)

        # File output extension, e.g.: "desktop"
        string(REPLACE ".in" "" _fileExt ${_fileExt})
        string(REGEX REPLACE "^\\.([^.].*)$" "\\1" _fileExt ${_fileExt})

        if(_ARGS_DESKTOP_FILE_STEM)
            set(_outFile "${CMAKE_CURRENT_BINARY_DIR}/${_ARGS_DESKTOP_FILE_STEM}.${_fileExt}")
        else()
            set(_outFile "${CMAKE_CURRENT_BINARY_DIR}/${_fileName}.${_fileExt}")
        endif()
        get_filename_component(_outFileName ${_outFile} NAME)

        add_custom_command(OUTPUT ${_outFile}
            COMMAND ${PERL_EXECUTABLE} "${Qtilitools_CMAKE_MODULE_PATH}/TranslateDesktop.pl"
                "${_inFile}"
                "${_fileName}"
                "${_translationDir}/${_fileName}[_.]*${_fileExt}.yaml" >> "${_outFile}"
            VERBATIM
            COMMENT "Generating ${_outFileName}"
        )

        set(__result ${__result} ${_outFile})
    endforeach()

    set(${_RESULT} ${__result} PARENT_SCOPE)
endfunction()
