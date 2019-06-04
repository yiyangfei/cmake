find_program(VALGRIND valgrind)
if(VALGRIND)
    message(STATUS "Unit tests will be profiled on memory leaks using valgrind: ${VALGRIND}")
endif()

macro(add_qt_test TEST_NAME SRCS)
    find_package(Qt5Test REQUIRED)
    add_executable(${TEST_NAME} ${SRCS})
    target_link_libraries(${TEST_NAME} PUBLIC Qt5::Test)

    if(VALGRIND)
        add_test(NAME ${TEST_NAME} COMMAND ${VALGRIND} --error-exitcode=1 --leak-check=full ${VALGRIND_OPTS} $<TARGET_FILE:${TEST_NAME}>)
    else()
        add_test(NAME ${TEST_NAME} COMMAND $<TARGET_FILE:${TEST_NAME}>)
    endif()
endmacro()

option(PRIVATE_TESTS_ENABLED "Enable private tests" ON)
macro(add_private_qt_test TEST_NAME SRCS)
    if(DEFINED PRIVATE_TESTS_ENABLED)
        if(${PRIVATE_TESTS_ENABLED})
            add_qt_test(${TEST_NAME} "${SRCS}")
        endif(${PRIVATE_TESTS_ENABLED})
    endif(DEFINED PRIVATE_TESTS_ENABLED)
endmacro()

option(MANUAL_TESTS_ENABLED "Enable manual tests" OFF)
macro(add_manual_qt_test TEST_NAME SRCS)
    find_package(Qt5Test REQUIRED)
    add_executable(${TEST_NAME} ${SRCS})
    target_link_libraries(${TEST_NAME} PUBLIC Qt5::Test)

    if(DEFINED MANUAL_TESTS_ENABLED)
        if(${MANUAL_TESTS_ENABLED})
            add_test(NAME ${TEST_NAME} COMMAND $<TARGET_FILE:${TEST_NAME}>)
        endif(${MANUAL_TESTS_ENABLED})
    endif(DEFINED MANUAL_TESTS_ENABLED)
endmacro()