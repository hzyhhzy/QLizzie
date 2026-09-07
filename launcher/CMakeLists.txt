cmake_minimum_required(VERSION 3.24)

project(qlizzie_launcher LANGUAGES CXX)

if(WIN32)
    set(QLIZZIE_PORTABLE_DIR "${CMAKE_SOURCE_DIR}/release")
    if(TARGET Qt6::windeployqt)
        get_target_property(WINDEPLOYQT_EXECUTABLE Qt6::windeployqt IMPORTED_LOCATION)
    else()
        find_program(WINDEPLOYQT_EXECUTABLE NAMES windeployqt)
    endif()
    set(QLIZZIE_PORTABLE_DEPLOY_COMMAND)
    if(WINDEPLOYQT_EXECUTABLE)
        set(QLIZZIE_PORTABLE_DEPLOY_COMMAND
            COMMAND "${WINDEPLOYQT_EXECUTABLE}"
                --qmldir "${CMAKE_SOURCE_DIR}/app/qml"
                "${QLIZZIE_PORTABLE_DIR}/bin/qlizzie.exe"
        )
    endif()

    add_executable(qlizzie_launcher WIN32
        src/launcher.cpp
        ../app/resources/qlizzie.rc
    )

    set_target_properties(qlizzie_launcher PROPERTIES
        CXX_STANDARD 17
        CXX_STANDARD_REQUIRED ON
        OUTPUT_NAME QLizzie
    )
    if(COMMAND qlizzie_enable_local_copy)
        qlizzie_enable_local_copy(qlizzie_launcher "QLizzie.exe")
    endif()

    add_custom_target(qlizzie_portable
        COMMAND ${CMAKE_COMMAND}
            -DMAIN_RUNTIME_DIR=$<TARGET_FILE_DIR:qlizzie>
            -DMAIN_EXE=$<TARGET_FILE:qlizzie>
            -DLAUNCHER_EXE=$<TARGET_FILE:qlizzie_launcher>
            -DPACKAGE_DIR=${QLIZZIE_PORTABLE_DIR}
            -P ${CMAKE_SOURCE_DIR}/cmake/PackagePortable.cmake
        ${QLIZZIE_PORTABLE_DEPLOY_COMMAND}
        DEPENDS qlizzie qlizzie_launcher
        COMMENT "Assembling portable QLizzie package"
        VERBATIM
    )
endif()
