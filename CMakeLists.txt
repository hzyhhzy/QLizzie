cmake_minimum_required(VERSION 3.24)

project(QLizzieWorkspace LANGUAGES CXX)

include(CTest)

add_subdirectory(app)
add_subdirectory(launcher)

if(BUILD_TESTING)
    find_program(QLIZZIE_NODE_EXECUTABLE NAMES node node.exe)
    if(QLIZZIE_NODE_EXECUTABLE)
        foreach(test_name IN ITEMS GameRules rule_support sgf_session sgf_utils)
            add_test(
                NAME qlizzie_js_${test_name}
                COMMAND ${QLIZZIE_NODE_EXECUTABLE}
                        ${CMAKE_CURRENT_SOURCE_DIR}/tests/${test_name}.test.js
            )
        endforeach()
    endif()
endif()
