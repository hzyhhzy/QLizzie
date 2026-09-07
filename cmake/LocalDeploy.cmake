# Update an existing local installation without running PackagePortable.cmake,
# which intentionally recreates its release staging directory from scratch.
if(WIN32)
    set(QLIZZIE_LOCAL_DEPLOY_DIR "C:/qlizzie" CACHE PATH
        "Existing QLizzie installation to update after builds; empty disables copying")
endif()

function(qlizzie_enable_local_copy target relative_path)
    if(NOT WIN32 OR NOT QLIZZIE_LOCAL_DEPLOY_DIR)
        return()
    endif()

    set(copy_command "${CMAKE_COMMAND}"
        "-DSOURCE_EXE=$<TARGET_FILE:${target}>"
        "-DDEPLOY_DIR=${QLIZZIE_LOCAL_DEPLOY_DIR}"
        "-DRELATIVE_EXE=${relative_path}"
        -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CopyLocalExecutable.cmake")

    # Also works when building just the executable target.
    add_custom_command(TARGET ${target} POST_BUILD
        COMMAND ${copy_command}
        COMMENT "Updating local ${relative_path}"
        VERBATIM)

    # A normal build rechecks the copy even when no relinking was necessary.
    # copy_if_different leaves an identical installed executable untouched.
    add_custom_target(${target}_sync_local ALL
        COMMAND ${copy_command}
        DEPENDS ${target}
        COMMENT "Checking local ${relative_path}"
        VERBATIM)
endfunction()
