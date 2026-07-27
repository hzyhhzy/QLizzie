cmake_minimum_required(VERSION 3.24)

project(QLizzieWorkspace LANGUAGES CXX)

include(CTest)

add_subdirectory(app)
add_subdirectory(launcher)

if(BUILD_TESTING)
    find_program(QLIZZIE_NODE_EXECUTABLE NAMES node node.exe)
    if(QLIZZIE_NODE_EXECUTABLE)
        foreach(test_name IN ITEMS GameRules analysis_status candidate_analysis engine_list_dialog engine_log_formatter engine_play engine_speed engine_support engine_sync frontend_rendering modal_dialog ownership rule_support sgf_session sgf_utils translations)
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
        find_program(QLIZZIE_QMLTESTRUNNER_EXECUTABLE
            NAMES qmltestrunner
            HINTS "${QLIZZIE_QT_BIN_DIR}"
            NO_DEFAULT_PATH
        )
        if(QLIZZIE_QMLTESTRUNNER_EXECUTABLE)
            add_test(
                NAME qlizzie_qml_modal_window
                COMMAND ${QLIZZIE_QMLTESTRUNNER_EXECUTABLE}
                        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/qml_runtime/tst_modal_window.qml
                        -platform offscreen
            )
            add_test(
                NAME qlizzie_qml_engine_communication
                COMMAND ${QLIZZIE_QMLTESTRUNNER_EXECUTABLE}
                        -input ${CMAKE_CURRENT_SOURCE_DIR}/tests/qml_runtime/tst_engine_communication.qml
                        -platform offscreen
            )
        endif()
    endif()
endif()
