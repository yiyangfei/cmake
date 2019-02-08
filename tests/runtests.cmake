execute_process(
    COMMAND ${CMAKE_COMMAND} --build . --target test
    WORKING_DIRECTORY ${BASEDIR}
    RESULT_VARIABLE RESULT
    OUTPUT_VARIABLE OUTPUT
    ERROR_VARIABLE ERROR)

message(STATUS ${OUTPUT})

if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
    if(NOT ${RESULT} EQUAL 1)
        message(FATAL_ERROR "Valgrind should find an memory leak. Return code was: ${RESULT}")
    endif()
endif()
