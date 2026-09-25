cmake_minimum_required(VERSION 3.24)

project(QLizzieWorkspace LANGUAGES CXX)

include(CTest)
include(cmake/LocalDeploy.cmake)

add_subdirectory(app)
add_subdirectory(launcher)

if(BUILD_TESTING)
    find_program(QLIZZIE_NODE_EXECUTABLE NAMES node node.exe)
    if(QLIZZIE_NODE_EXECUTABLE)
        foreach(test_name IN ITEMS GameRules game_tree engine_session analysis_cache analysis_status candidate_analysis candidate_table engine_log_formatter engine_play engine_speed engine_support engine_sync frontend_rendering ownership rule_support settings_store sgf_session sgf_utils translations tree_layout window_geometry)
            add_test(
                NAME qlizzie_js_${test_name}
                COMMAND ${QLIZZIE_NODE_EXECUTABLE}
                        ${CMAKE_CURRENT_SOURCE_DIR}/tests/${test_name}.test.js
            )
        endforeach()
    endif()

    if(TARGET Qt6::qmake)
        get_target_property(QLIZZIE_QMAKE_EXECUTABLE Qt6::qmake IMPORTED_LOCATION)
        get_filename_component(QLIZZIE_QT_BIN_DIR "${QLIZZIE_QMAKE_EXECUTABLE}" DIRECTORY)
        if(TARGET qlizzie_qml_tests)
            foreach(test_name IN ITEMS modal_window engine_communication candidate_list game_session engine_session analysis_session application_session candidate_layer)
                add_test(
                    NAME qlizzie_qml_${test_name}
                    COMMAND qlizzie_qml_tests
                            -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/qml_runtime/tst_${test_name}.qml
                            -platform offscreen
                )
                if(WIN32)
                    set_tests_properties(qlizzie_qml_${test_name} PROPERTIES
                        ENVIRONMENT_MODIFICATION "PATH=path_list_prepend:${QLIZZIE_QT_BIN_DIR}")
                endif()
            endforeach()
        endif()
    endif()
endif()
