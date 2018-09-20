# Remove any previous file. Start with a clean slate.
file(REMOVE ${CMAKE_BINARY_DIR}/tests.txt)
file(REMOVE ${CMAKE_BINARY_DIR}/private_tests.txt)
file(REMOVE ${CMAKE_BINARY_DIR}/manual_tests.txt)

if(NOT TARGET manual-test-archive)
    add_custom_target(manual-test-archive
        COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_BINARY_DIR}/manualTests.zip"
        COMMAND ${CMAKE_COMMAND} -E tar "cf" "${CMAKE_BINARY_DIR}/manualTests.zip" --format=zip --files-from=${CMAKE_BINARY_DIR}/manual_tests.txt
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endif()

if(NOT TARGET private-test-archive)
    add_custom_target(private-test-archive
        COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_BINARY_DIR}/privateTests.zip"
        COMMAND ${CMAKE_COMMAND} -E tar "cf" "${CMAKE_BINARY_DIR}/privateTests.zip" --format=zip --files-from=${CMAKE_BINARY_DIR}/private_tests.txt
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endif()

if(NOT TARGET test-archive)
    add_custom_target(test-archive
        COMMAND ${CMAKE_COMMAND} -E remove -f "${CMAKE_BINARY_DIR}/tests.zip"
        COMMAND ${CMAKE_COMMAND} -E tar "cf" "${CMAKE_BINARY_DIR}/tests.zip" --format=zip --files-from=${CMAKE_BINARY_DIR}/tests.txt
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
endif()

macro(add_qt_test TEST_NAME SRCS)
    find_package(Qt5Test REQUIRED)

    add_executable(${TEST_NAME} ${SRCS})

    add_test(NAME ${TEST_NAME} COMMAND $<TARGET_FILE:${TEST_NAME}>)

    target_link_libraries(${TEST_NAME} PUBLIC Qt5::Test)
    
    file(APPEND ${CMAKE_BINARY_DIR}/tests.txt ${TEST_NAME}${CMAKE_EXECUTABLE_SUFFIX}\n)
endmacro()

option(PRIVATE_TESTS_ENABLED "Enable private tests" ON)
macro(add_private_qt_test TEST_NAME SRCS)
    if(DEFINED PRIVATE_TESTS_ENABLED)
        if(${PRIVATE_TESTS_ENABLED})
            add_qt_test(${TEST_NAME} "${SRCS}")
            file(APPEND ${CMAKE_BINARY_DIR}/private_tests.txt ${TEST_NAME}${CMAKE_EXECUTABLE_SUFFIX}\n)
        endif(${PRIVATE_TESTS_ENABLED})
    endif(DEFINED PRIVATE_TESTS_ENABLED)
endmacro()

option(MANUAL_TESTS_ENABLED "Enable manual tests" OFF)
macro(add_manual_qt_test TEST_NAME SRCS)
    find_package(Qt5Test REQUIRED)
    add_executable(${TEST_NAME} ${SRCS})
    target_link_libraries(${TEST_NAME} PUBLIC Qt5::Test)
    file(APPEND ${CMAKE_BINARY_DIR}/manual_tests.txt ${TEST_NAME}${CMAKE_EXECUTABLE_SUFFIX}\n)
    
    if(DEFINED MANUAL_TESTS_ENABLED)
        if(${MANUAL_TESTS_ENABLED})
            add_test(NAME ${TEST_NAME} COMMAND $<TARGET_FILE:${TEST_NAME}>)
        endif(${MANUAL_TESTS_ENABLED})
    endif(DEFINED MANUAL_TESTS_ENABLED)
endmacro()
