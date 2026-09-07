if(NOT DEFINED SOURCE_EXE OR NOT EXISTS "${SOURCE_EXE}" OR IS_DIRECTORY "${SOURCE_EXE}")
    message(FATAL_ERROR "Built executable is missing: ${SOURCE_EXE}")
endif()
if(NOT DEFINED DEPLOY_DIR OR DEPLOY_DIR STREQUAL "")
    message(FATAL_ERROR "DEPLOY_DIR is required")
endif()

# Only these two files belong to this update. Never enumerate/copy a build
# directory: it may contain settings, logs, test tools and unrelated files.
if(NOT RELATIVE_EXE STREQUAL "bin/qlizzie.exe" AND NOT RELATIVE_EXE STREQUAL "QLizzie.exe")
    message(FATAL_ERROR "Not a permitted local executable: ${RELATIVE_EXE}")
endif()
set(destination "${DEPLOY_DIR}/${RELATIVE_EXE}")
get_filename_component(destination_dir "${destination}" DIRECTORY)
file(MAKE_DIRECTORY "${destination_dir}")
execute_process(COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${SOURCE_EXE}" "${destination}"
    RESULT_VARIABLE copy_result ERROR_VARIABLE copy_error)
if(NOT copy_result EQUAL 0)
    message(FATAL_ERROR "Could not update ${destination}. Close QLizzie if it is running. ${copy_error}")
endif()
message(STATUS "Local executable up to date: ${destination}")
