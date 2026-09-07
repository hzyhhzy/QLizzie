if(NOT DEFINED MAIN_RUNTIME_DIR OR NOT EXISTS "${MAIN_RUNTIME_DIR}")
    message(FATAL_ERROR "MAIN_RUNTIME_DIR is missing: ${MAIN_RUNTIME_DIR}")
endif()

if(NOT DEFINED MAIN_EXE OR NOT EXISTS "${MAIN_EXE}")
    message(FATAL_ERROR "MAIN_EXE is missing: ${MAIN_EXE}")
endif()

if(NOT DEFINED LAUNCHER_EXE OR NOT EXISTS "${LAUNCHER_EXE}")
    message(FATAL_ERROR "LAUNCHER_EXE is missing: ${LAUNCHER_EXE}")
endif()

if(NOT DEFINED PACKAGE_DIR OR PACKAGE_DIR STREQUAL "")
    message(FATAL_ERROR "PACKAGE_DIR is required")
endif()

file(REMOVE_RECURSE "${PACKAGE_DIR}")
file(MAKE_DIRECTORY "${PACKAGE_DIR}/bin")

file(GLOB runtime_entries LIST_DIRECTORIES true RELATIVE "${MAIN_RUNTIME_DIR}" "${MAIN_RUNTIME_DIR}/*")
foreach(entry IN LISTS runtime_entries)
    string(TOLOWER "${entry}" entry_lower)
    if(entry_lower MATCHES "\\.(lib|exp|pdb|ilk)$")
        continue()
    endif()
    if(entry_lower STREQUAL "settings.ini"
            OR entry_lower STREQUAL "qlizzie_core_tests.exe"
            OR entry_lower STREQUAL "runtime-check.err"
            OR entry_lower STREQUAL "runtime-check.out"
            OR entry_lower STREQUAL "gtp_logs")
        continue()
    endif()

    file(COPY "${MAIN_RUNTIME_DIR}/${entry}" DESTINATION "${PACKAGE_DIR}/bin")
endforeach()

file(COPY "${LAUNCHER_EXE}" DESTINATION "${PACKAGE_DIR}")

message(STATUS "Portable package written to: ${PACKAGE_DIR}")
